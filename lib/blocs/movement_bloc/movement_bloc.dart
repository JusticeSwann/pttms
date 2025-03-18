// lib/blocs/movement_bloc/movement_bloc.dart

import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'movement_event.dart';
import 'movement_state.dart';
import 'package:pttms/services/traffic_service.dart';
import 'package:pttms/data/services/route_detection_service.dart';
import 'package:pttms/utils/line_simplification.dart'; // Already imported
import 'package:pttms/utils/movement_helpers.dart'; // Import your new helper file

/// This bloc manages transitions between waiting, active, complete, and false positive states.
/// It integrates traffic data updates and enhanced off-route detection.
class MovementBloc extends Bloc<MovementEvent, MovementState> {
  Timer? _waitingTimer;
  Timer? _activeTimer;
  Timer? _trafficTimer;
  Timer? _offRouteTimer; // Timer for off-route detection

  final TrafficService trafficService;
  final RouteDetectionService routeDetectionService;
  final Duration offRouteDuration; // Configurable off-route duration

  // To accumulate traffic data.
  final List<String> _trafficLevels = [];
  String _currentTrafficLevel = 'low';

  // Optional: store origin (route start) and current location.
  LatLng? _origin;
  LatLng? _currentLocation;

  MovementBloc({
    required this.trafficService,
    required this.routeDetectionService,
    this.offRouteDuration = const Duration(minutes: 10),
  }) : super(const MovementInitial()) {
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
    // Set _origin; replace with actual route start if available.
    _origin ??= const LatLng(0, 0);
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
  ) async {
    _currentLocation = event.newLocation;
    final currentState = state;

    if (currentState is MovementWaiting) {
      if (event.speed > 15.0) {
        add(TransitionToActive(DateTime.now()));
      } else {
        final updatedWaitingTime = currentState.waitingTime + 5;
        emit(currentState.copyWith(waitingTime: updatedWaitingTime));
      }
    } else if (currentState is MovementActive) {
      // Enhanced Off-Route Detection:
      if (!event.onRoute) {
        final dualDistances = await routeDetectionService.getDualDistances(
          event.newLocation,
          trafficLevel: _currentTrafficLevel,
        );
        if (dualDistances['rawDistance']! > 30 ||
            dualDistances['trafficDistance']! > 30) {
          _offRouteTimer ??= Timer(offRouteDuration, () {
            add(MarkFalsePositive("Off-route for ${offRouteDuration.inMinutes} minutes"));
          });
        } else {
          _offRouteTimer?.cancel();
          _offRouteTimer = null;
        }
      } else {
        _offRouteTimer?.cancel();
        _offRouteTimer = null;
      }

      if (event.speed < 5.0 && event.isWalking) {
        add(MarkComplete(DateTime.now()));
        return;
      }

      final newActiveTime = currentState.activeTime + 5;
      // Update the route trace using the helper function.
      final updatedRouteTrace = updateMovementRouteTrace(
        List<Map<String, double>>.from(currentState.routeTrace),
        event.newLocation,
        5.0, // Threshold value in meters
      );

      emit(
        MovementActive(
          startedTraveling: currentState.startedTraveling,
          activeTime: newActiveTime,
          routeTrace: updatedRouteTrace,
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
      _trafficTimer?.cancel();
      _trafficTimer = Timer.periodic(const Duration(minutes: 10), (timer) {
        if (_origin != null && _currentLocation != null) {
          add(UpdateTrafficData(origin: _origin!, destination: _currentLocation!));
        }
      });
      if (_origin != null && _currentLocation != null) {
        add(UpdateTrafficData(origin: _origin!, destination: _currentLocation!));
      }
      emit(
        MovementActive(
          startedTraveling: event.startedTraveling,
          activeTime: 0,
          routeTrace: const [],
          stopsMade: const [],
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
      // Simplify the route trace before finalizing.
      List<LatLng> originalTrace = currentState.routeTrace
          .map((point) => LatLng(point['lat']!, point['lng']!))
          .toList();
      // Choose an epsilon tolerance in meters (adjust as needed).
      List<LatLng> simplifiedTrace = simplifyPolyline(originalTrace, 10.0);
      // Convert back to list of maps.
      List<Map<String, double>> simplifiedMap = simplifiedTrace
          .map((p) => {'lat': p.latitude, 'lng': p.longitude})
          .toList();

      final totalCommuteTime = currentState.activeTime;
      // Use the helper to compute the average traffic level.
      String averageTrafficLevel = computeAverageTrafficLevel(_trafficLevels);
      emit(
        MovementComplete(
          stoppedTraveling: event.stoppedTraveling,
          totalCommuteTime: totalCommuteTime,
          finalRouteTrace: simplifiedMap,
          stopsMade: currentState.stopsMade,
        ),
      );
      // Optionally trigger a final upload using _currentTrafficLevel and averageTrafficLevel.
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
    add(const MarkFalsePositive("User stopped via notification"));
  }

  @override
  Future<void> close() {
    _waitingTimer?.cancel();
    _activeTimer?.cancel();
    _trafficTimer?.cancel();
    _offRouteTimer?.cancel();
    return super.close();
  }
}
