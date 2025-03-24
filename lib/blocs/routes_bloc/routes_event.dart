import 'package:equatable/equatable.dart';
import 'package:pttms/data/models/route_card_data.dart';

abstract class RoutesEvent extends Equatable {
  const RoutesEvent();
  @override
  List<Object> get props => [];
}

class FetchRoutes extends RoutesEvent {}

class VehicleTypeSelected extends RoutesEvent {
  final String vehicleType;
  const VehicleTypeSelected(this.vehicleType);
  @override
  List<Object> get props => [vehicleType];
}

class RouteSelected extends RoutesEvent {
  final RouteCardData selectedRoute;
  const RouteSelected(this.selectedRoute);
  @override
  List<Object> get props => [selectedRoute];
}

class RouteRemoved extends RoutesEvent {
  final String routeName;
  const RouteRemoved(this.routeName);
  @override
  List<Object> get props => [routeName];
}
