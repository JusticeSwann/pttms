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
  final String lastUpdated;  // formatted as "HH:MM AM/PM"
  final String eta;          // ETA string (e.g., "8 min" or "-")

  const MapLoaded({
    required this.position,
    this.routeTrace = const [],
    this.activeVehicleLocations = const [],
    this.averageWaitTime = 0,
    this.lastUpdated = "",
    this.eta = "-",
  });

  @override
  List<Object?> get props =>
      [position, routeTrace, activeVehicleLocations, averageWaitTime, lastUpdated, eta];

  MapLoaded copyWith({
    LatLng? position,
    List<LatLng>? routeTrace,
    List<VehicleLocationData>? activeVehicleLocations,
    int? averageWaitTime,
    String? lastUpdated,
    String? eta,
  }) {
    return MapLoaded(
      position: position ?? this.position,
      routeTrace: routeTrace ?? this.routeTrace,
      activeVehicleLocations: activeVehicleLocations ?? this.activeVehicleLocations,
      averageWaitTime: averageWaitTime ?? this.averageWaitTime,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      eta: eta ?? this.eta,
    );
  }
}

class MapError extends MapState {
  final String message;
  const MapError(this.message);
  @override
  List<Object?> get props => [message];
}
