// lib/data/repository/route_selection_repository.dart

import 'package:shared_preferences/shared_preferences.dart';

class RouteSelectionRepository {
  static const String selectedRoutesKey = 'selected_routes';

  /// Saves the list of selected route names to local storage.
  Future<void> saveSelectedRoutes(List<String> routeNames) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(selectedRoutesKey, routeNames);
  }

  /// Loads the list of selected route names from local storage.
  Future<List<String>> loadSelectedRoutes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(selectedRoutesKey) ?? [];
  }
}
