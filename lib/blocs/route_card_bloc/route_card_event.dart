part of 'route_card_bloc.dart';

abstract class RouteCardEvent extends Equatable {
  const RouteCardEvent();
  @override
  List<Object?> get props => [];
}

class RouteCardStart extends RouteCardEvent {
  const RouteCardStart();
}

class RouteCardVehiclesUpdated extends RouteCardEvent {
  final List<VehicleLocationData> vehicles;
  const RouteCardVehiclesUpdated(this.vehicles);
  @override
  List<Object?> get props => [vehicles];
}
