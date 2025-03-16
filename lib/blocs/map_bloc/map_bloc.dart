// lib/blocs/map_bloc/map_bloc.dart
import 'dart:async';
import 'dart:math';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location_repository/location_repository.dart';
import 'package:pttms/data/repository/vehicle_tracking_repository.dart';
import 'package:pttms/data/services/route_detection_service.dart';

part 'map_event.dart';
part 'map_state.dart';

class MapBloc extends Bloc<MapEvent, MapState> {
  final LocationRepository locationRepository;
  final VehicleTrackingRepository vehicleTrackingRepository;
  final RouteDetectionService routeDetectionService;
  
  StreamSubscription<LatLng>? _locationSubscription;
  Timer? _uploadTimer;
  int _lastUploadSecond = -1;
  String? _sessionId; // Generated once per session.
  LatLng? _lastUploadedLocation; // Used to compute movement.
  String _lastStatus = "Waiting"; // Initial status.
  
  // Additional fields to track off-route and stationary conditions.
  DateTime? _offRouteStartTime;
  DateTime? _stationaryStartTime;
  
  // Fields for route data.
  int? _routeId;
  String? _routeName;
  final List<LatLng> _routeTrace = [];
  final List<LatLng> _stopsMade = [];
  
  // Default speed threshold in km/h for low traffic.
  static const double speedThresholdKmh = 15.0;
  // Distance threshold for adding a new point to route trace.
  static const double traceDistanceThreshold = 5.0;
  
