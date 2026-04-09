// lib/models/medicine.dart
import 'dart:convert';

class Medicine {
  final String id;
  String name;
  String dosage;
  String frequency; // daily, twice, thrice, weekly
  String time; // HH:mm format
  bool enabled;
  int alarmId;
  DateTime? lastTriggered;

  Medicine({
    required this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.time,
    this.enabled = true,
    required this.alarmId,
    this.lastTriggered,
  });

  Medicine copyWith({
    String? id,
    String? name,
    String? dosage,
    String? frequency,
    String? time,
    bool? enabled,
    int? alarmId,
    DateTime? lastTriggered,
  }) {
    return Medicine(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      time: time ?? this.time,
      enabled: enabled ?? this.enabled,
      alarmId: alarmId ?? this.alarmId,
      lastTriggered: lastTriggered ?? this.lastTriggered,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'time': time,
      'enabled': enabled,
      'alarmId': alarmId,
      'lastTriggered': lastTriggered?.toIso8601String(),
    };
  }

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      id: json['id'] as String,
      name: json['name'] as String,
      dosage: json['dosage'] as String,
      frequency: json['frequency'] as String,
      time: json['time'] as String,
      enabled: json['enabled'] as bool? ?? true,
      alarmId: json['alarmId'] as int,
      lastTriggered: json['lastTriggered'] != null
          ? DateTime.tryParse(json['lastTriggered'] as String)
          : null,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory Medicine.fromJsonString(String jsonString) =>
      Medicine.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);

  String get frequencyLabel {
    switch (frequency) {
      case 'twice':
        return 'Twice a day';
      case 'thrice':
        return 'Three times a day';
      case 'weekly':
        return 'Weekly';
      default:
        return 'Daily';
    }
  }

  String get ttsMessage =>
      'Medicine reminder. It\'s time to take your $name, $dosage. '
      'Please take your medicine now.';
}
