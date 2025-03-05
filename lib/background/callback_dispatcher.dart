// lib/background/callback_dispatcher.dart
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:pttms/background/local_storage_service.dart';
import 'package:pttms/data/repository/vehicle_tracking_repository.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print("Background sync task started.");
    try {
      // Initialize Firebase in the background isolate.
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Initialize Hive in the background isolate.
      Hive.init('./hive_background');
      await Hive.openBox('trackingUpdates');

      // Create an instance of LocalStorageService.
      final localStorageService = LocalStorageService();

      // Retrieve pending updates.
      final pendingUpdates = localStorageService.getPendingUpdates();
      print("Found ${pendingUpdates.length} pending updates for sync.");

      // Create an instance of VehicleTrackingRepository.
      final vehicleRepo = VehicleTrackingRepository();

      // Attempt to upload each pending update.
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
            startedWaiting: DateTime.parse(update['started_waiting']),
            startedTraveling: DateTime.parse(update['started_traveling']),
            stoppedTraveling: DateTime.parse(update['stopped_traveling']),
            totalCommuteTime: update['total_commute_time'],
            totalWaitTime: update['total_wait_time'],
            dateTime: DateTime.parse(update['date_time']),
            trafficLevel: update['traffic_level'],
            averageTrafficLevel: update['average_traffic_level'],
          );
          print("Successfully synced update for device: ${update['device_id']}");
        } catch (e) {
          print("Error syncing update: $e");
          // Optionally leave the update for retry.
        }
      }

      // Clear updates after processing.
      await localStorageService.clearPendingUpdates();
      print("Local pending updates cleared after sync.");
    } catch (e) {
      print("Background sync task failed: $e");
      return Future.value(false);
    }
    return Future.value(true);
  });
}
