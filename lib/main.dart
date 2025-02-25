import 'package:flutter/material.dart';
import 'package:pttms/app.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Global instance for local notifications.
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Callback for Workmanager background task.
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print("Background tracking running...");
    return Future.value(true);
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Request location permission.
  await _requestLocationPermission();
  // Request notification permission.
  await _requestNotificationPermission();

  // Initialize Workmanager for background tasks.
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: true, // Set to false in production.
  );

  // Optionally, register a periodic background task.
  await Workmanager().registerPeriodicTask(
    "backgroundTracking",
    "backgroundTrackingTask",
    frequency: const Duration(minutes: 15),
    inputData: <String, dynamic>{},
  );

  // Initialize local notifications.
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  final InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Do not show the persistent notification here.
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

Future<void> showPersistentNotification() async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'tracking_channel', // Channel ID
    'Tracking Notifications', // Channel name
    channelDescription: 'Your location is being tracked along the route.',
    importance: Importance.max,
    priority: Priority.high,
    ongoing: true, // makes notification non-dismissible
    autoCancel: false,
  );

  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

  await flutterLocalNotificationsPlugin.show(
    0, // Notification ID
    'Tracking Active',
    'You are being tracked along the route.',
    platformChannelSpecifics,
  );
}
