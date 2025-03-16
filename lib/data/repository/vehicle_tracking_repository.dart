// lib/data/repository/vehicle_tracking_repository.dart
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
    required bool userOnRoute,
    required double gpsAccuracy,
    required double distanceTraveled,
    required bool weekendIndicator,
    required String weatherConditions,
    required String trafficConditions,
    // Detailed timing fields:
    required DateTime startedWaiting,
    required DateTime startedTraveling,
    required DateTime stoppedTraveling,
    required int totalCommuteTime,
    required int totalWaitTime,
    // Overall update time:
    required DateTime dateTime,
    // Traffic level fields:
    required String trafficLevel,
    required String averageTrafficLevel,
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
        'started_waiting': startedWaiting.toIso8601String(),
        'started_traveling': startedTraveling.toIso8601String(),
        'stopped_traveling': stoppedTraveling.toIso8601String(),
        'total_commute_time': totalCommuteTime,
        'total_wait_time': totalWaitTime,
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
        'traffic_level': trafficLevel,
        'average_traffic_level': averageTrafficLevel,
      };

      // Write to the "actor_report" collection.
      await _firestore
          .collection('actor_report')
          .doc(deviceId)
          .set(data, SetOptions(merge: true));
      print("Data uploaded successfully!");
    } catch (e) {
      print("Error uploading data: $e");
      throw Exception("Failed to upload tracking data");
    }
  }
}
