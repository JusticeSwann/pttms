part of 'route_bloc.dart';

sealed class RouteState extends Equatable {
  const RouteState();
  
  @override
  List<Object> get props => [];
}

final class RouteBlocInitial extends RouteState {}

final class RouteVehicleState extends RouteState {
  final int vehicleTypeIndex;
  final List<bool> vehicleType;
  const RouteVehicleState({required this.vehicleTypeIndex, required this.vehicleType});

  @override
  List<Object> get props => [vehicleTypeIndex];
}

final class RoutesLoading extends RouteState {}

final class RoutesLoaded extends RouteState {
  final List<Map<String, dynamic>> availableRoutes;
  const RoutesLoaded({required this.availableRoutes});
}

final class RoutesLoadError extends RouteState {
  final String message;
  const RoutesLoadError(this.message);
}

