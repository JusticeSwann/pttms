// lib/main.dart
import 'package:flutter/material.dart';
import 'package:pttms/app.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:workmanager/workmanager.dart';
import 'package:pttms/background/callback_dispatcher.dart';
import 'package:pttms/services/notification_service.dart'; // for initialization if needed

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for offline data persistence.
  await Hive.initFlutter();
  await Hive.openBox('trackingUpdates');

  // Initialize Firebase.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Request permissions.
  await _requestLocationPermission();
  await _requestNotificationPermission();

  // Initialize Workmanager for background tasks using the full callbackDispatcher.
  await Workmanager().initialize(
    callbackDispatcher, // Full implementation from background/callback_dispatcher.dart
    isInDebugMode: true, // Set to false in production.
  );

  // Register a periodic background task.
  await Workmanager().registerPeriodicTask(
    "backgroundTracking",
    "backgroundTrackingTask",
    frequency: const Duration(minutes: 15),
    inputData: <String, dynamic>{},
  );

  // Optionally, initialize local notifications here if required.
  // (Initialization could also occur in your notification service.)
  
  runApp(const MyApp());
}

Future<void> _requestLocationPermission() async {
  final status = await Permission.location.request();
  if (status.isGranted) {
    print('Location permission granted');
  } else if (status.isDenied) {
    print('Location permission denied');
  } else if (status.isPermanentlyDenied) {
    print('Location permission permanently denied. Opening app settings.');
    openAppSettings();
  }
}

Future<void> _requestNotificationPermission() async {
  final status = await Permission.notification.request();
  if (status.isGranted) {
    print('Notification permission granted');
  } else {
    print('Notification permission denied');
  }
}
