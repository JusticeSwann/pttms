part of 'map_bloc.dart';

sealed class MapState extends Equatable {
  const MapState();

  @override
  List<Object> get props => [];
}

class MapInitial extends MapState {}

class MapLoading extends MapState {}

/// 🚀 Modified MapLoadedWithRoute to include route polylines
class MapLoadedWithRoute extends MapState {
  final LatLng position;
  final String? routeName;
  final bool isOnRoute;
  final List<LatLng> routePolyline; // ✅ Store polyline

  const MapLoadedWithRoute(
    this.position,
    this.routeName,
    this.isOnRoute,
    this.routePolyline,
  );

  @override
  List<Object> get props => [position, routeName ?? '', isOnRoute, routePolyline];
}

class MapError extends MapState {
  final String message;

  const MapError(this.message);

  @override
  List<Object> get props => [message];
}
