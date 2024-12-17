import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'map_event.dart';
import 'map_state.dart';
import 'package:location_repository/location_repository.dart';
import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapBloc extends Bloc<MapEvent, MapState> {
  final LocationRepository locationRepository;
  Timer? _timer;
  String? _deviceId;
  LatLng? _lastPosition;
  DateTime? _lastTimestamp;
  String _status = 'passive'; // passive or active
  String? _currentRouteName;
  List<Map<String, dynamic>> _nearbyRoutes = [];

  // Report data
  String? _reportId;
  LatLng? _startLocation;
  int _waitingTime = 0;
  int _activeTime = 0;
  double _totalDistance = 0;
  double _totalSpeed = 0;
  int _speedCount = 0;

  // Offline queue for updates
  final List<Map<String, dynamic>> _offlineUpdates = [];

  MapBloc({required this.locationRepository}) : super(MapInitial()) {
    _initialize();
    on<LoadMap>(_onLoadMap);
    on<UpdateCameraPosition>(_onUpdateCameraPosition);
  }

  Future<void> _initialize() async {
    await _initDeviceId();
    add(LoadMap());
  }

  Future<void> _initDeviceId() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    try {
      final androidInfo = await deviceInfo.androidInfo;
      _deviceId = androidInfo.id;
      print('Device ID initialized: $_deviceId');
    } catch (e) {
      print('Error initializing device ID: $e');
    }
  }

  Future<void> _onLoadMap(LoadMap event, Emitter<MapState> emit) async {
    emit(MapLoading());
    try {
      final position = await locationRepository.getCurrentLocation();
      if (position == null) {
        emit(const MapError('Location permission denied or unavailable.'));
      } else {
        emit(MapLoaded(position));
        _startLocationSaving();
      }
    } catch (e) {
      emit(MapError('Failed to load map: ${e.toString()}'));
    }
  }

  void _onUpdateCameraPosition(UpdateCameraPosition event, Emitter<MapState> emit) {
    emit(MapLoaded(event.position));
  }

  void _startLocationSaving() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        final position = await locationRepository.getCurrentLocation();
        if (position == null || _deviceId == null) {
          print('Location or device ID unavailable. Skipping upload.');
          return;
        }

        final routes = await _loadRoutesFromJson();
        _nearbyRoutes = [];
        String? closestRouteName;
        double minDistance = double.infinity;

        for (var route in routes) {
          final polyline = route['polyline'] as List;
          final parsedPolyline = polyline.map<List<double>>((point) {
            return List<double>.from(point);
          }).toList();

          final distance = _calculateMinDistanceToRoute(position, parsedPolyline);

          if (distance <= 300) {
            _nearbyRoutes.add({
              ...route,
              'polyline': parsedPolyline,
            });
            if (distance < minDistance) {
              minDistance = distance;
              closestRouteName = route['name'];
            }
          }
        }

        _currentRouteName = closestRouteName;
        print('Closest Route: $_currentRouteName');

        // Calculate speed
        double speed = 0;
        if (_lastPosition != null && _lastTimestamp != null) {
          final timeDiff = DateTime.now().difference(_lastTimestamp!).inSeconds;
          final distance = _calculateDistance(
            _lastPosition!.latitude,
            _lastPosition!.longitude,
            position.latitude,
            position.longitude,
          );
          speed = distance / timeDiff;
          _totalDistance += distance;
          _totalSpeed += speed;
          _speedCount++;
        }

        final isOnRoute = _nearbyRoutes.any((route) {
          final polyline = route['polyline'] as List<List<double>>;
          return _isNearRoute(position, polyline, distanceThreshold: 50);
        });

        if (_status == 'passive' && speed > 5 && isOnRoute) {
          _status = 'active';
          _initializeReport(position);
        }

        if (_status == 'active') {
          if (isOnRoute) {
            _activeTime += 5;
          } else {
            _status = 'passive';
          }
        }

        // Prepare data for upload
        final data = {
          'waiting_time': _waitingTime,
          'active_time': _activeTime,
          'last_location': {'lat': position.latitude, 'lng': position.longitude},
          'avg_speed': _speedCount > 0 ? _totalSpeed / _speedCount : 0,
        };

        // Update report
        if (_reportId != null) {
          await _updateReport(data);
        }

        _lastPosition = position;
        _lastTimestamp = DateTime.now();
      } catch (e) {
        print('Error updating report: $e');
      }
    });
  }

  void _initializeReport(LatLng position) {
    _reportId = '$_deviceId-${DateTime.now().millisecondsSinceEpoch}';
    _startLocation = position;
    _waitingTime = 0;
    _activeTime = 0;
    _totalDistance = 0;
    _totalSpeed = 0;
    _speedCount = 0;

    final data = {
      'report_id': _reportId,
      'device_id': _deviceId,
      'route_name': _currentRouteName,
      'waiting_time': _waitingTime,
      'active_time': _activeTime,
      'start_location': {'lat': position.latitude, 'lng': position.longitude},
      'last_location': {'lat': position.latitude, 'lng': position.longitude},
      'avg_speed': null,
    };

    _uploadData(data);
  }

  Future<void> _updateReport(Map<String, dynamic> data) async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      print('No internet connection. Queuing update.');
      _offlineUpdates.add(data);
    } else {
      await _uploadData(data);
      await _syncOfflineData();
    }
  }

  Future<void> _uploadData(Map<String, dynamic> data) async {
    await FirebaseFirestore.instance.collection('actor_report').doc(_reportId).set(data, SetOptions(merge: true));
    print('Data uploaded: $data');
  }

  Future<void> _syncOfflineData() async {
    while (_offlineUpdates.isNotEmpty) {
      final data = _offlineUpdates.removeAt(0);
      await _uploadData(data);
      print('Offline data synced: $data');
    }
  }

  bool _isNearRoute(LatLng position, List<List<double>> polyline, {int distanceThreshold = 50}) {
    for (int i = 0; i < polyline.length - 1; i++) {
      final segmentStart = polyline[i];
      final segmentEnd = polyline[i + 1];
      final distance = _distanceToSegment(
        position.latitude,
        position.longitude,
        segmentStart[0],
        segmentStart[1],
        segmentEnd[0],
        segmentEnd[1],
      );
      if (distance <= distanceThreshold) return true;
    }
    return false;
  }

  double _calculateMinDistanceToRoute(LatLng position, List<List<double>> polyline) {
    double minDistance = double.infinity;
    for (int i = 0; i < polyline.length - 1; i++) {
      final segmentStart = polyline[i];
      final segmentEnd = polyline[i + 1];
      final distance = _distanceToSegment(
        position.latitude,
        position.longitude,
        segmentStart[0],
        segmentStart[1],
        segmentEnd[0],
        segmentEnd[1],
      );
      minDistance = min(minDistance, distance);
    }
    return minDistance;
  }

  double _distanceToSegment(double lat, double lon, double lat1, double lon1, double lat2, double lon2) {
    final p = [lat, lon];
    final v = [lat1, lon1];
    final w = [lat2, lon2];
    final l2 = pow(lat2 - lat1, 2) + pow(lon2 - lon1, 2);
    if (l2 == 0.0) return _calculateDistance(lat, lon, lat1, lon1);

    var t = ((p[0] - v[0]) * (w[0] - v[0]) + (p[1] - v[1]) * (w[1] - v[1])) / l2;
    t = max(0, min(1, t));
    final projection = [v[0] + t * (w[0] - v[0]), v[1] + t * (w[1] - v[1])];
    return _calculateDistance(lat, lon, projection[0], projection[1]);
  }

  Future<List<Map<String, dynamic>>> _loadRoutesFromJson() async {
    final String response = await rootBundle.loadString('assets/routes.json');
    final data = json.decode(response) as Map<String, dynamic>;
    return (data['routes'] as List).map((e) => e as Map<String, dynamic>).toList();
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371000;
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) * sin(dLon / 2);
    return earthRadius * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _degreesToRadians(double degrees) => degrees * pi / 180;

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}