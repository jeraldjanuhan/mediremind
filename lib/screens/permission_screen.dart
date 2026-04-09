// lib/screens/permission_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  bool _requesting = false;

  static const _items = [
    _PermItem(
      icon: Icons.notifications_active_rounded,
      title: 'Notifications',
      subtitle: 'Show alerts when it\'s time for your medicine',
    ),
    _PermItem(
      icon: Icons.alarm_rounded,
      title: 'Exact Alarms',
      subtitle: 'Trigger reminders at the exact scheduled time',
    ),
    _PermItem(
      icon: Icons.volume_up_rounded,
      title: 'Voice Alerts',
      subtitle: 'Read out reminders aloud via text-to-speech',
    ),
    _PermItem(
      icon: Icons.battery_saver_rounded,
      title: 'Background Execution',
      subtitle: 'Keep reminders working even when the app is closed',
    ),
  ];

  Future<void> _requestAll() async {
    setState(() => _requesting = true);

    if (Platform.isAndroid) {
      // Notifications (Android 13+)
      await Permission.notification.request();

      // Schedule exact alarm (Android 12+) — opens system settings
      final alarmStatus = await Permission.scheduleExactAlarm.status;
      if (!alarmStatus.isGranted) {
        await Permission.scheduleExactAlarm.request();
      }

      // Battery optimization
      final batteryStatus =
          await Permission.ignoreBatteryOptimizations.status;
      if (!batteryStatus.isGranted) {
        await Permission.ignoreBatteryOptimizations.request();
      }
    } else {
      // iOS: only notifications
      await Permission.notification.request();
    }

    if (mounted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('permissions_granted', true);
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6200EA), Color(0xFF9C27B0)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(),
              const Icon(Icons.health_and_safety_rounded,
                  color: Colors.white, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Permissions Needed',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'MediRemind needs a few permissions to reliably deliver medicine reminders.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 36),

              // Permission item list
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: _items
                      .map((item) => _PermissionRow(item: item))
                      .toList(),
                ),
              ),

              const Spacer(),

              // Allow button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _requesting ? null : _requestAll,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF6200EA),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: _requesting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Color(0xFF6200EA),
                            ),
                          )
                        : const Text(
                            'Grant Permissions',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),

              TextButton(
                onPressed: () =>
                    Navigator.of(context).pushReplacementNamed('/home'),
                child: Text(
                  'Skip for now',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermItem {
  final IconData icon;
  final String title;
  final String subtitle;
  const _PermItem(
      {required this.icon, required this.title, required this.subtitle});
}

class _PermissionRow extends StatelessWidget {
  final _PermItem item;
  const _PermissionRow({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF6200EA).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon,
                color: const Color(0xFF6200EA), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFF212121),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF757575),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
