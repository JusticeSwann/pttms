import 'dart:async';
import 'dart:math';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pttms/data/models/vehicle_location_data.dart';
import 'package:pttms/data/repository/active_vehicle_stream_repository.dart';
import 'package:pttms/services/traffic_service.dart';
import 'package:pttms/services/ticker.dart';
import 'package:pttms/utils/time_utils.dart'; // For formatTime()

part 'route_card_event.dart';
part 'route_card_state.dart';

/// This bloc listens to active vehicle data (filtered by status "active")
/// and computes the average wait time and ETA based on the polyline-constrained
/// distance between the user's location and the vehicle's streamed location.
/// If the streamed speed is 0, the previous ETA is retained.
class RouteCardBloc extends Bloc<RouteCardEvent, RouteCardState> {
  final String routeName;
  final ActiveVehicleStreamRepository activeVehicleStreamRepository;
  final TrafficService trafficService;
  final Ticker ticker;

  StreamSubscription<List<VehicleLocationData>>? _vehicleSubscription;
  StreamSubscription<int>? _tickerSubscription;

  // For ETA calculation.
  String _lastETA = "-";
  // Dummy polyline representing the route – replace with your actual polyline.
  final List<LatLng> _polyline = [
    LatLng(37.7749, -122.4194),
    LatLng(37.7750, -122.4180),
    LatLng(37.7755, -122.4170),
    LatLng(37.7760, -122.4160),
  ];
  // For demonstration, assume the user's location is at the start of the polyline.
  late LatLng _userLocation;

  RouteCardBloc({
    required this.routeName,
    required this.activeVehicleStreamRepository,
    required this.trafficService,
    required this.ticker,
  }) : super(const RouteCardInitial()) {
    _userLocation = _polyline.first;
    on<RouteCardStart>(_onStart);
    on<RouteCardVehiclesUpdated>(_onVehiclesUpdated);

    // Refresh every 5 seconds.
    _tickerSubscription = ticker.tick().listen((tickCount) {
      if (tickCount % 5 == 0) {
        add(const RouteCardStart());
      }
    });
  }

  Future<void> _onStart(RouteCardStart event, Emitter<RouteCardState> emit) async {
    await _vehicleSubscription?.cancel();
    _vehicleSubscription = activeVehicleStreamRepository
        .streamActiveVehicleLocations()
        .listen((vehicles) {
      add(RouteCardVehiclesUpdated(vehicles));
    });
  }

  // Helper functions:
  double _deg2rad(double deg) => deg * (pi / 180);

  double _haversineDistance(LatLng p1, LatLng p2) {
    const R = 6371; // Earth's radius in km
    double dLat = _deg2rad(p2.latitude - p1.latitude);
    double dLon = _deg2rad(p2.longitude - p1.longitude);
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(p1.latitude)) * cos(_deg2rad(p2.latitude)) *
        sin(dLon / 2) * sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  LatLng _projectPointOnSegment(LatLng p, LatLng a, LatLng b) {
    double ax = a.latitude;
    double ay = a.longitude;
    double bx = b.latitude;
    double by = b.longitude;
    double px = p.latitude;
    double py = p.longitude;
    double abx = bx - ax;
    double aby = by - ay;
    double apx = px - ax;
    double apy = py - ay;
    double abLenSq = abx * abx + aby * aby;
    double t = (apx * abx + apy * aby) / abLenSq;
    t = t.clamp(0, 1);
    return LatLng(ax + t * abx, ay + t * aby);
  }

  double _polylineDistanceBetween(List<LatLng> polyline, LatLng user, LatLng stream) {
    if (polyline.isEmpty) return 0;
    double minDistUser = double.infinity;
    int userIndex = 0;
    LatLng userProj = polyline.first;
    for (int i = 0; i < polyline.length - 1; i++) {
      LatLng proj = _projectPointOnSegment(user, polyline[i], polyline[i + 1]);
      double d = _haversineDistance(user, proj);
      if (d < minDistUser) {
        minDistUser = d;
        userIndex = i;
        userProj = proj;
      }
    }
    double minDistStream = double.infinity;
    int streamIndex = 0;
    LatLng streamProj = polyline.first;
    for (int i = 0; i < polyline.length - 1; i++) {
      LatLng proj = _projectPointOnSegment(stream, polyline[i], polyline[i + 1]);
      double d = _haversineDistance(stream, proj);
      if (d < minDistStream) {
        minDistStream = d;
        streamIndex = i;
        streamProj = proj;
      }
    }
    if (userIndex == streamIndex) {
      return _haversineDistance(userProj, streamProj);
    }
    double distance = 0;
    distance += _haversineDistance(userProj, polyline[userIndex + 1]);
    for (int i = userIndex + 1; i < streamIndex; i++) {
      distance += _haversineDistance(polyline[i], polyline[i + 1]);
    }
    distance += _haversineDistance(polyline[streamIndex], streamProj);
    return distance;
  }

  String _calculateETA(LatLng streamLocation, double speed) {
    if (speed == 0) return _lastETA;
    double distanceKm = _polylineDistanceBetween(_polyline, _userLocation, streamLocation);
    double etaMinutes = (distanceKm / (speed/10)) * 60;
    int roundedETA = etaMinutes.round();
    String newETA = "$roundedETA min";
    _lastETA = newETA;
    return newETA;
  }

  void _onVehiclesUpdated(RouteCardVehiclesUpdated event, Emitter<RouteCardState> emit) {
    final vehicles = event.vehicles;
    print("RouteCardBloc - Received ${vehicles.length} vehicles for route $routeName");
    for (final vehicle in vehicles) {
      print("Vehicle wait time: ${vehicle.waitTime} sec, speed: ${vehicle.speed} km/h");
    }
    int? averageWaitSec;
    bool hasData = vehicles.isNotEmpty;
    if (vehicles.isNotEmpty) {
      final totalWait = vehicles.fold<int>(0, (sum, v) => sum + v.waitTime);
      averageWaitSec = totalWait ~/ vehicles.length;
    } else {
      averageWaitSec = null;
    }
    print("RouteCardBloc - Computed average wait time: ${averageWaitSec ?? '-'} seconds");

    // Calculate ETA using the first vehicle's speed, if available.
    double vehicleSpeed = 40; // default speed
    if (vehicles.isNotEmpty) {
      vehicleSpeed = vehicles.first.speed;
      // If speed is zero, retain the last ETA.
    }
    String computedETA = vehicles.isNotEmpty ? _calculateETA(vehicles.first.lastLocation, vehicleSpeed) : "-";

    final now = DateTime.now();
    final lastUpdatedStr = formatTime(now); // e.g., "10:05 AM"

    emit(RouteCardLoaded(
      averageWaitTime: averageWaitSec,
      lastUpdated: lastUpdatedStr,
      eta: computedETA,
      routeName: routeName,
      hasData: hasData,
    ));
  }

  @override
  Future<void> close() {
    _vehicleSubscription?.cancel();
    _tickerSubscription?.cancel();
    return super.close();
  }
}
