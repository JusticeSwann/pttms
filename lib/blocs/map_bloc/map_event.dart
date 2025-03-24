// lib/blocs/map_bloc/map_event.dart
part of 'map_bloc.dart';

sealed class MapEvent extends Equatable {
  const MapEvent();
  @override
  List<Object?> get props => [];
}

class MapLoad extends MapEvent {}

class UpdateCameraPosition extends MapEvent {
  final LatLng position;
  const UpdateCameraPosition(this.position);
  @override
  List<Object?> get props => [position];
}

class MoveToCurrentLocation extends MapEvent {}

class UploadVehicleTrackingData extends MapEvent {
  final String docId;
  final String deviceId;
  final int routeId;
  final String routeName;
  final int activeTime;
  final int waitingTime;
  final double speed;
  final String status;
  final LatLng lastLocation;
  final List<LatLng> routeTrace;
  final List<LatLng> stopsMade;
  final LatLng pickupPoint;
  final bool userOnRoute;
  final double gpsAccuracy;
  final double distanceTraveled;
  final bool weekendIndicator;
  final String weatherConditions;
  final String trafficConditions;
  final DateTime startedWaiting;
  final DateTime? startedTraveling;
  final DateTime? stoppedTraveling;
  final int totalCommuteTime;
  final int totalWaitTime;
  final DateTime dateTime;
  final String trafficLevel;
  final String averageTrafficLevel;

  const UploadVehicleTrackingData({
    required this.docId,
    required this.deviceId,
    required this.routeId,
    required this.routeName,
    required this.activeTime,
    required this.waitingTime,
    required this.speed,
    required this.status,
    required this.lastLocation,
    required this.routeTrace,
    required this.stopsMade,
    required this.pickupPoint,
    required this.userOnRoute,
    required this.gpsAccuracy,
    required this.distanceTraveled,
    required this.weekendIndicator,
    required this.weatherConditions,
    required this.trafficConditions,
    required this.startedWaiting,
    this.startedTraveling,
    this.stoppedTraveling,
    required this.totalCommuteTime,
    required this.totalWaitTime,
    required this.dateTime,
    required this.trafficLevel,
    required this.averageTrafficLevel,
  });

  @override
  List<Object?> get props => [
        docId,
        deviceId,
        routeId,
        routeName,
        activeTime,
        waitingTime,
        speed,
        status,
        lastLocation,
        routeTrace,
        stopsMade,
        pickupPoint,
        userOnRoute,
        gpsAccuracy,
        distanceTraveled,
        weekendIndicator,
        weatherConditions,
        trafficConditions,
        startedWaiting,
        startedTraveling,
        stoppedTraveling,
        totalCommuteTime,
        totalWaitTime,
        dateTime,
        trafficLevel,
        averageTrafficLevel,
      ];
}

class MapTick extends MapEvent {
  final int tickCount;
  const MapTick(this.tickCount);
  @override
  List<Object?> get props => [tickCount];
}

class StartActiveVehicleStream extends MapEvent {
  final String routeName;
  const StartActiveVehicleStream(this.routeName);
  @override
  List<Object?> get props => [routeName];
}

class StopActiveVehicleStream extends MapEvent {}

class ActiveVehicleLocationsUpdated extends MapEvent {
  final List<VehicleLocationData> locations;
  const ActiveVehicleLocationsUpdated(this.locations);
  @override
  List<Object?> get props => [locations];
}
