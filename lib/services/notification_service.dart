// lib/services/notification_service.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static NotificationService? _instance;
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  NotificationService._();

  static NotificationService get instance {
    _instance ??= NotificationService._();
    return _instance!;
  }

  Future<void> init() async {
    if (_initialized) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings =
        InitializationSettings(android: android, iOS: ios);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationResponse,
    );

    // Create high-priority notification channel
    await _createChannel();
    _initialized = true;
  }

  Future<void> _createChannel() async {
    final channel = AndroidNotificationChannel(
      'medicine_reminders',
      'Medicine Reminders',
      description: 'High-priority alerts for medicine reminders',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
      enableLights: true,
      ledColor: Color.fromARGB(255, 98, 0, 234),
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> showMedicineReminder({
    required int id,
    required String medicineName,
    required String dosage,
  }) async {
    if (!_initialized) await init();

    final androidDetails = AndroidNotificationDetails(
      'medicine_reminders',
      'Medicine Reminders',
      channelDescription: 'High-priority alerts for medicine reminders',
      importance: Importance.max,
      priority: Priority.max,
      ticker: 'Medicine Reminder',
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      actions: [
        const AndroidNotificationAction(
          'TAKEN',
          'Mark as Taken',
          showsUserInterface: true,
          cancelNotification: true,
        ),
        const AndroidNotificationAction(
          'SNOOZE',
          'Snooze 10 min',
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ],
      styleInformation: BigTextStyleInformation(
        '$medicineName · $dosage\nTime to take your medicine now.',
        summaryText: 'Medicine Reminder',
      ),
      vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
      enableLights: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.critical,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      id,
      'Medicine Reminder 💊',
      '$medicineName — $dosage · Take your medicine now.',
      details,
    );
  }

  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  static void _onNotificationResponse(NotificationResponse response) {
    // Handled in provider / main isolate
  }

  @pragma('vm:entry-point')
  static void _onBackgroundNotificationResponse(
      NotificationResponse response) {
    // Background action handling
  }
}
