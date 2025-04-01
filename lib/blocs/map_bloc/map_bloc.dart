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
import 'package:pttms/services/traffic_service.dart';

part 'map_event.dart';
part 'map_state.dart';

// Helper to format time as "HH:MM AM/PM"
String _formatTime(DateTime time) {
  final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final minute = time.minute.toString().padLeft(2, '0');
  final period = time.hour >= 12 ? "PM" : "AM";
  return "$hour:$minute $period";
}

class MapBloc extends Bloc<MapEvent, MapState> {
  final String deviceId;
  final LocationRepository locationRepository;
  final VehicleTrackingRepository vehicleTrackingRepository;
  final RouteDetectionService routeDetectionService;
  final Ticker ticker;
  final ActiveVehicleStreamRepository activeVehicleStreamRepository;
  final TrafficService trafficService; // For ETA

  StreamSubscription<LatLng>? _locationSubscription;
  StreamSubscription<int>? _tickerSubscription;
  StreamSubscription<List<VehicleLocationData>>? _activeVehicleSubscription;

  // For route trace & upload logic.
  LatLng? _lastUploadedLocation;
  String _lastStatus = "waiting"; // always lowercase
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

  static const double speedThresholdKmh = 15.0;
  static const double traceDistanceThreshold = 5.0;

  String? _sessionDocId;

  // For streaming active vehicle data.
  List<VehicleLocationData> _latestActiveVehicles = [];

  // Field to accumulate local waiting time in seconds.
  int _accumulatedWaitTime = 0;
  // Freeze waiting time when status turns active.
  int? _frozenWaitTime;

