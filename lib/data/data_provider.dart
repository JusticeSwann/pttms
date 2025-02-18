import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class RoutesDataProvider {
  Future<List<Map<String, dynamic>>> getRoutes() async {
    final String jsonString = await rootBundle.loadString('assets/routes.json');
    final Map<String, dynamic> data = json.decode(jsonString);
    return List<Map<String, dynamic>>.from(data['routes']);
  }
}
