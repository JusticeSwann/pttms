import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Defines all events that can be dispatched to MovementBloc.

abstract class MovementEvent extends Equatable {
  const MovementEvent();

  @override
  List<Object?> get props => [];
}

/// Initialize waiting state when user is within 10m of a route.
class InitializeWaiting extends MovementEvent {
  final String deviceId;
  final int routeId;
  final String routeName;
  final DateTime startedWaiting;

  const InitializeWaiting({
    required this.deviceId,
    required this.routeId,
    required this.routeName,
    required this.startedWaiting,
  });

  @override
  List<Object?> get props => [deviceId, routeId, routeName, startedWaiting];
}

/// Dispatched every 5 seconds with a new location update.
class UpdateLocation extends MovementEvent {
  final LatLng newLocation;
  final double speed; // computed externally or in-bloc
  final bool onRoute; // if the user is still on route
  final bool isWalking; // for possible detection of "complete"

  const UpdateLocation({
    required this.newLocation,
    required this.speed,
    required this.onRoute,
    required this.isWalking,
  });

  @override
  List<Object?> get props => [newLocation, speed, onRoute, isWalking];
}

/// Transition from waiting to active.
class TransitionToActive extends MovementEvent {
  final DateTime startedTraveling;

  const TransitionToActive(this.startedTraveling);

  @override
  List<Object?> get props => [startedTraveling];
}

/// Mark the journey as complete.
class MarkComplete extends MovementEvent {
  final DateTime stoppedTraveling;

  const MarkComplete(this.stoppedTraveling);

  @override
  List<Object?> get props => [stoppedTraveling];
}

/// Mark as false positive (off-route or user-initiated stop).
class MarkFalsePositive extends MovementEvent {
  final String reason;

  const MarkFalsePositive(this.reason);

  @override
  List<Object?> get props => [reason];
}

/// Immediately stop tracking (e.g., from notification button).
class StopTrackingImmediately extends MovementEvent {
  const StopTrackingImmediately();
}

/// Dispatch when you want to update traffic data. 
/// The MovementBloc can fetch traffic info for [origin] to [destination].
class UpdateTrafficData extends MovementEvent {
  final LatLng origin;
  final LatLng destination;

  const UpdateTrafficData({
    required this.origin,
    required this.destination,
  });

  @override
  List<Object?> get props => [origin, destination];
}
