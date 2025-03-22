// lib/blocs/route_bloc/route_event.dart
import 'package:equatable/equatable.dart';
import 'package:pttms/data/models/route_model.dart';

abstract class RouteEvent extends Equatable {
  const RouteEvent();
  @override
  List<Object> get props => [];
}

class FetchRoutes extends RouteEvent {}

class VehicleTypeSelected extends RouteEvent {
  final String vehicleType;
  const VehicleTypeSelected(this.vehicleType);
  @override
  List<Object> get props => [vehicleType];
}

class RouteSelected extends RouteEvent {
  final RouteModel selectedRoute;
  const RouteSelected(this.selectedRoute);
  @override
  List<Object> get props => [selectedRoute];
}

class RouteRemoved extends RouteEvent {
  final String routeName;
  const RouteRemoved(this.routeName);
  @override
  List<Object> get props => [routeName];
}
