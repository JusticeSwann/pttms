import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class TrafficService {
  final String apiKey;

  TrafficService({required this.apiKey});

  /// Fetch traffic data for a given start and end location.
  /// Optionally, you can pass a departureTime (in seconds since epoch).
  /// Returns a Map containing data for both the raw route and traffic-adjusted route.
  Future<Map<String, dynamic>> fetchTrafficData({
    required LatLng origin,
    required LatLng destination,
    required int departureTime, // Unix timestamp (seconds)
  }) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json?'
      'origin=${origin.latitude},${origin.longitude}&'
      'destination=${destination.latitude},${destination.longitude}&'
      'departure_time=$departureTime&'
      'key=$apiKey',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // Parse the data to extract relevant traffic information.
      // For example, you can extract "duration_in_traffic" and "duration".
      if (data['status'] == 'OK') {
        final route = data['routes'][0];
        final leg = route['legs'][0];

        // For raw duration (without traffic) and duration_in_traffic.
        final rawDuration = leg['duration']['value']; // seconds
        final trafficDuration = leg['duration_in_traffic'] != null
            ? leg['duration_in_traffic']['value']
            : rawDuration;

        return {
          'raw_duration': rawDuration,
          'traffic_duration': trafficDuration,
          // Optionally, include any other info you want.
        };
      } else {
        throw Exception('Directions API error: ${data['status']}');
      }
    } else {
      throw Exception('Failed to fetch traffic data. Status: ${response.statusCode}');
    }
  }

  /// Map traffic data to a traffic level.
  /// For example, if the difference between raw and traffic duration is high,
  /// we can say traffic is "high". Adjust thresholds as needed.
  String determineTrafficLevel({
    required int rawDuration,
    required int trafficDuration,
  }) {
    final delay = trafficDuration - rawDuration;
    if (delay <= 60) {
      return 'low';
    } else if (delay <= 180) {
      return 'medium';
    } else {
      return 'high';
    }
  }
}
