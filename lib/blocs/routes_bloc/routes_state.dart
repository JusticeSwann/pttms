import 'package:equatable/equatable.dart';
import 'package:pttms/data/models/route_card_data.dart';

class RoutesState extends Equatable {
  final List<RouteCardData> allRoutes;
  final List<RouteCardData> selectedRoutes;
  final String activeVehicleType; // "bus" or "maxi"

  const RoutesState({
    required this.allRoutes,
    required this.selectedRoutes,
    required this.activeVehicleType,
  });

  List<RouteCardData> get availableRoutes => allRoutes
      .where((route) =>
          route.vehicleType == activeVehicleType &&
          !selectedRoutes.any((sel) => sel.name == route.name))
      .toList();

  RoutesState copyWith({
    List<RouteCardData>? allRoutes,
    List<RouteCardData>? selectedRoutes,
    String? activeVehicleType,
  }) {
    return RoutesState(
      allRoutes: allRoutes ?? this.allRoutes,
      selectedRoutes: selectedRoutes ?? this.selectedRoutes,
      activeVehicleType: activeVehicleType ?? this.activeVehicleType,
    );
  }

  @override
  List<Object> get props => [allRoutes, selectedRoutes, activeVehicleType];
}