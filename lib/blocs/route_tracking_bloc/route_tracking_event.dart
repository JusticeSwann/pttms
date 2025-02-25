part of 'route_tracking_bloc.dart';

sealed class RouteTrackingEvent extends Equatable {
  const RouteTrackingEvent();

  @override
  List<Object> get props => [];
}

class UpdateRouteTracking extends RouteTrackingEvent {
  final LatLng position;

  const UpdateRouteTracking(this.position);

  @override
  List<Object> get props => [position];
}

class ToggleRoutePolyline extends RouteTrackingEvent {}
