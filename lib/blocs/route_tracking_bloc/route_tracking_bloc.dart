import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pttms/data/repository/routes_repository.dart';

part 'route_tracking_event.dart';
part 'route_tracking_state.dart';

class RouteTrackingBloc extends Bloc<RouteTrackingEvent, RouteTrackingState> {
  final RoutesRepository routesRepository;

  RouteTrackingBloc({required this.routesRepository}) : super(RouteTrackingBlocInitial()) {
    on<UpdateRouteTracking>(_onUpdateRouteTracking);
    on<ToggleRoutePolyline>(_onToggleRoutePolyline);
  }

  Future<void> _onUpdateRouteTracking(
      UpdateRouteTracking event, Emitter<RouteTrackingState> emit) async {
    emit(RouteTrackingLoading());
    try {
      final String? routeName = await routesRepository.getNearbyRoute(event.position);
      final bool isOnRoute = routesRepository.isPositionNearRoute(event.position);
      final List<LatLng> routePolyline = routesRepository.getDetectedRoutePolyline();
      emit(RouteTrackingLoaded(
        routeName: routeName,
        isOnRoute: isOnRoute,
        routePolyline: routePolyline,
        showPolyline: true,
      ));
    } catch (e) {
      emit(RouteTrackingError('Failed to load route tracking: ${e.toString()}'));
    }
  }

  void _onToggleRoutePolyline(
      ToggleRoutePolyline event, Emitter<RouteTrackingState> emit) {
    if (state is RouteTrackingLoaded) {
      final currentState = state as RouteTrackingLoaded;
      emit(RouteTrackingLoaded(
        routeName: currentState.routeName,
        isOnRoute: currentState.isOnRoute,
        routePolyline: currentState.routePolyline,
        showPolyline: !currentState.showPolyline,
      ));
    }
  }
}
