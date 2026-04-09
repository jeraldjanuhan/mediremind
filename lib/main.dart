// lib/main.dart
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/medicine_provider.dart';
import 'screens/home_screen.dart';
import 'screens/permission_screen.dart';
import 'screens/splash_screen.dart';

// Background alarm callback declared in alarm_service.dart
// (top-level + @pragma('vm:entry-point'))

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AndroidAlarmManager.initialize();

  runApp(
    ChangeNotifierProvider(
      create: (_) => MedicineProvider()..init(),
      child: const MediRemindApp(),
    ),
  );
}

class MediRemindApp extends StatelessWidget {
  const MediRemindApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MediRemind',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6200EA),
          primary: const Color(0xFF6200EA),
        ),
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFFAFAFA),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
        ),
        snackBarTheme:
            const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (_) => const SplashScreen(),
        '/permissions': (_) => const PermissionScreen(),
        '/home': (_) => const HomeScreen(),
      },
    );
  }
}
