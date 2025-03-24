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
  final List<LatLng> routeTrace;
  final List<VehicleLocationData> activeVehicleLocations;

  const MapLoaded({
    required this.position,
    this.routeTrace = const [],
    this.activeVehicleLocations = const [],
  });

  @override
  List<Object?> get props => [position, routeTrace, activeVehicleLocations];

  MapLoaded copyWith({
    LatLng? position,
    List<LatLng>? routeTrace,
    List<VehicleLocationData>? activeVehicleLocations,
  }) {
    return MapLoaded(
      position: position ?? this.position,
      routeTrace: routeTrace ?? this.routeTrace,
      activeVehicleLocations: activeVehicleLocations ?? this.activeVehicleLocations,
    );
  }
}

class MapError extends MapState {
  final String message;
  const MapError(this.message);
  @override
  List<Object?> get props => [message];
}
