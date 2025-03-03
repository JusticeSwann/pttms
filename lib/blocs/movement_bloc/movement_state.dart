import 'package:equatable/equatable.dart';

/// Represents the different states of user movement and tracking.

abstract class MovementState extends Equatable {
  const MovementState();

  @override
  List<Object?> get props => [];
}

class MovementInitial extends MovementState {
  const MovementInitial();
}

/// User is near a route but not moving significantly.
class MovementWaiting extends MovementState {
  final DateTime startedWaiting;
  final int waitingTime; // in seconds

  const MovementWaiting({
    required this.startedWaiting,
    required this.waitingTime,
  });

  @override
  List<Object?> get props => [startedWaiting, waitingTime];

  /// Creates a new MovementWaiting with updated fields.
  MovementWaiting copyWith({
    DateTime? startedWaiting,
    int? waitingTime,
  }) {
    return MovementWaiting(
      startedWaiting: startedWaiting ?? this.startedWaiting,
      waitingTime: waitingTime ?? this.waitingTime,
    );
  }
}


/// User is actively traveling on a route.
class MovementActive extends MovementState {
  final DateTime startedTraveling;
  final int activeTime; // in seconds
  final List<Map<String, double>> routeTrace; // or List<LatLng> if you prefer
  final List<Map<String, double>> stopsMade;

  const MovementActive({
    required this.startedTraveling,
    required this.activeTime,
    required this.routeTrace,
    required this.stopsMade,
  });

  @override
  List<Object?> get props => [
        startedTraveling,
        activeTime,
        routeTrace,
        stopsMade,
      ];
}

/// The journey has been completed successfully.
class MovementComplete extends MovementState {
  final DateTime stoppedTraveling;
  final int totalCommuteTime; // total time from start to end
  final List<Map<String, double>> finalRouteTrace; // possibly simplified
  final List<Map<String, double>> stopsMade;

  const MovementComplete({
    required this.stoppedTraveling,
    required this.totalCommuteTime,
    required this.finalRouteTrace,
    required this.stopsMade,
  });

  @override
  List<Object?> get props => [
        stoppedTraveling,
        totalCommuteTime,
        finalRouteTrace,
        stopsMade,
      ];
}

/// The user has gone off-route or manually stopped tracking.
class MovementFalsePositive extends MovementState {
  final String reason; // e.g., "off-route", "stop button pressed", etc.

  const MovementFalsePositive({required this.reason});

  @override
  List<Object?> get props => [reason];
}
