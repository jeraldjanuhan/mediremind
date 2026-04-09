// lib/providers/medicine_provider.dart
import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../models/medicine.dart';
import '../services/alarm_service.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';

class MedicineProvider extends ChangeNotifier {
  List<Medicine> _medicines = [];
  Medicine? _currentAlert;
  Timer? _minuteTimer;
  ReceivePort? _alarmPort;

  List<Medicine> get medicines => List.unmodifiable(_medicines);
  Medicine? get currentAlert => _currentAlert;

  // ── Initialisation ─────────────────────────────────────────────────────────

  Future<void> init() async {
    await StorageService.instance.init();
    await AlarmService.instance.init();
    await NotificationService.instance.init();
    await TtsService.instance.init();

    _medicines = await StorageService.instance.loadMedicines();

    // Reschedule alarms for all enabled medicines (handles reboot)
    await AlarmService.instance.rescheduleAll(_medicines);

    // Listen for alarm callbacks from background isolate
    _alarmPort = ReceivePort();
    IsolateNameServer.registerPortWithName(
        _alarmPort!.sendPort, 'alarm_port');
    _alarmPort!.listen(_onBackgroundAlarm);

    // Foreground minute-tick for when app is open
    _startMinuteTimer();

    notifyListeners();
  }

  // ── Foreground timer ───────────────────────────────────────────────────────

  void _startMinuteTimer() {
    _minuteTimer?.cancel();
    _minuteTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkReminders();
    });
    // Also check immediately
    _checkReminders();
  }

  void _checkReminders() {
    final now = DateTime.now();
    final currentTime =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    for (final medicine in _medicines) {
      if (!medicine.enabled) continue;
      if (medicine.time != currentTime) continue;

      // De-duplicate: don't fire twice in same minute
      final last = medicine.lastTriggered;
      if (last != null &&
          last.year == now.year &&
          last.month == now.month &&
          last.day == now.day &&
          last.hour == now.hour &&
          last.minute == now.minute) continue;

      _triggerForegroundAlert(medicine);
    }
  }

  void _triggerForegroundAlert(Medicine medicine) {
    // Update lastTriggered
    final idx = _medicines.indexWhere((m) => m.id == medicine.id);
    if (idx != -1) {
      _medicines[idx] = medicine.copyWith(lastTriggered: DateTime.now());
      _save();
    }

    _currentAlert = medicine;
    notifyListeners();

    // Speak
    TtsService.instance.speak(medicine.ttsMessage);
  }

  // ── Background alarm callback ──────────────────────────────────────────────

  void _onBackgroundAlarm(dynamic message) {
    if (message is! Map) return;
    final name = message['medicineName'] as String?;
    if (name == null) return;

    final medicine = _medicines.cast<Medicine?>().firstWhere(
          (m) => m?.name == name,
          orElse: () => null,
        );
    if (medicine == null) return;

    _currentAlert = medicine;
    notifyListeners();
  }

  // ── Public actions ─────────────────────────────────────────────────────────

  Future<void> addMedicine(Medicine medicine) async {
    _medicines.add(medicine);
    await _save();
    if (medicine.enabled) {
      await AlarmService.instance.schedule(medicine);
    }
    notifyListeners();
  }

  Future<void> toggleMedicine(String id) async {
    final idx = _medicines.indexWhere((m) => m.id == id);
    if (idx == -1) return;

    final updated = _medicines[idx]
        .copyWith(enabled: !_medicines[idx].enabled);
    _medicines[idx] = updated;
    await _save();

    if (updated.enabled) {
      await AlarmService.instance.schedule(updated);
    } else {
      await AlarmService.instance.cancel(updated);
    }
    notifyListeners();
  }

  Future<void> deleteMedicine(String id) async {
    final medicine =
        _medicines.cast<Medicine?>().firstWhere((m) => m?.id == id,
            orElse: () => null);
    if (medicine != null) {
      await AlarmService.instance.cancel(medicine);
    }
    _medicines.removeWhere((m) => m.id == id);
    await _save();
    notifyListeners();
  }

  void dismissAlert() {
    _currentAlert = null;
    notifyListeners();
  }

  void snoozeAlert() {
    // Snooze is handled at the notification level (reschedule +10 min)
    _currentAlert = null;
    notifyListeners();
  }

  Future<void> testVoice(Medicine medicine) async {
    await TtsService.instance.speak(medicine.ttsMessage);
  }

  // ── Internal helpers ───────────────────────────────────────────────────────

  Future<void> _save() async {
    await StorageService.instance.saveMedicines(_medicines);
  }

  @override
  void dispose() {
    _minuteTimer?.cancel();
    IsolateNameServer.removePortNameMapping('alarm_port');
    _alarmPort?.close();
    super.dispose();
  }
}
