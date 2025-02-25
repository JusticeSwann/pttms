part of 'route_tracking_bloc.dart';

sealed class RouteTrackingState extends Equatable {
  const RouteTrackingState();
  
  @override
  List<Object> get props => [];
}

class RouteTrackingBlocInitial extends RouteTrackingState {}

class RouteTrackingLoading extends RouteTrackingState {}

class RouteTrackingLoaded extends RouteTrackingState {
  final String? routeName;
  final bool isOnRoute;
  final List<LatLng> routePolyline;
  final bool showPolyline;

  const RouteTrackingLoaded({
    this.routeName,
    required this.isOnRoute,
    required this.routePolyline,
    this.showPolyline = true,
  });

  @override
  List<Object> get props => [routeName ?? '', isOnRoute, routePolyline, showPolyline];
}

class RouteTrackingError extends RouteTrackingState {
  final String message;

  const RouteTrackingError(this.message);

  @override
  List<Object> get props => [message];
}
