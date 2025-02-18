import 'package:flutter_bloc/flutter_bloc.dart';
import 'routes_event.dart';
import 'routes_state.dart';
import '../../repositories/routes_repository.dart';

class RoutesBloc extends Bloc<RoutesEvent, RoutesState> {
  final RoutesRepository _routesRepository;

  RoutesBloc(this._routesRepository) : super(RoutesInitial()) {
    on<LoadRouteEvent>(_onLoadRoute);
  }

  void _onLoadRoute(LoadRouteEvent event, Emitter<RoutesState> emit) async {
    emit(RoutesLoading());
    try {
      // Fetch the full list of routes
      final routes = await _routesRepository.fetchRoutes();
      // Emit the `RoutesLoaded` state with full route data
      emit(RoutesLoaded(routes: routes));
    } catch (e) {
      emit(RoutesError("Failed to load routes"));
    }
  }
}

//_loadSelectedRoutes
//_saveSelectedRoutes
