import 'dart:async';
import 'dart:math';
import 'package:bloc/bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'movement_event.dart';
import 'movement_state.dart';
import 'package:pttms/services/traffic_service.dart';
import 'package:pttms/data/services/route_detection_service.dart';

/// This bloc manages transitions between waiting, active, complete, and false positive states.
/// It now integrates traffic data updates and enhanced off-route detection.
class MovementBloc extends Bloc<MovementEvent, MovementState> {
  Timer? _waitingTimer;
  Timer? _activeTimer;
  Timer? _trafficTimer;
  Timer? _offRouteTimer; // Timer for off-route detection

  final TrafficService trafficService;
  final RouteDetectionService routeDetectionService;
  final Duration offRouteDuration; // Configurable off-route duration

  // To accumulate traffic data over the journey.
  final List<String> _trafficLevels = [];
  String _currentTrafficLevel = 'low';

  // Optional: store origin (e.g., route start) and current location.
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
    // Optionally set _origin based on event data.
    _origin ??= const LatLng(0, 0); // Replace with actual value if available.
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
      // --- Enhanced Off-Route Detection ---
      if (!event.onRoute) {
        final dualDistances = await routeDetectionService.getDualDistances(
          event.newLocation,
          trafficLevel: _currentTrafficLevel,
        );
        // If either computed distance exceeds 30 meters, start the off-route timer.
        if (dualDistances['rawDistance']! > 30 || dualDistances['trafficDistance']! > 30) {
          _offRouteTimer ??= Timer(offRouteDuration, () {
            add(MarkFalsePositive("Off-route for ${offRouteDuration.inMinutes} minutes"));
          });
        } else {
          // User is close enough; cancel any off-route timer.
          _offRouteTimer?.cancel();
          _offRouteTimer = null;
        }
      } else {
        _offRouteTimer?.cancel();
        _offRouteTimer = null;
      }
      // ---------------------------------------

      if (event.speed < 5.0 && event.isWalking) {
        add(MarkComplete(DateTime.now()));
        return;
      }

      final newActiveTime = currentState.activeTime + 5;
      final routeTrace = List<Map<String, double>>.from(currentState.routeTrace);
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
      final totalCommuteTime = currentState.activeTime;
      String averageTrafficLevel = _computeAverageTrafficLevel();
      emit(
        MovementComplete(
          stoppedTraveling: event.stoppedTraveling,
          totalCommuteTime: totalCommuteTime,
          finalRouteTrace: currentState.routeTrace,
          stopsMade: currentState.stopsMade,
        ),
      );
      // Trigger final upload with _currentTrafficLevel and averageTrafficLevel.
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

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371000;
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    final a = (dLat / 2) * (dLat / 2) +
        (dLon / 2) * (dLon / 2) *
            (cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)));
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
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
    _offRouteTimer?.cancel();
    return super.close();
  }
}