  MapBloc({
    required this.deviceId,
    required this.locationRepository,
    required this.vehicleTrackingRepository,
    required this.routeDetectionService,
    required this.ticker,
    required this.activeVehicleStreamRepository,
    required this.trafficService,
  }) : super(MapInitial()) {
    on<MapLoad>(_onMapLoad);
    on<UpdateCameraPosition>(_onUpdateCameraPosition);
    on<MoveToCurrentLocation>(_onMoveToCurrentLocation);
    on<UploadVehicleTrackingData>(_onUploadVehicleTrackingData);
    on<MapTick>(_onMapTick);
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
          averageWaitTime: 0,
          lastUpdated: "",
          eta: "-",
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
      final now = DateTime.now();
      await vehicleTrackingRepository.uploadVehicleData(
        docId: event.docId,
        deviceId: event.deviceId,
        routeId: event.routeId,
        routeName: event.routeName,
        activeTime: event.activeTime,
        // UPLOAD uses the local computed waiting time (computedWaitTime)
        waitingTime: event.status == "waiting"
            ? now.difference(_startedWaiting!).inSeconds
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
        weekendIndicator: now.weekday >= 6,
        weatherConditions: event.weatherConditions,
        trafficConditions: event.trafficConditions,
        startedWaiting: event.startedWaiting,
        startedTraveling: event.startedTraveling,
        stoppedTraveling: event.stoppedTraveling,
        totalWaitTime: event.status == "waiting"
            ? now.difference(_startedWaiting!).inSeconds
            : _accumulatedWaitTime,
        dateTime: event.dateTime,
        trafficLevel: event.trafficLevel,
        averageTrafficLevel: event.averageTrafficLevel,
        totalCommuteTime: event.totalCommuteTime,
      );
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
      // _timeOfDay remains unchanged after initial set.

      // Generate session doc ID if needed.
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

      // Transition logic: if waiting and speed exceeds threshold, switch to active.
      if (_lastStatus == "waiting") {
        if (computedSpeedKmh > speedThresholdKmh) {
          newStatus = "active";
          _startedTraveling = now;
          // Freeze wait time when transitioning to active.
          _frozenWaitTime = now.difference(_startedWaiting!).inSeconds;
        } else {
          newStatus = "waiting";
        }
      } else if (_lastStatus == "active") {
        newStatus = "active";
      } else {
        newStatus = "waiting";
        _startedWaiting ??= now;
      }

      // Compute local waiting time.
      int computedWaitTime;
      if (newStatus == "waiting") {
        computedWaitTime = now.difference(_startedWaiting!).inSeconds;
        _accumulatedWaitTime = computedWaitTime;
      } else {
        // When active, use the frozen wait time.
        computedWaitTime = _frozenWaitTime ?? _accumulatedWaitTime;
      }

      _lastStatus = newStatus;
      _lastUploadedLocation = currentState.position;
      final int totalCommuteTime = now.difference(_initialUploadTime!).inSeconds;

      // Compute average wait time from active vehicles (for display in route page).
      int computedAverageWaitTime = 0;
      if (_latestActiveVehicles.isNotEmpty) {
        computedAverageWaitTime = _latestActiveVehicles
                .map((v) => v.waitTime)
                .reduce((a, b) => a + b) ~/
            _latestActiveVehicles.length;
      } else {
        computedAverageWaitTime = 0;
      }

      // Format last updated time.
      final String lastUpdatedStr = _formatTime(now);

      // --- ETA Calculation ---
      String computedEta = "-";
      if (_latestActiveVehicles.isNotEmpty &&
          newStatus != "active" &&
          _routeTrace.isNotEmpty &&
          _lastUploadedLocation != null) {
        double minDistance = double.infinity;
        LatLng? nearestPoint;
        for (final point in _routeTrace) {
          final dist = calculateDistance(currentState.position, point);
          if (dist < minDistance) {
            minDistance = dist;
            nearestPoint = point;
          }
        }
        if (nearestPoint != null && minDistance < 50) {
          try {
            final departureTime = (now.millisecondsSinceEpoch / 1000).round();
            // Use the first active vehicle's lastLocation as the origin.
            final origin = _latestActiveVehicles.first.lastLocation;
            final trafficData = await trafficService.fetchTrafficData(
              origin: origin,
              destination: nearestPoint,
              departureTime: departureTime,
            );
            final trafficDurationSec = trafficData['traffic_duration'] as int;
            final travelTimeMin = trafficDurationSec < 60
                ? 1
                : (trafficDurationSec / 60).round();
            computedEta = "${travelTimeMin} min";
          } catch (e) {
            computedEta = "-";
          }
        } else {
          computedEta = "-";
        }
      } else {
        computedEta = "-";
      }
      // --- End ETA Calculation ---

      // Trigger the upload event using the local computed wait time.
      add(UploadVehicleTrackingData(
        docId: _sessionDocId!,
        deviceId: deviceId,
        routeId: _routeId ?? 0,
        routeName: _routeName ?? "Unknown Route",
        activeTime: 0,
        waitingTime: computedWaitTime, // Use the local waiting time for upload.
        speed: computedSpeedKmh,
        status: newStatus,
        lastLocation: currentState.position,
        routeTrace: List<LatLng>.from(_routeTrace),
        stopsMade: List<LatLng>.from(_stopsMade),
        pickupPoint: currentState.position,
        userOnRoute: true,
        gpsAccuracy: 5.0,
        distanceTraveled: 0.0,
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

      // Emit updated state with average wait time from stream, last updated time, and ETA.
      emit(currentState.copyWith(
        activeVehicleLocations: _latestActiveVehicles,
        averageWaitTime: computedAverageWaitTime,
        lastUpdated: lastUpdatedStr,
        eta: computedEta,
      ));
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



  void _onActiveVehicleLocationsUpdated(ActiveVehicleLocationsUpdated event, Emitter<MapState> emit) {
    if (state is MapLoaded) {
      final currentState = state as MapLoaded;
      _latestActiveVehicles = event.locations;
      emit(currentState.copyWith(activeVehicleLocations: event.locations));
    }
  }

  @override
  Future<void> close() {
    _locationSubscription?.cancel();
    _tickerSubscription?.cancel();
    _activeVehicleSubscription?.cancel();
    return super.close();
  }
}
