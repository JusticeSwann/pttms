import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'movement_event.dart';
import 'movement_state.dart';

/// This bloc manages transitions between waiting, active, complete, and false positive states.

class MovementBloc extends Bloc<MovementEvent, MovementState> {
  // For demonstration, these are timers or counters you might need.
  Timer? _waitingTimer;
  Timer? _activeTimer;

  // You might also keep references to location or repository services if needed.
  // final LocationRepository locationRepo;
  // final VehicleTrackingRepository trackingRepo;

  MovementBloc() : super(const MovementInitial()) {
    on<InitializeWaiting>(_onInitializeWaiting);
    on<UpdateLocation>(_onUpdateLocation);
    on<TransitionToActive>(_onTransitionToActive);
    on<MarkComplete>(_onMarkComplete);
    on<MarkFalsePositive>(_onMarkFalsePositive);
    on<StopTrackingImmediately>(_onStopTrackingImmediately);
  }

  void _onInitializeWaiting(
    InitializeWaiting event,
    Emitter<MovementState> emit,
  ) {
    emit(
      MovementWaiting(
        startedWaiting: event.startedWaiting,
        waitingTime: 0,
      ),
    );
  }

  void _onUpdateLocation(
    UpdateLocation event,
    Emitter<MovementState> emit,
  ) {
    final currentState = state;

    if (currentState is MovementWaiting) {
      // Check if speed exceeds threshold => Transition to Active
      // Otherwise, increment waitingTime
      if (event.speed > 15.0 /* or dynamic threshold */) {
        add(TransitionToActive(DateTime.now()));
      } else {
        // Increment waiting time
        final updatedWaitingTime = currentState.waitingTime + 5; // 5 seconds
        emit(currentState.copyWith(waitingTime: updatedWaitingTime));
      }
    } else if (currentState is MovementActive) {
      // Possibly check if user is off-route => MarkFalsePositive
      if (!event.onRoute) {
        // Start a timer or handle logic for 10 min off-route
      }

      // If speed < 5.0 and isWalking => MarkComplete
      if (event.speed < 5.0 && event.isWalking) {
        add(MarkComplete(DateTime.now()));
        return;
      }

      // Otherwise, increment activeTime
      final newActiveTime = currentState.activeTime + 5;
      // Possibly append newLocation to routeTrace or record a stop
      final routeTrace = List<Map<String, double>>.from(currentState.routeTrace);

      // Check distance from last point, etc.
      // For simplicity, let's assume we always append for now:
      routeTrace.add({
        'lat': event.newLocation.latitude,
        'lng': event.newLocation.longitude,
      });

      emit(
        MovementActive(
          startedTraveling: currentState.startedTraveling,
          activeTime: newActiveTime,
          routeTrace: routeTrace,
          stopsMade: currentState.stopsMade,
        ),
      );
    }
  }

  void _onTransitionToActive(
    TransitionToActive event,
    Emitter<MovementState> emit,
  ) {
    // If we are waiting, we transition to active
    final currentState = state;
    if (currentState is MovementWaiting) {
      emit(
        MovementActive(
          startedTraveling: event.startedTraveling,
          activeTime: 0,
          routeTrace: [],
          stopsMade: [],
        ),
      );
    }
  }

  void _onMarkComplete(
    MarkComplete event,
    Emitter<MovementState> emit,
  ) {
    final currentState = state;
    if (currentState is MovementActive) {
      final totalCommuteTime = currentState.activeTime; // + waitingTime if needed
      // Optionally do route trace simplification here
      emit(
        MovementComplete(
          stoppedTraveling: event.stoppedTraveling,
          totalCommuteTime: totalCommuteTime,
          finalRouteTrace: currentState.routeTrace,
          stopsMade: currentState.stopsMade,
        ),
      );
      // Could trigger final upload here
    }
  }

  void _onMarkFalsePositive(
    MarkFalsePositive event,
    Emitter<MovementState> emit,
  ) {
    emit(MovementFalsePositive(reason: event.reason));
    // Possibly trigger final upload with status = "false positive"
  }

  void _onStopTrackingImmediately(
    StopTrackingImmediately event,
    Emitter<MovementState> emit,
  ) {
    // Immediately mark false positive with reason "User stopped"
    add(MarkFalsePositive("User stopped via notification"));
  }

  @override
  Future<void> close() {
    _waitingTimer?.cancel();
    _activeTimer?.cancel();
    return super.close();
  }
}
