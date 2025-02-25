part of 'route_tracking_bloc_bloc.dart';

sealed class RouteTrackingBlocEvent extends Equatable {
  const RouteTrackingBlocEvent();

  @override
  List<Object> get props => [];
}

class UpdateRouteTracking extends RouteTrackingBlocEvent {
  final LatLng position;

  const UpdateRouteTracking(this.position);

  @override
  List<Object> get props => [position];
}

class ToggleRoutePolyline extends RouteTrackingBlocEvent {}
