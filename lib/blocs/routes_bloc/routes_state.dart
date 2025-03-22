// lib/blocs/route_bloc/route_state.dart
import 'package:equatable/equatable.dart';
import 'package:pttms/data/models/route_model.dart';

class RouteState extends Equatable {
  final List<RouteModel> allRoutes;
  final List<RouteModel> selectedRoutes;
  final String activeVehicleType; // "bus" or "maxi"

  const RouteState({
    required this.allRoutes,
    required this.selectedRoutes,
    required this.activeVehicleType,
  });

  List<RouteModel> get availableRoutes => allRoutes
      .where((route) =>
          route.vehicleType == activeVehicleType &&
          !selectedRoutes.any((sel) => sel.name == route.name))
      .toList();

  RouteState copyWith({
    List<RouteModel>? allRoutes,
    List<RouteModel>? selectedRoutes,
    String? activeVehicleType,
  }) {
    return RouteState(
      allRoutes: allRoutes ?? this.allRoutes,
      selectedRoutes: selectedRoutes ?? this.selectedRoutes,
      activeVehicleType: activeVehicleType ?? this.activeVehicleType,
    );
  }

  @override
  List<Object> get props => [allRoutes, selectedRoutes, activeVehicleType];
}
