part of 'route_tracking_bloc_bloc.dart';

sealed class RouteTrackingBlocState extends Equatable {
  const RouteTrackingBlocState();
  
  @override
  List<Object> get props => [];
}

class RouteTrackingBlocInitial extends RouteTrackingBlocState {}

class RouteTrackingLoading extends RouteTrackingBlocState {}

class RouteTrackingLoaded extends RouteTrackingBlocState {
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

class RouteTrackingError extends RouteTrackingBlocState {
  final String message;

  const RouteTrackingError(this.message);

  @override
  List<Object> get props => [message];
}
