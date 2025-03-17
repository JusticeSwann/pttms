part of 'map_bloc.dart';

sealed class MapEvent extends Equatable {
  const MapEvent();

  @override
  List<Object> get props => [];
}

class MapLoad extends MapEvent {}

class UpdateCameraPosition extends MapEvent {
  final LatLng position;

  const UpdateCameraPosition(this.position);

  @override
  List<Object> get props => [position];
}

class MoveToCurrentLocation extends MapEvent {}

/// New event for uploading vehicle tracking data
class UploadVehicleTrackingData extends MapEvent {
  /// The Firestore document ID (generated as deviceId_timestamp).
  final String docId;

  /// The actual device name/ID that is stored in the data payload.
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
  final DateTime startedTraveling;
  final DateTime stoppedTraveling;
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
    required this.startedTraveling,
    required this.stoppedTraveling,
    required this.totalCommuteTime,
    required this.totalWaitTime,
    required this.dateTime,
    required this.trafficLevel,
    required this.averageTrafficLevel,
  });

  @override
  List<Object> get props => [
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
