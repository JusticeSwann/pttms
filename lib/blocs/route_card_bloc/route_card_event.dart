part of 'route_card_bloc.dart';

sealed class RouteCardEvent extends Equatable {
  const RouteCardEvent();

  @override
  List<Object?> get props => [];
}

/// Fired to (re)start listening for active vehicle data.
final class RouteCardStart extends RouteCardEvent {
  const RouteCardStart();
}

/// Fired when the active vehicle stream updates.
final class RouteCardVehiclesUpdated extends RouteCardEvent {
  final List<VehicleLocationData> vehicles;

  const RouteCardVehiclesUpdated(this.vehicles);

  @override
  List<Object?> get props => [vehicles];
}
