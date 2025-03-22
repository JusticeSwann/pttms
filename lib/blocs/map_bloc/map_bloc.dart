// lib/blocs/map_bloc/map_bloc.dart
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location_repository/location_repository.dart';
import 'package:pttms/data/repository/vehicle_tracking_repository.dart';
import 'package:pttms/data/services/route_detection_service.dart';
import 'package:pttms/services/ticker.dart';
import 'package:pttms/utils/map_helpers.dart'; // Expects updateRouteData and computeSpeedKmh

part 'map_event.dart';
part 'map_state.dart';

class MapBloc extends Bloc<MapEvent, MapState> {
  final String deviceId;
  final LocationRepository locationRepository;
  final VehicleTrackingRepository vehicleTrackingRepository;
  final RouteDetectionService routeDetectionService;
  final Ticker ticker; // Injected ticker

  StreamSubscription<LatLng>? _locationSubscription;
  StreamSubscription<int>? _tickerSubscription;
  LatLng? _lastUploadedLocation;
  String _lastStatus = "Waiting";

  // Time fields.
  DateTime? _initialUploadTime;
  DateTime? _startedWaiting;
  DateTime? _startedTraveling;
  DateTime? _stoppedTraveling;
  String? _timeOfDay;

  // Off-route and stationary conditions.
  DateTime? _offRouteStartTime;
  DateTime? _stationaryStartTime;

  // Route data.
  int? _routeId;
  String? _routeName;
  final List<LatLng> _routeTrace = [];
  final List<LatLng> _stopsMade = [];

  // Default thresholds.
  static const double speedThresholdKmh = 15.0;
  static const double traceDistanceThreshold = 5.0;

  // Session document ID.
  String? _sessionDocId;

  MapBloc({
    required this.deviceId,
    required this.locationRepository,
    required this.vehicleTrackingRepository,
    required this.routeDetectionService,
    required this.ticker,
  }) : super(MapInitial()) {
    on<MapLoad>(_onMapLoad);
    on<UpdateCameraPosition>(_onUpdateCameraPosition);
    on<MoveToCurrentLocation>(_onMoveToCurrentLocation);
    on<UploadVehicleTrackingData>(_onUploadVehicleTrackingData);
    on<MapTick>(_onMapTick);

    // Subscribe to continuous location updates.
    _locationSubscription = locationRepository
        .trackLocationUpdates()
        .listen((latLng) => add(UpdateCameraPosition(latLng)));

    // Subscribe to the ticker stream (1 tick per second).
    _tickerSubscription = ticker.tick().listen((tickCount) {
      add(MapTick(tickCount));
    });
  }

  /// Loads the initial map state.
  Future<void> _onMapLoad(MapLoad event, Emitter<MapState> emit) async {
    emit(MapLoading());
    try {
      final LatLng? position = await locationRepository.getCurrentLocation();
      if (position == null) {
        emit(const MapError('Location permission denied or unavailable.'));
      } else {
        emit(MapLoaded(position: position, routeTrace: []));
      }
    } catch (e) {
      emit(MapError('Failed to load map: ${e.toString()}'));
    }
  }

  /// Updates the camera position whenever a new location is received.
  void _onUpdateCameraPosition(UpdateCameraPosition event, Emitter<MapState> emit) {
    if (state is MapLoaded) {
      final currentState = state as MapLoaded;
      // Preserve the existing routeTrace.
      emit(MapLoaded(position: event.position, routeTrace: currentState.routeTrace));
    }
  }

  /// Moves the camera to the current device location.
  Future<void> _onMoveToCurrentLocation(MoveToCurrentLocation event, Emitter<MapState> emit) async {
    if (state is MapLoaded) {
      try {
        final LatLng? position = await locationRepository.getCurrentLocation();
        if (position != null) {
          final currentState = state as MapLoaded;
          emit(MapLoaded(position: position, routeTrace: currentState.routeTrace));
        }
      } catch (e) {
        emit(MapError('Failed to fetch current location: ${e.toString()}'));
      }
    }
  }

