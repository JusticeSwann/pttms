import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class VehicleTrackingRepository {
  final FirebaseFirestore _firestore;

  VehicleTrackingRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> uploadVehicleData({
    required String deviceId,
    required int routeId,
    required String routeName,
    required int activeTime,
    required int waitingTime,
    required double speed,
    required String status,
    required LatLng lastLocation,
    required List<LatLng> routeTrace,
    required List<LatLng> stopsMade,
    required LatLng pickupPoint,
    required bool userOnRoute, // Label for ML.
    required double gpsAccuracy, // GPS Accuracy in meters.
    required double distanceTraveled, // Distance traveled in meters.
    required bool weekendIndicator, // True if weekend.
    required String weatherConditions, // Weather description.
    required String trafficConditions, // Traffic condition.
    // New detailed timing fields:
    required DateTime startedWaiting,
    required DateTime startedTraveling,
    required DateTime stoppedTraveling,
    required int totalCommuteTime, // e.g., in seconds.
    required int totalWaitTime, // e.g., in seconds.
    // New overall date/time of the update.
    required DateTime dateTime,
    // New traffic level fields:
    required String trafficLevel, // current traffic level: low, medium, high.
    required String averageTrafficLevel, // average traffic level at journey end.
  }) async {
    try {
      final now = DateTime.now().toUtc();
      final dayOfWeek = now.weekday;
      final timeOfDay =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      final data = {
        'device_id': deviceId,
        'route_id': routeId,
        'route_name': routeName,
        'active_time': activeTime,
        'waiting_time': waitingTime,
        'speed': speed,
        'status': status,
        // Detailed timing fields:
        'started_waiting': startedWaiting.toIso8601String(),
        'started_traveling': startedTraveling.toIso8601String(),
        'stopped_traveling': stoppedTraveling.toIso8601String(),
        'total_commute_time': totalCommuteTime,
        'total_wait_time': totalWaitTime,
        // Overall update time.
        'date_time': dateTime.toIso8601String(),
        'day_of_week': dayOfWeek,
        'time_of_day': timeOfDay,
        'last_location': {
          'lat': lastLocation.latitude,
          'lng': lastLocation.longitude,
        },
        'route_trace': routeTrace
            .map((loc) => {'lat': loc.latitude, 'lng': loc.longitude})
            .toList(),
        'stops_made': stopsMade
            .map((loc) => {'lat': loc.latitude, 'lng': loc.longitude})
            .toList(),
        'pickup_point': {
          'lat': pickupPoint.latitude,
          'lng': pickupPoint.longitude,
        },
        'user_on_route': userOnRoute,
        'gps_accuracy': gpsAccuracy,
        'distance_traveled': distanceTraveled,
        'weekend_indicator': weekendIndicator,
        'weather_conditions': weatherConditions,
        'traffic_conditions': trafficConditions,
        // New traffic level fields:
        'traffic_level': trafficLevel,
        'average_traffic_level': averageTrafficLevel,
      };

      await _firestore
          .collection('vehicle_tracking')
          .doc(deviceId)
          .set(data, SetOptions(merge: true));
      print("Data uploaded successfully!");
    } catch (e) {
      print("Error uploading data: $e");
      throw Exception("Failed to upload tracking data");
    }
  }
}
