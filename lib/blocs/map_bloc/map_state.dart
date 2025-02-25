part of 'map_bloc.dart';

sealed class MapState extends Equatable {
  const MapState();

  @override
  List<Object> get props => [];
}

class MapInitial extends MapState {}

class MapLoading extends MapState {}

/// Modified state to include a [showPolyline] flag.
class MapLoadedWithRoute extends MapState {
  final LatLng position;
  final String? routeName;
  final bool isOnRoute;
  final List<LatLng> routePolyline;
  final bool showPolyline;

  const MapLoadedWithRoute({
    required this.position,
    this.routeName,
    required this.isOnRoute,
    required this.routePolyline,
    this.showPolyline = true,
  });

  @override
  List<Object> get props => [position, routeName ?? '', isOnRoute, routePolyline, showPolyline];
}

class MapError extends MapState {
  final String message;

  const MapError(this.message);

  @override
  List<Object> get props => [message];
}
