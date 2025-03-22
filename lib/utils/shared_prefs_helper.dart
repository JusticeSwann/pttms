// lib/utils/shared_prefs_helper.dart
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsHelper {
  static const String selectedRoutesKey = 'selected_routes';

  Future<void> saveSelectedRoutes(List<String> routeNames) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(selectedRoutesKey, routeNames);
  }

  Future<List<String>> loadSelectedRoutes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(selectedRoutesKey) ?? [];
  }
}