  /// Processes the tick events (once per second) and every 5 seconds updates the route trace.
  Future<void> _onMapTick(MapTick event, Emitter<MapState> emit) async {
    if (event.tickCount % 5 == 0 && state is MapLoaded) {
      final currentState = state as MapLoaded;
      final now = DateTime.now();

      // Initialize time fields on first tick.
      if (_initialUploadTime == null) {
        _initialUploadTime = now;
        _startedWaiting = now;
        _timeOfDay = "${now.hour.toString().padLeft(2, '0')}:00";
      }

      // Generate session document ID if needed.
      _sessionDocId ??= "session_${now.millisecondsSinceEpoch}";

      // Update route trace.
      if (_routeTrace.isEmpty) {
        await _initializeRouteData(currentState.position);
        _routeTrace.add(currentState.position);
      } else {
        updateRouteData(
          currentPosition: currentState.position,
          routeTrace: _routeTrace,
          stopsMade: _stopsMade,
          threshold: traceDistanceThreshold,
        );
      }

      // Compute instantaneous speed in km/h.
      double computedSpeedKmh = 0.0;
      if (_lastUploadedLocation != null) {
        computedSpeedKmh = computeSpeedKmh(_lastUploadedLocation!, currentState.position, 5.0);
      }

      // Off-route and stationary logic.
      bool onRouteWithin5 = routeDetectionService.isNearRoute(currentState.position, distanceThreshold: 5);
      bool onRouteWithin30 = routeDetectionService.isNearRoute(currentState.position, distanceThreshold: 30);
      bool offRouteByMoreThan5 = !onRouteWithin5;
      bool offRouteByMoreThan30 = !onRouteWithin30;
      String newStatus = _lastStatus;

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

      if (onRouteWithin5 && newStatus != "false positive") {
        if (computedSpeedKmh < 1.0) {
          _stationaryStartTime ??= now;
          if (now.difference(_stationaryStartTime!).inMinutes >= 10) {
            newStatus = "false positive";
          }
        } else {
          _stationaryStartTime = null;
        }
      } else {
        _stationaryStartTime = null;
      }

      // Transition logic.
      if (newStatus == "waiting") {
        _startedTraveling = null;
        _stoppedTraveling = null;
      } else if (newStatus == "active") {
        if (_startedTraveling == null) {
          _startedTraveling = now;
        }
      } else if (newStatus == "complete") {
        if (_stoppedTraveling == null) {
          _stoppedTraveling = now;
        }
      }

      if (newStatus != "false positive") {
        if (_lastStatus != "active" && computedSpeedKmh > speedThresholdKmh) {
          newStatus = "active";
        } else if (_lastStatus == "active") {
          newStatus = "active";
        } else {
          newStatus = "waiting";
        }
      }

      if (_lastStatus == "active" && newStatus == "waiting") {
        newStatus = "active";
      }

      _lastStatus = newStatus;
      _lastUploadedLocation = currentState.position;

      // Total commute time.
      final int totalCommuteTime = now.difference(_initialUploadTime!).inSeconds;

      // Trigger the upload event (this could be handled by another bloc or service).
      add(UploadVehicleTrackingData(
        docId: _sessionDocId!,
        deviceId: deviceId,
        routeId: _routeId ?? 0,
        routeName: _routeName ?? "Unknown Route",
        activeTime: 0,         // Update as needed.
        waitingTime: 0,        // Update as needed.
        speed: computedSpeedKmh,
        status: newStatus,
        lastLocation: currentState.position,
        routeTrace: List<LatLng>.from(_routeTrace),
        stopsMade: List<LatLng>.from(_stopsMade),
        pickupPoint: currentState.position,
        userOnRoute: true,
        gpsAccuracy: 5.0,
        distanceTraveled: 0.0, // Update as needed.
        weekendIndicator: now.weekday >= 6,
        weatherConditions: "Clear",
        trafficConditions: "Moderate",
        startedWaiting: _startedWaiting!,
        startedTraveling: newStatus == "active" ? _startedTraveling : null,
        stoppedTraveling: newStatus == "complete" ? _stoppedTraveling : null,
        totalWaitTime: 0,      // Update as needed.
        dateTime: _initialUploadTime!,
        trafficLevel: "Low",
        averageTrafficLevel: "Moderate",
        totalCommuteTime: totalCommuteTime,
      ));

      // If a false positive is detected, stop updates; otherwise, emit a new state.
      if (newStatus == "false positive") {
        print("False positive detected, stopping updates.");
        _locationSubscription?.cancel();
        _tickerSubscription?.cancel();
      } else {
        emit(MapLoaded(position: currentState.position, routeTrace: List<LatLng>.from(_routeTrace)));
      }
    }
  }

  /// Handles uploading vehicle tracking data.
  Future<void> _onUploadVehicleTrackingData(UploadVehicleTrackingData event, Emitter<MapState> emit) async {
    try {
      await vehicleTrackingRepository.uploadVehicleData(
        docId: event.docId,
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

  /// Initializes route data (route ID and route name) based on the current position.
  Future<void> _initializeRouteData(LatLng position) async {
    final String? nearestRoute = await routeDetectionService.findNearbyRoutes(position);
    if (nearestRoute != null) {
      _routeName = nearestRoute;
      final routes = await routeDetectionService.loadRoutesFromJson();
      int index = routes.indexWhere((r) => r['name'] == nearestRoute);
      _routeId = index >= 0 ? index + 1 : 1;
    } else {
      _routeName = "Unknown";
      _routeId = 0;
    }
    print("Initialized route data: route_id=$_routeId, route_name=$_routeName");
  }

  @override
  Future<void> close() {
    _locationSubscription?.cancel();
    _tickerSubscription?.cancel();
    return super.close();
  }
}
