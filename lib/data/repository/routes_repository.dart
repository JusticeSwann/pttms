import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pttms/data/services/route_detection_service.dart';

class RoutesRepository {
  final RouteDetectionService routeDetectionService;

  RoutesRepository({required this.routeDetectionService});

  Future<String?> getNearbyRoute(LatLng position) async {
    return await routeDetectionService.findNearbyRoutes(position);
  }

  bool isPositionNearRoute(LatLng position) {
    return routeDetectionService.isNearRoute(position);
  }

  List<LatLng> getDetectedRoutePolyline() {
    return routeDetectionService.getDetectedRoutePolyline();
  }
}
