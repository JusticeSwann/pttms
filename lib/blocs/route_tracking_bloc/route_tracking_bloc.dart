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
    _startDebugTimer();
  }

  void _startDebugTimer() {
    _printTimer?.cancel();
    _printTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      print("DEBUG: Current RouteTrackingState -> $state");
    });
    print("Debug timer started!");
  }

  Future<void> _onUpdateRouteTracking(UpdateRouteTracking event, Emitter<RouteTrackingState> emit) async {
    emit(RouteTrackingLoading());
    try {
      // 1) Determine the nearby route name (if any)
      final String? routeName = await routesRepository.getNearbyRoute(event.position);
      // 2) Check if the current position is near the route
      final bool isOnRoute = await routesRepository.isPositionNearRouteAsync(event.position);
      // 3) Get the polyline for the detected route
      List<LatLng> routePolyline = routesRepository.getDetectedRoutePolyline();
      // If the user is not on-route, clear the polyline and update flag accordingly.
      bool showPolyline = isOnRoute;
      if (!isOnRoute) {
        routePolyline = [];
      }
      emit(RouteTrackingLoaded(
        routeName: routeName,
        isOnRoute: isOnRoute,
        routePolyline: routePolyline,
        showPolyline: showPolyline,
      ));
    } catch (e) {
      emit(RouteTrackingError('Failed to load route tracking: ${e.toString()}'));
      print("Error in route tracking: $e");
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
    print("Debug timer stopped.");
    return super.close();
  }
}
