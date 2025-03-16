// lib/blocs/map_bloc/map_bloc.dart
import 'dart:async';
import 'dart:math';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location_repository/location_repository.dart';
import 'package:pttms/data/repository/vehicle_tracking_repository.dart';

part 'map_event.dart';
part 'map_state.dart';

class MapBloc extends Bloc<MapEvent, MapState> {
  final LocationRepository locationRepository;
  final VehicleTrackingRepository vehicleTrackingRepository;
  StreamSubscription<LatLng>? _locationSubscription;
  Timer? _uploadTimer;
  int _lastUploadSecond = -1;
  String? _sessionId; // Session identifier (remains constant during a session)
  LatLng? _lastUploadedLocation; // To calculate movement between uploads

  MapBloc({
    required this.locationRepository,
    required this.vehicleTrackingRepository,
  }) : super(MapInitial()) {
    on<MapLoad>(_onMapLoad);
    on<UpdateCameraPosition>(_onUpdateCameraPosition);
    on<MoveToCurrentLocation>(_onMoveToCurrentLocation);
    on<UploadVehicleTrackingData>(_onUploadVehicleTrackingData);

    // Listen to continuous location updates.
    _locationSubscription =
        locationRepository.trackLocationUpdates().listen((latLng) {
      add(UpdateCameraPosition(latLng));
    });

    // Set up a periodic timer that checks every second.
    // If the current second is divisible by 5 and wasn't already triggered in that second, trigger an upload.
    _uploadTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final int currentSecond = DateTime.now().second;
      if (currentSecond % 5 == 0 && currentSecond != _lastUploadSecond) {
        _lastUploadSecond = currentSecond;
        if (state is MapLoaded) {
          final currentState = state as MapLoaded;
          // If no session has been started, generate one.
          _sessionId ??= "session_${DateTime.now().millisecondsSinceEpoch}";

          // Determine status based on movement:
          String status;
          if (_lastUploadedLocation == null) {
            status = "Active"; // First upload—assume active.
          } else {
            final distance = _calculateDistance(
              _lastUploadedLocation!.latitude,
              _lastUploadedLocation!.longitude,
              currentState.position.latitude,
              currentState.position.longitude,
            );
            // If moved less than 5 meters, consider it "Waiting"; otherwise, "Active".
            status = distance < 5.0 ? "Waiting" : "Active";
          }
          // Update the last uploaded location.
          _lastUploadedLocation = currentState.position;
          // Dispatch the upload event.
          add(UploadVehicleTrackingData(
            deviceId: _sessionId!, // Use the session ID for the document.
            routeId: 1,
            routeName: "Auto Update Route",
            activeTime: 0,
            waitingTime: 0,
            speed: 0.0,
            status: status,
            lastLocation: currentState.position,
            routeTrace: [currentState.position],
            stopsMade: [],
            pickupPoint: currentState.position,
            userOnRoute: true,
            gpsAccuracy: 5.0,
            distanceTraveled: 0.0,
            weekendIndicator: DateTime.now().weekday >= 6,
            weatherConditions: "Clear",
            trafficConditions: "Moderate",
            startedWaiting: DateTime.now(),
            startedTraveling: DateTime.now(),
            stoppedTraveling: DateTime.now(),
            totalCommuteTime: 0,
            totalWaitTime: 0,
            dateTime: DateTime.now(),
            trafficLevel: "Low",
            averageTrafficLevel: "Moderate",
          ));
        }
      }
    });
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

  void _onUpdateCameraPosition(
      UpdateCameraPosition event, Emitter<MapState> emit) {
    if (state is MapLoaded) {
      emit(MapLoaded(position: event.position));
    }
  }

  Future<void> _onMoveToCurrentLocation(
      MoveToCurrentLocation event, Emitter<MapState> emit) async {
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

  Future<void> _onUploadVehicleTrackingData(
      UploadVehicleTrackingData event, Emitter<MapState> emit) async {
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

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
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

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  @override
  Future<void> close() {
    _locationSubscription?.cancel();
    _uploadTimer?.cancel();
    return super.close();
  }
}
