// lib/services/alarm_service.dart

import 'dart:ui';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/foundation.dart';

import '../models/medicine.dart';
import 'notification_service.dart';
import 'storage_service.dart';
import 'tts_service.dart';

// ─── Top-level background callback ────────────────────────────────────────────
// MUST be a top-level function annotated with @pragma('vm:entry-point')
@pragma('vm:entry-point')
Future<void> alarmCallback(int id, Map<String, dynamic>? data) async {
  debugPrint('[AlarmService] Alarm fired: id=$id data=$data');

  // Initialise services in the background isolate
  await StorageService.instance.init();
  await NotificationService.instance.init();

  // Load the medicine that matches this alarm ID
  final medicines = await StorageService.instance.loadMedicines();
  final medicine = medicines.cast<Medicine?>().firstWhere(
        (m) => m?.alarmId == id,
        orElse: () => null,
      );

  if (medicine == null || !medicine.enabled) return;

  // Show system notification
  await NotificationService.instance.showMedicineReminder(
    id: id,
    medicineName: medicine.name,
    dosage: medicine.dosage,
  );

  // Speak via TTS (works in background isolate on Android)
  try {
    await TtsService.instance.init();
    await TtsService.instance.speak(medicine.ttsMessage);
    // Give TTS time to complete before the isolate exits
    await Future.delayed(const Duration(seconds: 8));
    await TtsService.instance.stop();
  } catch (e) {
    debugPrint('[AlarmService] TTS error: $e');
  }

  // Update lastTriggered and reschedule next alarm
  final updated = medicine.copyWith(lastTriggered: DateTime.now());
  final index = medicines.indexWhere((m) => m.alarmId == id);
  if (index != -1) {
    medicines[index] = updated;
    await StorageService.instance.saveMedicines(medicines);
  }

  // Reschedule next occurrence
  await AlarmService.instance
      ._scheduleNext(updated, reschedule: true);

  // Notify UI isolate if running
  final port = IsolateNameServer.lookupPortByName('alarm_port');
  port?.send({'alarmId': id, 'medicineName': medicine.name});
}

// ─── AlarmService ─────────────────────────────────────────────────────────────

class AlarmService {
  static AlarmService? _instance;

  AlarmService._();

  static AlarmService get instance {
    _instance ??= AlarmService._();
    return _instance!;
  }

  Future<void> init() async {
    await AndroidAlarmManager.initialize();
  }

  /// Schedule an exact alarm for [medicine] at its next due time.
  Future<void> schedule(Medicine medicine) async {
    if (!medicine.enabled) return;
    await _scheduleNext(medicine, reschedule: false);
  }

  /// Cancel the alarm for [medicine].
  Future<void> cancel(Medicine medicine) async {
    await AndroidAlarmManager.cancel(medicine.alarmId);
    debugPrint('[AlarmService] Cancelled alarm ${medicine.alarmId}');
  }

  Future<void> rescheduleAll(List<Medicine> medicines) async {
    for (final m in medicines) {
      await cancel(m);
      if (m.enabled) await schedule(m);
    }
  }

  // ── Internal helpers ──────────────────────────────────────────────────────

  Future<void> _scheduleNext(Medicine medicine,
      {required bool reschedule}) async {
    final next = _nextAlarmTime(medicine);
    debugPrint(
        '[AlarmService] Scheduling alarm ${medicine.alarmId} at $next');

    await AndroidAlarmManager.oneShotAt(
      next,
      medicine.alarmId,
      alarmCallback,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
      alarmClock: true,
      params: {
        'alarmId': medicine.alarmId,
        'name': medicine.name,
        'dosage': medicine.dosage,
      },
    );
  }

  DateTime _nextAlarmTime(Medicine medicine) {
    final parts = medicine.time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    final now = DateTime.now();
    var next =
        DateTime(now.year, now.month, now.day, hour, minute);

    if (next.isBefore(now) || next.isAtSameMomentAs(now)) {
      switch (medicine.frequency) {
        case 'weekly':
          next = next.add(const Duration(days: 7));
          break;
        default:
          // daily / twice / thrice → advance by 1 day minimum
          next = next.add(const Duration(days: 1));
      }
    }

    return next;
  }
}
