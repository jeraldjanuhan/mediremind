// lib/services/storage_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/medicine.dart';

class StorageService {
  static const String _medicinesKey = 'medicines';
  static const String _alarmCounterKey = 'alarm_counter';

  static StorageService? _instance;
  SharedPreferences? _prefs;

  StorageService._();

  static StorageService get instance {
    _instance ??= StorageService._();
    return _instance!;
  }

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  SharedPreferences get _p {
    if (_prefs == null) throw StateError('StorageService not initialized');
    return _prefs!;
  }

  // ── Medicine CRUD ──────────────────────────────────────────────────────────

  Future<List<Medicine>> loadMedicines() async {
    final raw = _p.getStringList(_medicinesKey) ?? [];
    return raw
        .map((s) => Medicine.fromJson(
            jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveMedicines(List<Medicine> medicines) async {
    final encoded = medicines
        .map((m) => jsonEncode(m.toJson()))
        .toList();
    await _p.setStringList(_medicinesKey, encoded);
  }

  // ── Alarm ID counter ───────────────────────────────────────────────────────

  Future<int> nextAlarmId() async {
    final current = _p.getInt(_alarmCounterKey) ?? 1000;
    await _p.setInt(_alarmCounterKey, current + 1);
    return current;
  }
}
