import 'dart:math';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RouteDetectionService {
  List<Map<String, dynamic>> _nearbyRoutes = [];
  List<LatLng> _lastDetectedRoutePolyline = []; // ✅ Store last detected route

  Future<List<Map<String, dynamic>>> loadRoutesFromJson() async {
    final String response = await rootBundle.loadString('assets/routes.json');
    final data = json.decode(response) as Map<String, dynamic>;
    return (data['routes'] as List).map((e) => e as Map<String, dynamic>).toList();
  }

  Future<String?> findNearbyRoutes(LatLng position) async {
    final routes = await loadRoutesFromJson();
    _nearbyRoutes = [];
    _lastDetectedRoutePolyline.clear(); // ✅ Clear previous route polyline

    String? closestRouteName;
    double minDistance = double.infinity;

    for (var route in routes) {
      try {
        final polyline = (route['polyline'] as List)
            .map((point) => LatLng(point[0], point[1])) // ✅ Convert to LatLng list
            .toList();

        final distance = _calculateMinDistanceToRoute(position, polyline);

        if (distance <= 300) {
          _nearbyRoutes.add({
            ...route,
            'polyline': polyline,
          });
          if (distance < minDistance) {
            minDistance = distance;
            closestRouteName = route['name'];
            _lastDetectedRoutePolyline = polyline; // ✅ Store polyline
          }
        }
      } catch (e) {
        print('Error parsing route polyline: $e');
      }
    }

    print('🚏 Closest Route: $closestRouteName');
    return closestRouteName;
  }

  /// ✅ Returns the polyline of the last detected route
  List<LatLng> getDetectedRoutePolyline() {
    return _lastDetectedRoutePolyline;
  }

  bool isNearRoute(LatLng position, {int distanceThreshold = 50}) {
    return _nearbyRoutes.any((route) {
      try {
        final polyline = (route['polyline'] as List<LatLng>);
        return _isNearRoute(position, polyline, distanceThreshold);
      } catch (e) {
        print('Error checking route: $e');
        return false;
      }
    });
  }

  double _calculateMinDistanceToRoute(LatLng position, List<LatLng> polyline) {
    double minDistance = double.infinity;
    for (int i = 0; i < polyline.length - 1; i++) {
      final segmentStart = polyline[i];
      final segmentEnd = polyline[i + 1];
      final distance = _distanceToSegment(
        position.latitude,
        position.longitude,
        segmentStart.latitude,
        segmentStart.longitude,
        segmentEnd.latitude,
        segmentEnd.longitude,
      );
      minDistance = min(minDistance, distance);
    }
    return minDistance;
  }

  bool _isNearRoute(LatLng position, List<LatLng> polyline, int distanceThreshold) {
    for (int i = 0; i < polyline.length - 1; i++) {
      final segmentStart = polyline[i];
      final segmentEnd = polyline[i + 1];
      final distance = _distanceToSegment(
        position.latitude,
        position.longitude,
        segmentStart.latitude,
        segmentStart.longitude,
        segmentEnd.latitude,
        segmentEnd.longitude,
      );
      if (distance <= distanceThreshold) return true;
    }
    return false;
  }

  double _distanceToSegment(double lat, double lon, double lat1, double lon1, double lat2, double lon2) {
    final p = [lat, lon];
    final v = [lat1, lon1];
    final w = [lat2, lon2];
    final l2 = pow(lat2 - lat1, 2) + pow(lon2 - lon1, 2);
    if (l2 == 0.0) return _calculateDistance(lat, lon, lat1, lon1);

    var t = ((p[0] - v[0]) * (w[0] - v[0]) + (p[1] - v[1]) * (w[1] - v[1])) / l2;
    t = max(0, min(1, t));
    final projection = [v[0] + t * (w[0] - v[0]), v[1] + t * (w[1] - v[1])];
    return _calculateDistance(lat, lon, projection[0], projection[1]);
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371000; // in meters
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) * sin(dLon / 2);
    return earthRadius * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _degreesToRadians(double degrees) => degrees * pi / 180;
}
