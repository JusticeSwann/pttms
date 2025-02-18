part of 'route_bloc.dart';

sealed class RouteEvent extends Equatable {
  const RouteEvent();

  @override
  List<Object> get props => [];
}

class VehicleTypeSelected extends RouteEvent{
  final List<bool> vehicleType;
  final int vehicleTypeIndex;
  const VehicleTypeSelected({required this.vehicleTypeIndex, required this.vehicleType});
}

class RouteDropdownSelected extends RouteEvent{}

class RouteLoadEvent extends RouteEvent{}

