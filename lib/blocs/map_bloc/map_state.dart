// lib/blocs/map_bloc/map_state.dart
part of 'map_bloc.dart';

abstract class MapState extends Equatable {
  const MapState();

  @override
  List<Object?> get props => [];
}

class MapInitial extends MapState {}

class MapLoading extends MapState {}

class MapLoaded extends MapState {
  final LatLng position;
  final List<LatLng> routeTrace; // <-- New field for polyline data

  const MapLoaded({required this.position, this.routeTrace = const []});

  @override
  List<Object?> get props => [position, routeTrace];
}

class MapError extends MapState {
  final String message;

  const MapError(this.message);

  @override
  List<Object?> get props => [message];
}
