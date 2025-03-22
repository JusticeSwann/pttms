// lib/blocs/route_bloc/routes_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pttms/blocs/routes_bloc/routes_event.dart';
import 'package:pttms/blocs/routes_bloc/routes_state.dart';
import 'package:pttms/data/models/route_model.dart';
import 'package:pttms/data/repository/routes_repository.dart';
import 'package:pttms/data/repository/routes_selection_repository.dart';

class RoutesBloc extends Bloc<RouteEvent, RouteState> {
  final RoutesRepository _routesRepository;
  final RouteSelectionRepository _selectionRepository;

  RoutesBloc(
    this._routesRepository,
    this._selectionRepository,
  ) : super(const RouteState(
          allRoutes: [],
          selectedRoutes: [],
          activeVehicleType: 'bus',
        )) {
    on<FetchRoutes>(_onFetchRoutes);
    on<VehicleTypeSelected>(_onVehicleTypeSelected);
    on<RouteSelected>(_onRouteSelected);
    on<RouteRemoved>(_onRouteRemoved);
  }

  /// Fetches all available routes and merges in persisted selections.
  Future<void> _onFetchRoutes(FetchRoutes event, Emitter<RouteState> emit) async {
    try {
      // For demonstration, let's assume you obtain allRoutes from some source.
      // This could be extended to call an alternative method that returns a full list.
      final allRoutes = await _routesRepository.fetchRoutes(); // If available
      final selectedNames = await _selectionRepository.loadSelectedRoutes();

      final selectedRoutes = allRoutes
          .where((r) => selectedNames.contains(r.name))
          .toList();

      emit(state.copyWith(allRoutes: allRoutes, selectedRoutes: selectedRoutes));
    } catch (e) {
      emit(state.copyWith(allRoutes: [], selectedRoutes: []));
    }
  }

  /// Updates the active vehicle type filter.
  void _onVehicleTypeSelected(
      VehicleTypeSelected event, Emitter<RouteState> emit) {
    emit(state.copyWith(activeVehicleType: event.vehicleType));
  }

  /// Adds a route to the selection and persists it.
  Future<void> _onRouteSelected(
      RouteSelected event, Emitter<RouteState> emit) async {
    final updatedSelected = List<RouteModel>.from(state.selectedRoutes)
      ..add(event.selectedRoute);

    await _selectionRepository.saveSelectedRoutes(
      updatedSelected.map((r) => r.name).toList(),
    );

    emit(state.copyWith(selectedRoutes: updatedSelected));
  }

  /// Removes a route from the selection and updates persistence.
  Future<void> _onRouteRemoved(
      RouteRemoved event, Emitter<RouteState> emit) async {
    final updatedSelected =
        state.selectedRoutes.where((r) => r.name != event.routeName).toList();

    await _selectionRepository.saveSelectedRoutes(
      updatedSelected.map((r) => r.name).toList(),
    );

    emit(state.copyWith(selectedRoutes: updatedSelected));
  }
}
