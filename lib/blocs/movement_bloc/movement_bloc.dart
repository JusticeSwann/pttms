import 'dart:async';
import 'dart:math';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'movement_event.dart';
import 'movement_state.dart';
import 'package:pttms/services/traffic_service.dart'; // Import your TrafficService

/// This bloc manages transitions between waiting, active, complete, and false positive states.
/// It now also integrates traffic data updates.
class MovementBloc extends Bloc<MovementEvent, MovementState> {
  Timer? _waitingTimer;
  Timer? _activeTimer;
  Timer? _trafficTimer;
  
  // Injected TrafficService dependency.
  final TrafficService trafficService;

  // To accumulate traffic data over the journey.
  final List<String> _trafficLevels = [];
  String _currentTrafficLevel = 'low'; // Default traffic level

  // Optional: store origin (e.g., route start) and current location.
  LatLng? _origin;
  LatLng? _currentLocation;

  MovementBloc({required this.trafficService}) : super(const MovementInitial()) {
    on<InitializeWaiting>(_onInitializeWaiting);
    on<UpdateLocation>(_onUpdateLocation);
    on<TransitionToActive>(_onTransitionToActive);
    on<MarkComplete>(_onMarkComplete);
    on<MarkFalsePositive>(_onMarkFalsePositive);
    on<StopTrackingImmediately>(_onStopTrackingImmediately);
    on<UpdateTrafficData>(_onUpdateTrafficData);
  }

  void _onInitializeWaiting(
    InitializeWaiting event,
    Emitter<MovementState> emit,
  ) {
    // Optionally, set _origin based on event data if available.
    // For example, you might pass the route's starting point in the event.
    _origin ??= event.startedWaiting != null ? const LatLng(0, 0) : null; // Replace with actual value.
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
    // Always update current location.
    _currentLocation = event.newLocation;

    final currentState = state;

    if (currentState is MovementWaiting) {
      // Check if speed exceeds threshold => Transition to Active.
      // (You can adjust threshold based on _currentTrafficLevel if desired.)
      if (event.speed > 15.0 /* default or dynamic based on _currentTrafficLevel */) {
        add(TransitionToActive(DateTime.now()));
      } else {
        // Increment waiting time by 5 seconds.
        final updatedWaitingTime = currentState.waitingTime + 5;
        emit(currentState.copyWith(waitingTime: updatedWaitingTime));
      }
    } else if (currentState is MovementActive) {
      // Off-route detection logic can be inserted here.
      if (!event.onRoute) {
        // Start or check a timer for 10 min off-route condition (not fully implemented here).
      }
      // If speed is low and user is walking => MarkComplete.
      if (event.speed < 5.0 && event.isWalking) {
        add(MarkComplete(DateTime.now()));
        return;
      }
      // Otherwise, increment activeTime.
      final newActiveTime = currentState.activeTime + 5;
      final routeTrace = List<Map<String, double>>.from(currentState.routeTrace);

      // Append new location if moved at least 5 meters from the last point.
      if (routeTrace.isEmpty) {
        routeTrace.add({
          'lat': event.newLocation.latitude,
          'lng': event.newLocation.longitude,
        });
      } else {
        final lastPoint = routeTrace.last;
        final distance = _calculateDistance(
          lastPoint['lat']!,
          lastPoint['lng']!,
          event.newLocation.latitude,
          event.newLocation.longitude,
        );
        if (distance > 5.0) {
          routeTrace.add({
            'lat': event.newLocation.latitude,
            'lng': event.newLocation.longitude,
          });
        } else {
          // If the location is the same, record a stop instead (logic for stops can be added here).
        }
      }

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
    final currentState = state;
    if (currentState is MovementWaiting) {
      // When transitioning, start a traffic update timer.
      _trafficTimer?.cancel();
      _trafficTimer = Timer.periodic(const Duration(minutes: 10), (timer) {
        if (_origin != null && _currentLocation != null) {
          add(UpdateTrafficData(origin: _origin!, destination: _currentLocation!));
        }
      });
      // Immediately trigger a traffic update if possible.
      if (_origin != null && _currentLocation != null) {
        add(UpdateTrafficData(origin: _origin!, destination: _currentLocation!));
      }
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

  Future<void> _onUpdateTrafficData(
    UpdateTrafficData event,
    Emitter<MovementState> emit,
  ) async {
    final departureTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    try {
      final result = await trafficService.fetchTrafficData(
        origin: event.origin,
        destination: event.destination,
        departureTime: departureTime,
      );
      final newTrafficLevel = trafficService.determineTrafficLevel(
        rawDuration: result['raw_duration'],
        trafficDuration: result['traffic_duration'],
      );
      _currentTrafficLevel = newTrafficLevel;
      _trafficLevels.add(newTrafficLevel);
      print("Updated traffic level: $newTrafficLevel");
      // Optionally, update state with current traffic info.
    } catch (e) {
      print("Error updating traffic data: $e");
    }
  }

  void _onMarkComplete(
    MarkComplete event,
    Emitter<MovementState> emit,
  ) {
    final currentState = state;
    if (currentState is MovementActive) {
      final totalCommuteTime = currentState.activeTime; // + waitingTime if needed.
      // Compute average traffic level.
      String averageTrafficLevel = _computeAverageTrafficLevel();
      emit(
        MovementComplete(
          stoppedTraveling: event.stoppedTraveling,
          totalCommuteTime: totalCommuteTime,
          finalRouteTrace: currentState.routeTrace,
          stopsMade: currentState.stopsMade,
        ),
      );
      // Trigger final upload with current traffic level and averageTrafficLevel as part of the payload.
    }
  }

  void _onMarkFalsePositive(
    MarkFalsePositive event,
    Emitter<MovementState> emit,
  ) {
    emit(MovementFalsePositive(reason: event.reason));
  }

  void _onStopTrackingImmediately(
    StopTrackingImmediately event,
    Emitter<MovementState> emit,
  ) {
    add(MarkFalsePositive("User stopped via notification"));
  }

  // Helper: Haversine distance calculation (in meters).
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371000; // in meters
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    final a = (dLat / 2) * (dLat / 2) +
        (dLon / 2) * (dLon / 2) *
            (cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)));
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * 3.1415926535897932 / 180;
  }

  String _computeAverageTrafficLevel() {
    if (_trafficLevels.isEmpty) return 'low';
    int total = 0;
    for (var level in _trafficLevels) {
      if (level == 'low') total += 1;
      else if (level == 'medium') total += 2;
      else if (level == 'high') total += 3;
    }
    double avg = total / _trafficLevels.length;
    if (avg < 1.5) return 'low';
    else if (avg < 2.5) return 'medium';
    else return 'high';
  }

  @override
  Future<void> close() {
    _waitingTimer?.cancel();
    _activeTimer?.cancel();
    _trafficTimer?.cancel();
    return super.close();
  }
}
