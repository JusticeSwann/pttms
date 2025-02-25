import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pttms/data/services/route_detection_service.dart';

class RoutesRepository {
  final RouteDetectionService routeDetectionService;

  RoutesRepository({required this.routeDetectionService});

  /// Returns the name of a nearby route if the user is within some threshold
  /// (the logic is delegated to [RouteDetectionService.findNearbyRoutes]).
  Future<String?> getNearbyRoute(LatLng position) async {
    return await routeDetectionService.findNearbyRoutes(position);
  }

  /// Synchronous version: checks if the user is near a route
  /// (depends on [RouteDetectionService.isNearRoute]).
  bool isPositionNearRoute(LatLng position) {
    return routeDetectionService.isNearRoute(position);
  }

  /// Returns the current detected route's polyline (synchronously).
  List<LatLng> getDetectedRoutePolyline() {
    return routeDetectionService.getDetectedRoutePolyline();
  }

  /// **New async method**: checks if the user is near a route asynchronously.
  /// This can be as simple as calling [findNearbyRoutes] and seeing if a route is returned,
  /// or you might add more distance-based logic here.
  Future<bool> isPositionNearRouteAsync(LatLng position, {int threshold = 50}) async {
    // For example, if [findNearbyRoutes] returns a route name if the user
    // is within 'threshold' meters, you can do:
    final routeName = await routeDetectionService.findNearbyRoutes(position);

    // If routeName is non-null, it means the user is near a route
    return routeName != null;
  }
}