  MapBloc({
    required this.locationRepository,
    required this.vehicleTrackingRepository,
    required this.routeDetectionService,
  }) : super(MapInitial()) {
    on<MapLoad>(_onMapLoad);
    on<UpdateCameraPosition>(_onUpdateCameraPosition);
    on<MoveToCurrentLocation>(_onMoveToCurrentLocation);
    on<UploadVehicleTrackingData>(_onUploadVehicleTrackingData);
    
    // Subscribe to continuous location updates.
    _locationSubscription =
        locationRepository.trackLocationUpdates().listen((latLng) {
      add(UpdateCameraPosition(latLng));
    });
    
    // Set up a periodic timer that fires every second.
    _uploadTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final int currentSecond = DateTime.now().second;
      // Trigger upload every 5 seconds.
      if (currentSecond % 5 == 0 && currentSecond != _lastUploadSecond) {
        _lastUploadSecond = currentSecond;
        if (state is MapLoaded) {
          final currentState = state as MapLoaded;
          final now = DateTime.now();
          // Initialize session ID if not already done.
          _sessionId ??= "session_${now.millisecondsSinceEpoch}";
          
          // If no route trace exists yet, initialize route data.
          if (_routeTrace.isEmpty) {
            await _initializeRouteData(currentState.position);
            _routeTrace.add(currentState.position);
          } else {
            // Calculate distance from last point in the route trace.
            final lastPoint = _routeTrace.last;
            final distance = _calculateDistance(
              lastPoint.latitude,
              lastPoint.longitude,
              currentState.position.latitude,
              currentState.position.longitude,
            );
            if (distance >= traceDistanceThreshold) {
              // Append new point and clear stops.
              _routeTrace.add(currentState.position);
              _stopsMade.clear();
            } else {
              // Record as a stop if not already recorded.
              if (_stopsMade.isEmpty ||
                  _calculateDistance(
                        _stopsMade.last.latitude,
                        _stopsMade.last.longitude,
                        currentState.position.latitude,
                        currentState.position.longitude,
                      ) >= traceDistanceThreshold) {
                _stopsMade.add(currentState.position);
              }
            }
          }
          
          // Compute instantaneous speed (in km/h) over the 5-second interval.
          double computedSpeedKmh = 0.0;
          if (_lastUploadedLocation != null) {
            final movement = _calculateDistance(
              _lastUploadedLocation!.latitude,
              _lastUploadedLocation!.longitude,
              currentState.position.latitude,
              currentState.position.longitude,
            );
            computedSpeedKmh = (movement / 5.0) * 3.6;
          }
          
          // Determine off-route conditions.
          bool onRouteWithin5 = routeDetectionService.isNearRoute(
              currentState.position, distanceThreshold: 5);
          bool onRouteWithin30 = routeDetectionService.isNearRoute(
              currentState.position, distanceThreshold: 30);
          bool offRouteByMoreThan5 = !onRouteWithin5;
          bool offRouteByMoreThan30 = !onRouteWithin30;
          
          String newStatus = _lastStatus; // Start with previous status.
          
          // Immediate false positive: off route by >30 meters.
          if (offRouteByMoreThan30) {
            newStatus = "false positive";
          } else if (offRouteByMoreThan5 && !offRouteByMoreThan30) {
            _offRouteStartTime ??= now;
            if (now.difference(_offRouteStartTime!).inMinutes >= 10) {
              newStatus = "false positive";
            }
          } else {
            _offRouteStartTime = null;
          }
          
          // Check stationary condition when on route and not false positive.
          if (onRouteWithin5 && newStatus != "false positive") {
            if (computedSpeedKmh < 1.0) {
              _stationaryStartTime ??= now;
              // Assume low traffic threshold for stationary (10 minutes).
              if (now.difference(_stationaryStartTime!).inMinutes >= 10) {
                newStatus = "false positive";
              }
            } else {
              _stationaryStartTime = null;
            }
          } else {
            _stationaryStartTime = null;
          }
          
          // Transition to active if not false positive.
          if (newStatus != "false positive") {
            if (_lastStatus == "active" || computedSpeedKmh > speedThresholdKmh) {
              newStatus = "active";
            } else {
              newStatus = "waiting";
            }
          }
          
          // Once active, do not revert to waiting.
          if (_lastStatus == "active" && newStatus == "waiting") {
            newStatus = "active";
          }
          
          // Save computed status and update last uploaded location.
          _lastStatus = newStatus;
          _lastUploadedLocation = currentState.position;
          
          // Dispatch the upload event with the collected data.
          add(UploadVehicleTrackingData(
            deviceId: _sessionId!,
            routeId: _routeId ?? 0,
            routeName: _routeName ?? "Unknown Route",
            activeTime: 0, // Update with actual active time if tracked.
            waitingTime: 0, // Update with actual waiting time if tracked.
            speed: computedSpeedKmh,
            status: newStatus,
            lastLocation: currentState.position,
            routeTrace: List<LatLng>.from(_routeTrace),
            stopsMade: List<LatLng>.from(_stopsMade),
            pickupPoint: currentState.position,
            userOnRoute: true,
            gpsAccuracy: 5.0,
            distanceTraveled: 0.0, // Update cumulative distance if needed.
            weekendIndicator: now.weekday >= 6,
            weatherConditions: "Clear",
            trafficConditions: "Moderate",
            startedWaiting: now,
            startedTraveling: now,
            stoppedTraveling: now,
            totalCommuteTime: 0,
            totalWaitTime: 0,
            dateTime: now,
            trafficLevel: "Low", // Replace with actual traffic data if available.
            averageTrafficLevel: "Moderate",
          ));
          
          // If false positive is detected, cancel further updates.
          if (newStatus == "false positive") {
            print("False positive detected, stopping updates.");
            _uploadTimer?.cancel();
            _locationSubscription?.cancel();
          }
        }
      }
    });
  }
  
  Future<void> _initializeRouteData(LatLng position) async {
    // Use findNearbyRoutes to get the nearest route's name if within 10 meters.
    String? nearestRoute = await routeDetectionService.findNearbyRoutes(position);
    if (nearestRoute != null) {
      _routeName = nearestRoute;
      // Load routes and determine the route ID by matching the name.
      List<Map<String, dynamic>> routes = await routeDetectionService.loadRoutesFromJson();
      int index = routes.indexWhere((route) => route['name'] == nearestRoute);
      _routeId = index >= 0 ? index + 1 : 1;
    } else {
      _routeName = "Unknown";
      _routeId = 0;
    }
    print("Initialized route data: route_id=$_routeId, route_name=$_routeName");
  }
  
  Future<void> _onMapLoad(MapLoad event, Emitter<MapState> emit) async {
    emit(MapLoading());
    try {
      final LatLng? position = await locationRepository.getCurrentLocation();
      if (position == null) {
        emit(const MapError('Location permission denied or unavailable.'));
      } else {
        emit(MapLoaded(position: position));
      }
    } catch (e) {
      emit(MapError('Failed to load map: ${e.toString()}'));
    }
  }
  
  void _onUpdateCameraPosition(UpdateCameraPosition event, Emitter<MapState> emit) {
    if (state is MapLoaded) {
      emit(MapLoaded(position: event.position));
    }
  }
  
  Future<void> _onMoveToCurrentLocation(MoveToCurrentLocation event, Emitter<MapState> emit) async {
    if (state is MapLoaded) {
      try {
        final LatLng? position = await locationRepository.getCurrentLocation();
        if (position != null) {
          emit(MapLoaded(position: position));
        }
      } catch (e) {
        emit(MapError('Failed to fetch current location: ${e.toString()}'));
      }
    }
  }
  
  Future<void> _onUploadVehicleTrackingData(UploadVehicleTrackingData event, Emitter<MapState> emit) async {
    try {
      await vehicleTrackingRepository.uploadVehicleData(
        deviceId: event.deviceId,
        routeId: event.routeId,
        routeName: event.routeName,
        activeTime: event.activeTime,
        waitingTime: event.waitingTime,
        speed: event.speed,
        status: event.status,
        lastLocation: event.lastLocation,
        routeTrace: event.routeTrace,
        stopsMade: event.stopsMade,
        pickupPoint: event.pickupPoint,
        userOnRoute: event.userOnRoute,
        gpsAccuracy: event.gpsAccuracy,
        distanceTraveled: event.distanceTraveled,
        weekendIndicator: event.weekendIndicator,
        weatherConditions: event.weatherConditions,
        trafficConditions: event.trafficConditions,
        startedWaiting: event.startedWaiting,
        startedTraveling: event.startedTraveling,
        stoppedTraveling: event.stoppedTraveling,
        totalCommuteTime: event.totalCommuteTime,
        totalWaitTime: event.totalWaitTime,
        dateTime: event.dateTime,
        trafficLevel: event.trafficLevel,
        averageTrafficLevel: event.averageTrafficLevel,
      );
      print("Vehicle tracking data uploaded successfully!");
    } catch (e) {
      print("Error uploading vehicle tracking data: $e");
    }
  }
  
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371000; // meters
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }
  
  double _degreesToRadians(double degrees) => degrees * pi / 180;
  
  @override
  Future<void> close() {
    _locationSubscription?.cancel();
    _uploadTimer?.cancel();
    return super.close();
  }
}
