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
import 'package:pttms/data/repository/active_vehicle_stream_repository.dart';
import 'package:pttms/data/models/vehicle_location_data.dart';

part 'map_event.dart';
part 'map_state.dart';

class MapBloc extends Bloc<MapEvent, MapState> {
  final String deviceId;
  final LocationRepository locationRepository;
  final VehicleTrackingRepository vehicleTrackingRepository;
  final RouteDetectionService routeDetectionService;
  final Ticker ticker;
  final ActiveVehicleStreamRepository activeVehicleStreamRepository;

  StreamSubscription<LatLng>? _locationSubscription;
  StreamSubscription<int>? _tickerSubscription;
  StreamSubscription<List<VehicleLocationData>>? _activeVehicleSubscription;

  // For upload & route trace logic.
  LatLng? _lastUploadedLocation;
  String _lastStatus = "waiting"; // initial status is waiting (all lowercase)
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

  // For streaming active vehicle data.
  List<VehicleLocationData> _latestActiveVehicles = [];

  // Field to accumulate waiting time in seconds.
  int _accumulatedWaitTime = 0;

  MapBloc({
    required this.deviceId,
    required this.locationRepository,
    required this.vehicleTrackingRepository,
    required this.routeDetectionService,
    required this.ticker,
    required this.activeVehicleStreamRepository,
  }) : super(MapInitial()) {
    on<MapLoad>(_onMapLoad);
    on<UpdateCameraPosition>(_onUpdateCameraPosition);
    on<MoveToCurrentLocation>(_onMoveToCurrentLocation);
    on<UploadVehicleTrackingData>(_onUploadVehicleTrackingData);
    on<MapTick>(_onMapTick);

    // New events for streaming active vehicle data.
    on<StartActiveVehicleStream>(_onStartActiveVehicleStream);
    on<StopActiveVehicleStream>(_onStopActiveVehicleStream);
    on<ActiveVehicleLocationsUpdated>(_onActiveVehicleLocationsUpdated);

    _locationSubscription = locationRepository
        .trackLocationUpdates()
        .listen((latLng) => add(UpdateCameraPosition(latLng)));

    _tickerSubscription = ticker.tick().listen((tickCount) {
      add(MapTick(tickCount));
    });
  }

  Future<void> _onMapLoad(MapLoad event, Emitter<MapState> emit) async {
    emit(MapLoading());
    try {
      final LatLng? position = await locationRepository.getCurrentLocation();
      if (position == null) {
        emit(const MapError('Location permission denied or unavailable.'));
      } else {
        emit(MapLoaded(
          position: position,
          routeTrace: [],
          activeVehicleLocations: [],
        ));
      }
    } catch (e) {
      emit(MapError('Failed to load map: ${e.toString()}'));
    }
  }

  void _onUpdateCameraPosition(UpdateCameraPosition event, Emitter<MapState> emit) {
    if (state is MapLoaded) {
      final currentState = state as MapLoaded;
      emit(currentState.copyWith(position: event.position));
    }
  }

  Future<void> _onMoveToCurrentLocation(MoveToCurrentLocation event, Emitter<MapState> emit) async {
    if (state is MapLoaded) {
      try {
        final LatLng? position = await locationRepository.getCurrentLocation();
        if (position != null) {
          final currentState = state as MapLoaded;
          emit(currentState.copyWith(position: position));
        }
      } catch (e) {
        emit(MapError('Failed to fetch current location: ${e.toString()}'));
      }
    }
  }

  Future<void> _onUploadVehicleTrackingData(UploadVehicleTrackingData event, Emitter<MapState> emit) async {
    try {
      await vehicleTrackingRepository.uploadVehicleData(
        docId: event.docId,
        deviceId: event.deviceId,
        routeId: event.routeId,
        routeName: event.routeName,
        activeTime: event.activeTime,
        waitingTime: event.status == "waiting"
            ? DateTime.now().difference(_startedWaiting!).inSeconds
            : _accumulatedWaitTime,
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
        totalWaitTime: event.status == "waiting"
            ? DateTime.now().difference(_startedWaiting!).inSeconds
            : _accumulatedWaitTime,
        dateTime: event.dateTime,
        trafficLevel: event.trafficLevel,
        averageTrafficLevel: event.averageTrafficLevel,
        totalCommuteTime: event.totalCommuteTime,
      );
      print("Vehicle tracking data uploaded successfully!");
    } catch (e) {
      print("Error uploading vehicle tracking data: $e");
    }
  }

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
      // Do not update _timeOfDay after initial set.

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

      // Transition logic:
      // - If currently waiting, check if speed exceeds threshold to transition to active.
      // - Once active, remain active.
      if (_lastStatus == "waiting") {
        if (computedSpeedKmh > speedThresholdKmh) {
          newStatus = "active";
          _startedTraveling = now; // mark the transition time
          // Do not update waiting time further (freeze _accumulatedWaitTime).
        } else {
          newStatus = "waiting";
          // Update waiting time.
          _startedWaiting ??= now; // ensure _startedWaiting is set
        }
      } else if (_lastStatus == "active") {
        // Once active, always remain active.
        newStatus = "active";
      } else {
        // Fallback case.
        newStatus = "waiting";
        _startedWaiting ??= now;
      }

      // Compute waiting time.
      int computedWaitTime;
      if (newStatus == "waiting") {
        computedWaitTime = now.difference(_startedWaiting!).inSeconds;
        _accumulatedWaitTime = computedWaitTime;
      } else {
        // When active, keep the waiting time frozen.
        computedWaitTime = _accumulatedWaitTime;
      }

      _lastStatus = newStatus;
      _lastUploadedLocation = currentState.position;

      // Total commute time.
      final int totalCommuteTime = now.difference(_initialUploadTime!).inSeconds;

      // Trigger the upload event with the computed waiting time.
      add(UploadVehicleTrackingData(
        docId: _sessionDocId!,
        deviceId: deviceId,
        routeId: _routeId ?? 0,
        routeName: _routeName ?? "Unknown Route",
        activeTime: 0, // Update as needed.
        waitingTime: computedWaitTime,
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
        totalWaitTime: computedWaitTime,
        dateTime: _initialUploadTime!,
        trafficLevel: "Low",
        averageTrafficLevel: "Moderate",
        totalCommuteTime: totalCommuteTime,
      ));

      // Update the state with the latest active vehicle data.
      emit(currentState.copyWith(activeVehicleLocations: _latestActiveVehicles));
    }
  }

  Future<void> _onStartActiveVehicleStream(StartActiveVehicleStream event, Emitter<MapState> emit) async {
    await _activeVehicleSubscription?.cancel();
    _activeVehicleSubscription = activeVehicleStreamRepository
        .streamActiveVehicleLocations(event.routeName)
        .listen((vehicles) {
      _latestActiveVehicles = vehicles;
      // Let MapTick trigger state updates every 5 seconds.
    });
  }

  Future<void> _onStopActiveVehicleStream(StopActiveVehicleStream event, Emitter<MapState> emit) async {
    await _activeVehicleSubscription?.cancel();
    _activeVehicleSubscription = null;
    _latestActiveVehicles = [];
  }

  void _onActiveVehicleLocationsUpdated(ActiveVehicleLocationsUpdated event, Emitter<MapState> emit) {
    if (state is MapLoaded) {
      final currentState = state as MapLoaded;
      emit(currentState.copyWith(activeVehicleLocations: event.locations));
    }
  }

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
    _activeVehicleSubscription?.cancel();
    return super.close();
  }
}
