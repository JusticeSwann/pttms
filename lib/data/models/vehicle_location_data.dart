import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class VehicleLocationData {
  final LatLng lastLocation;
  final int waitTime;
  final List<LatLng> stopsMade;

  VehicleLocationData({
    required this.lastLocation,
    required this.waitTime,
    required this.stopsMade,
  });

  factory VehicleLocationData.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final lastLocationData = data['last_location'] as Map<String, dynamic>;
    final stopsData = data['stops_made'] as List<dynamic>? ?? [];
    return VehicleLocationData(
      lastLocation: LatLng(
        (lastLocationData['lat'] as num).toDouble(),
        (lastLocationData['lng'] as num).toDouble(),
      ),
      waitTime: data['wait_time'] as int? ?? 0,
      stopsMade: stopsData.map((stop) {
        final stopMap = stop as Map<String, dynamic>;
        return LatLng(
          (stopMap['lat'] as num).toDouble(),
          (stopMap['lng'] as num).toDouble(),
        );
      }).toList(),
    );
  }
}
