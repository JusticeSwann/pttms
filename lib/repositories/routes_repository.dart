import '../data/data_provider.dart';

class RoutesRepository {
  final RoutesDataProvider _dataProvider;

  RoutesRepository(this._dataProvider);

  // Fetch only route names
  Future<List<String>> fetchRouteNames() async {
    final data = await _dataProvider.getRoutes();
    return data.map((route) => route['name'] as String).toList();
  }

  // Fetch full route data
  Future<List<Map<String, dynamic>>> fetchRoutes() async {
    return await _dataProvider.getRoutes(); // Return the full list of routes
  }
}
