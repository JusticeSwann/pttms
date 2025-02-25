import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pttms/data/repository/routes_repository.dart';

part 'route_tracking_event.dart';
part 'route_tracking_state.dart';

class RouteTrackingBloc extends Bloc<RouteTrackingEvent, RouteTrackingState> {
  final RoutesRepository routesRepository;
  Timer? _printTimer;

  RouteTrackingBloc({required this.routesRepository}) : super(RouteTrackingBlocInitial()) {
    on<UpdateRouteTracking>(_onUpdateRouteTracking);
    on<ToggleRoutePolyline>(_onToggleRoutePolyline);

    // Start debug timer in a separate function to ensure it runs
    _startDebugTimer();
  }

  /// Start a timer that prints the current state every 5 seconds
  void _startDebugTimer() {
    _printTimer?.cancel(); // Ensure no duplicate timers
    _printTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      print("🔄 DEBUG: Current RouteTrackingState -> $state");
    });
    print("⏳ Debug timer started! It will print route tracking state every 5 seconds.");
  }

  Future<void> _onUpdateRouteTracking(UpdateRouteTracking event, Emitter<RouteTrackingState> emit) async {
    emit(RouteTrackingLoading());
    try {
      // 1) Determine the name of the closest route (within 300m)
      final String? routeName = await routesRepository.getNearbyRoute(event.position);
      print("🛣️ Detected nearby route: $routeName");

      // 2) Check if user is near a route (within 50m threshold by default)
      final bool isOnRoute = await routesRepository.isPositionNearRouteAsync(event.position);
      print("📍 isOnRoute: $isOnRoute");

      // 3) Retrieve the polyline for the closest route (within 300m)
      final List<LatLng> routePolyline = routesRepository.getDetectedRoutePolyline();
      //print("📏 Polyline points: ${routePolyline.length} points");

      // Emit a new state with a fresh list instance for the polyline.
      emit(RouteTrackingLoaded(
        routeName: routeName,
        isOnRoute: isOnRoute,
        routePolyline: List.from(routePolyline),
        showPolyline: true,
      ));
    } catch (e) {
      emit(RouteTrackingError('Failed to load route tracking: ${e.toString()}'));
      print("❌ Error in route tracking: $e");
    }
  }

  void _onToggleRoutePolyline(ToggleRoutePolyline event, Emitter<RouteTrackingState> emit) {
    if (state is RouteTrackingLoaded) {
      final currentState = state as RouteTrackingLoaded;
      emit(RouteTrackingLoaded(
        routeName: currentState.routeName,
        isOnRoute: currentState.isOnRoute,
        routePolyline: List.from(currentState.routePolyline),
        showPolyline: !currentState.showPolyline,
      ));
    }
  }

  @override
  Future<void> close() {
    _printTimer?.cancel();
    print("⏹️ Debug timer stopped.");
    return super.close();
  }
}
