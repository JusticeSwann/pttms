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
    on<TogglePolyline>(_onTogglePolyline); 
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
        final List<LatLng> routePolyline = routesRepository.getDetectedRoutePolyline();

        emit(MapLoadedWithRoute(
          position: position,
          routeName: routeName,
          isOnRoute: isOnRoute,
          routePolyline: routePolyline,
          showPolyline: true, 
        ));
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
        position: event.position,
        routeName: currentState.routeName,
        isOnRoute: isOnRoute,
        routePolyline: currentState.routePolyline,
        showPolyline: currentState.showPolyline,
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
          final List<LatLng> routePolyline = routesRepository.getDetectedRoutePolyline();

          emit(MapLoadedWithRoute(
            position: position,
            routeName: routeName,
            isOnRoute: isOnRoute,
            routePolyline: routePolyline,
            showPolyline: (state as MapLoadedWithRoute).showPolyline,
          ));
        }
      } catch (e) {
        emit(MapError('Failed to fetch current location: ${e.toString()}'));
      }
    }
  }

  void _onTogglePolyline(TogglePolyline event, Emitter<MapState> emit) {
    if (state is MapLoadedWithRoute) {
      final currentState = state as MapLoadedWithRoute;
      emit(MapLoadedWithRoute(
        position: currentState.position,
        routeName: currentState.routeName,
        isOnRoute: currentState.isOnRoute,
        routePolyline: currentState.routePolyline,
        showPolyline: !currentState.showPolyline,
      ));
    }
  }
}
