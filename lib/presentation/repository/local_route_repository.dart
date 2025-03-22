// lib/presentation/repositories/local_route_repository.dart
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pttms/data/models/route_model.dart';

class LocalRouteRepository {
  Future<List<RouteModel>> loadLocalRoutes() async {
    final String jsonString = await rootBundle.loadString('assets/routes.json');
    final Map<String, dynamic> jsonData = jsonDecode(jsonString);
    final List<dynamic> routesList = jsonData['routes'];
    return routesList
        .map((routeItem) => RouteModel.fromJson(routeItem))
        .toList();
  }
}
