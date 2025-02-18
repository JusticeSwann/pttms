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

class UploadVehicleTrackingData extends MapEvent {
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

  const UploadVehicleTrackingData({
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
  });

  @override
  List<Object> get props => [
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
        pickupPoint
      ];
}
