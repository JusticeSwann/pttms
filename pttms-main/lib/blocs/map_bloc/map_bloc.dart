import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location_repository/location_repository.dart';

part 'map_event.dart';
part 'map_state.dart';

class MapBloc extends Bloc<MapEvent, MapState> {
  final LocationRepository locationRepository;

  MapBloc({required this.locationRepository}) : super(MapInitial()) {
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
        emit(MapLoaded(position));
      }
    } catch (e) {
      emit(MapError('Failed to load map: ${e.toString()}'));
    }
  }

  void _onUpdateCameraPosition(
      UpdateCameraPosition event, Emitter<MapState> emit) {
    if (state is MapLoaded) {
      emit(MapLoaded(event.position));
    }
  }

  Future<void> _onMoveToCurrentLocation(
      MoveToCurrentLocation event, Emitter<MapState> emit) async {
    if (state is MapLoaded) {
      try {
        final LatLng? position = await locationRepository.getCurrentLocation();
        if (position != null) {
          emit(MapLoaded(position)); 
        }
      } catch (e) {
        emit(MapError('Failed to fetch current location: ${e.toString()}'));
      }
    }
  }
}
