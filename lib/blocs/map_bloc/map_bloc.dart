import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location_repository/location_repository.dart';
import 'package:pttms/data/repository/routes_repository.dart';

part 'map_event.dart';
part 'map_state.dart';

class MapBloc extends Bloc<MapEvent, MapState> {
  final LocationRepository locationRepository;
  final RoutesRepository routesRepository;

  MapBloc({
    required this.locationRepository,
    required this.routesRepository,
  }) : super(MapInitial()) {
    on<MapLoad>(_onMapLoad);
    on<UpdateCameraPosition>(_onUpdateCameraPosition);
    on<MoveToCurrentLocation>(_onMoveToCurrentLocation);
  }

  Future<void> _onMapLoad(MapLoad event, Emitter<MapState> emit) async {
    emit(MapLoading());

    try {
      final LatLng? position = await locationRepository.getCurrentLocation();

      if (position == null) {
        emit(const MapError('Location permission denied or unavailable.'));
      } else {
        final String? routeName = await routesRepository.getNearbyRoute(position);
        final bool isOnRoute = routesRepository.isPositionNearRoute(position);
        final List<LatLng> routePolyline = routesRepository.getDetectedRoutePolyline(); // ✅ Get route polyline

        emit(MapLoadedWithRoute(position, routeName, isOnRoute, routePolyline));
      }
    } catch (e) {
      emit(MapError('Failed to load map: ${e.toString()}'));
    }
  }

  void _onUpdateCameraPosition(
      UpdateCameraPosition event, Emitter<MapState> emit) {
    if (state is MapLoadedWithRoute) {
      final currentState = state as MapLoadedWithRoute;
      final bool isOnRoute = routesRepository.isPositionNearRoute(event.position);

      emit(MapLoadedWithRoute(
        event.position, 
        currentState.routeName, 
        isOnRoute, 
        currentState.routePolyline // ✅ Keep the existing polyline
      ));
    }
  }

  Future<void> _onMoveToCurrentLocation(
      MoveToCurrentLocation event, Emitter<MapState> emit) async {
    if (state is MapLoadedWithRoute) {
      try {
        final LatLng? position = await locationRepository.getCurrentLocation();
        if (position != null) {
          final String? routeName = await routesRepository.getNearbyRoute(position);
          final bool isOnRoute = routesRepository.isPositionNearRoute(position);
          final List<LatLng> routePolyline = routesRepository.getDetectedRoutePolyline(); // ✅ Get new polyline

          emit(MapLoadedWithRoute(position, routeName, isOnRoute, routePolyline));
        }
      } catch (e) {
        emit(MapError('Failed to fetch current location: ${e.toString()}'));
      }
    }
  }
}
