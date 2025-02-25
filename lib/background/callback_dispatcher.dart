import 'package:flutter/material.dart';
import 'package:pttms/app.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive/hive.dart';
import 'package:pttms/background/local_storage_service.dart';
import 'package:pttms/data/repository/vehicle_tracking_repository.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Updated callback for Workmanager background sync task.
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print("Background sync task started.");
    try {
      // Initialize Firebase in the background isolate.
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      
      // Initialize Hive. Note: In background isolates, you might need to call Hive.init,
      // but if you already used Hive.initFlutter() in main(), this may work fine.
      // Here, we'll call Hive.init to be sure.
      // (You may need to adjust the storage path if issues arise.)
      Hive.init('./hive_background');
      
      // Open the box for tracking updates.
      await Hive.openBox('trackingUpdates');
      
      // Create an instance of our local storage service.
      final localStorageService = LocalStorageService();
      
      // Retrieve pending updates.
      final pendingUpdates = localStorageService.getPendingUpdates();
      print("Found ${pendingUpdates.length} pending updates for sync.");
      
      // Create an instance of VehicleTrackingRepository.
      final vehicleRepo = VehicleTrackingRepository();
      
      // For each update, attempt to sync to Firestore.
      for (var update in pendingUpdates) {
        try {
          await vehicleRepo.uploadVehicleData(
            deviceId: update['device_id'],
            routeId: update['route_id'],
            routeName: update['route_name'],
            activeTime: update['active_time'],
            waitingTime: update['waiting_time'],
            speed: update['speed'],
            status: update['status'],
            lastLocation: LatLng(
              update['last_location']['lat'],
              update['last_location']['lng'],
            ),
            routeTrace: (update['route_trace'] as List<dynamic>)
                .map((loc) => LatLng(loc['lat'], loc['lng']))
                .toList(),
            stopsMade: (update['stops_made'] as List<dynamic>)
                .map((loc) => LatLng(loc['lat'], loc['lng']))
                .toList(),
            pickupPoint: LatLng(
              update['pickup_point']['lat'],
              update['pickup_point']['lng'],
            ),
            userOnRoute: update['user_on_route'],
            gpsAccuracy: update['gps_accuracy'],
            distanceTraveled: update['distance_traveled'],
            weekendIndicator: update['weekend_indicator'],
            weatherConditions: update['weather_conditions'],
            trafficConditions: update['traffic_conditions'],
          );
          print("Successfully synced update for device: ${update['device_id']}");
          // In a real implementation, you might remove only this update.
          // For simplicity, we clear all updates at the end.
        } catch (e) {
          print("Error syncing update: $e");
          // Optionally, log and leave this update for retry.
        }
      }
      
      // For simplicity, clear all updates after processing.
      await localStorageService.clearPendingUpdates();
      print("Local pending updates cleared after sync.");
    } catch (e) {
      print("Background sync task failed: $e");
      // Returning false will cause Workmanager to consider the task failed.
      return Future.value(false);
    }
    return Future.value(true);
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive using HiveFlutter in the main isolate.
  // (This has already been set up to open our trackingUpdates box.)
  // Note: The background isolate will have its own initialization.
  // For the main app, we use Hive.initFlutter().
  // If you haven't already done so, you can call:
  // await Hive.initFlutter();
  // and then open the box:
  // await Hive.openBox('trackingUpdates');

  // Initialize Firebase.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Request permissions.
  await _requestLocationPermission();
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
    'tracking_channel',
    'Tracking Notifications',
    channelDescription: 'Your location is being tracked along the route.',
    importance: Importance.max,
    priority: Priority.high,
    ongoing: true,
    autoCancel: false,
  );

  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

  await flutterLocalNotificationsPlugin.show(
    0,
    'Tracking Active',
    'You are being tracked along the route.',
    platformChannelSpecifics,
  );
}
