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
  final int averageWaitTime; // in seconds
  final String lastUpdated; // formatted as "HH:MM AM"

  const MapLoaded({
    required this.position,
    this.routeTrace = const [],
    this.activeVehicleLocations = const [],
    this.averageWaitTime = 0,
    this.lastUpdated = "",
  });

  @override
  List<Object?> get props =>
      [position, routeTrace, activeVehicleLocations, averageWaitTime, lastUpdated];

  MapLoaded copyWith({
    LatLng? position,
    List<LatLng>? routeTrace,
    List<VehicleLocationData>? activeVehicleLocations,
    int? averageWaitTime,
    String? lastUpdated,
  }) {
    return MapLoaded(
      position: position ?? this.position,
      routeTrace: routeTrace ?? this.routeTrace,
      activeVehicleLocations: activeVehicleLocations ?? this.activeVehicleLocations,
      averageWaitTime: averageWaitTime ?? this.averageWaitTime,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class MapError extends MapState {
  final String message;
  const MapError(this.message);
  @override
  List<Object?> get props => [message];
}
