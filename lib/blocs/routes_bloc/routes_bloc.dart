import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pttms/blocs/routes_bloc/routes_event.dart';
import 'package:pttms/blocs/routes_bloc/routes_state.dart';
import 'package:pttms/data/models/route_card_data.dart';
import 'package:pttms/data/repository/routes_repository.dart';
import 'package:pttms/data/repository/routes_selection_repository.dart';

class RoutesBloc extends Bloc<RoutesEvent, RoutesState> {
  final RoutesRepository _routesRepository;
  final RouteSelectionRepository _selectionRepository;

  RoutesBloc(
    this._routesRepository,
    this._selectionRepository,
  ) : super(const RoutesState(
          allRoutes: [],
          selectedRoutes: [],
          activeVehicleType: 'bus',
        )) {
    on<FetchRoutes>(_onFetchRoutes);
    on<VehicleTypeSelected>(_onVehicleTypeSelected);
    on<RouteSelected>(_onRouteSelected);
    on<RouteRemoved>(_onRouteRemoved);
  }

  /// Fetches all available routes and merges persisted selections.
  Future<void> _onFetchRoutes(FetchRoutes event, Emitter<RoutesState> emit) async {
    try {
      // Fetch all routes (original repository returns List<RouteModel>).
      // Convert each RouteModel to RouteCardData.
      final routeModels = await _routesRepository.fetchRoutes();
      final allRoutes = routeModels.map((r) => RouteCardData(
        name: r.name,
        vehicleType: r.vehicleType,
        waitTimeInSeconds: r.waitTime, // Ensure that RouteModel includes waitTime in seconds.
      )).toList();

      // Load persisted selected route names.
      final selectedNames = await _selectionRepository.loadSelectedRoutes();
      final selectedRoutes = allRoutes.where((r) => selectedNames.contains(r.name)).toList();

      emit(state.copyWith(allRoutes: allRoutes, selectedRoutes: selectedRoutes));
    } catch (e) {
      emit(state.copyWith(allRoutes: [], selectedRoutes: []));
    }
  }

  void _onVehicleTypeSelected(VehicleTypeSelected event, Emitter<RoutesState> emit) {
    emit(state.copyWith(activeVehicleType: event.vehicleType));
  }

  Future<void> _onRouteSelected(RouteSelected event, Emitter<RoutesState> emit) async {
    final updatedSelected = List<RouteCardData>.from(state.selectedRoutes)
      ..add(event.selectedRoute);
    await _selectionRepository.saveSelectedRoutes(
      updatedSelected.map((r) => r.name).toList(),
    );
    emit(state.copyWith(selectedRoutes: updatedSelected));
  }

  Future<void> _onRouteRemoved(RouteRemoved event, Emitter<RoutesState> emit) async {
    final updatedSelected = state.selectedRoutes.where((r) => r.name != event.routeName).toList();
    await _selectionRepository.saveSelectedRoutes(
      updatedSelected.map((r) => r.name).toList(),
    );
    emit(state.copyWith(selectedRoutes: updatedSelected));
  }
}
