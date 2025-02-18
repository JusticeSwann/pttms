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
  }) async {
    try {
      final data = {
        'device_id': deviceId,
        'route_id': routeId,
        'route_name': routeName,
        'active_time': activeTime,
        'waiting_time': waitingTime,
        'speed': speed,
        'status': status,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        'last_location': {
          'lat': lastLocation.latitude,
          'lng': lastLocation.longitude,
        },
        'route_trace': routeTrace.map((loc) => {'lat': loc.latitude, 'lng': loc.longitude}).toList(),
        'stops_made': stopsMade.map((loc) => {'lat': loc.latitude, 'lng': loc.longitude}).toList(),
        'pickup_point': {
          'lat': pickupPoint.latitude,
          'lng': pickupPoint.longitude,
        },
      };

      await _firestore.collection('vehicle_tracking').doc(deviceId).set(data, SetOptions(merge: true));
      print("Data uploaded successfully!");
    } catch (e) {
      print("Error uploading data: $e");
      throw Exception("Failed to upload tracking data");
    }
  }
}
