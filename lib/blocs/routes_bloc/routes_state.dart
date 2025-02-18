abstract class RoutesState {}

class RoutesInitial extends RoutesState {}

class RoutesLoading extends RoutesState {}

class RoutesLoaded extends RoutesState {
  final List<Map<String, dynamic>> routes; // Full route data
  final List<String> routeNames; // Extracted route names

  // Constructor takes full route data and extracts route names
  RoutesLoaded({required this.routes})
      : routeNames = routes.map((route) => route['name'] as String).toList();
}

class RoutesError extends RoutesState {
  final String message;

  RoutesError(this.message);
}
