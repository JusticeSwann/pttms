part of 'map_bloc.dart';

sealed class MapEvent extends Equatable {
  const MapEvent();

  @override
  List<Object> get props => [];
}

class MapLoad extends MapEvent {}

class UpdateCameraPosition extends MapEvent {
  final LatLng position;

  const UpdateCameraPosition(this.position);

  @override
  List<Object> get props => [position];
}

class MoveToCurrentLocation extends MapEvent {}
