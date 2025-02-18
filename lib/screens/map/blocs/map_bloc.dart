/*
class MapBloc extends Bloc<MapEvent, MapState> {
  final LocationRepository locationRepository;
  Timer? _uploadTimer;
  Timer? _routeTraceTimer;
  String? _deviceId;
  LatLng? _lastPosition;
  DateTime? _lastTimestamp;
  String _status = 'passive'; // passive or active
  String? _currentRouteName;
  List<Map<String, dynamic>> _nearbyRoutes = [];
  List<LatLng> _routeTrace = [];
  List<LatLng> _stopsMade = [];

  // Report data
  String? _reportId;
  LatLng? _startLocation;
  int _waitingTime = 0;
  int _activeTime = 0;
  double _totalDistance = 0;
  double _totalSpeed = 0;
  int _speedCount = 0;
  

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
        _startRouteTraceUpdater();
      }
    } catch (e) {
      emit(MapError('Failed to load map: ${e.toString()}'));
    }
  }

  void _onUpdateCameraPosition(UpdateCameraPosition event, Emitter<MapState> emit) {
    // Update the map state with the new camera position
    emit(MapLoaded(event.position));
  }

void _startLocationSaving() {
  _uploadTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
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
        try {
          final polyline = (route['polyline'] as List)
              .map((point) => (point as List).map((e) => e as double).toList())
              .toList();

          final distance = _calculateMinDistanceToRoute(position, polyline);

          if (distance <= 300) {
            _nearbyRoutes.add({
              ...route,
              'polyline': polyline,
            });
            if (distance < minDistance) {
              minDistance = distance;
              closestRouteName = route['name'];
            }
          }
        } catch (e) {
          print('Error parsing route polyline: $e');
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
        speed = (distance / timeDiff) * 3.6; // Convert m/s to km/h
        _totalDistance += distance;
        _totalSpeed += speed;
        _speedCount++;
      }

      final isOnRoute = _nearbyRoutes.any((route) {
        try {
          final polyline = (route['polyline'] as List<List<double>>);
          return _isNearRoute(position, polyline, distanceThreshold: 50);
        } catch (e) {
          print('Error checking route: $e');
          return false;
        }
      });

      // Update active and passive time based on speed and route
      if (isOnRoute) {
        if (speed > 20) {
          _status = 'active';
          _activeTime += 5; // Increment active time
          print('Active: Speed is ${speed.toStringAsFixed(2)} km/h');
        } else {
          _status = 'passive';
          _waitingTime += 5; // Increment passive time
          print('Passive: Speed is ${speed.toStringAsFixed(2)} km/h');
        }
      } else {
        _status = 'passive';
        print('Not on route. Passive by default.');
        _waitingTime += 5; // Increment passive time when not on route
      }

      // Detect and append stops
      if (_lastPosition == position) {
        if (_stopsMade.isEmpty || _stopsMade.last != position) {
          _stopsMade.add(position);
          print('New stop added to stops_made: $_stopsMade');
        }
      }

      final data = {
        'report_id': _reportId,
        'device_id': _deviceId,
        'route_name': _currentRouteName,
        'waiting_time': _waitingTime,
        'active_time': _activeTime,
        'start_location': {'lat': _startLocation?.latitude, 'lng': _startLocation?.longitude},
        'last_location': {'lat': position.latitude, 'lng': position.longitude},
        'avg_speed': _speedCount > 0 ? _totalSpeed / _speedCount : null,
        'route_trace': _routeTrace.map((latLng) => {'lat': latLng.latitude, 'lng': latLng.longitude}).toList(),
        'stops_made': _stopsMade.map((latLng) => {'lat': latLng.latitude, 'lng': latLng.longitude}).toList(),
      };

      if (_reportId != null) {
        print('Uploading data to Firestore...');
        await _uploadData(data);
        print('Data uploaded successfully');
      }

      _lastPosition = position;
      _lastTimestamp = DateTime.now();
    } catch (e) {
      print('Error updating report: $e');
    }
  });
}
  void _startRouteTraceUpdater() {
    _routeTraceTimer = Timer.periodic(const Duration(minutes: 2), (timer) async {
      try {
        final position = await locationRepository.getCurrentLocation();
        if (position == null) return;

        if (_routeTrace.isEmpty || _routeTrace.last != position) {
          _routeTrace.add(position);
          print('Route trace updated: $_routeTrace');
        }
      } catch (e) {
        print('Error updating route trace: $e');
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
    _routeTrace = [position];
    _stopsMade = [];

    final data = {
      'report_id': _reportId,
      'device_id': _deviceId,
      'route_name': _currentRouteName,
      'waiting_time': _waitingTime,
      'active_time': _activeTime,
      'start_location': {'lat': position.latitude, 'lng': position.longitude},
      'last_location': {'lat': position.latitude, 'lng': position.longitude},
      'avg_speed': null,
      'route_trace': _routeTrace.map((latLng) => {'lat': latLng.latitude, 'lng': latLng.longitude}).toList(),
    };

    print('Initializing report with data: $data');
    _uploadData(data);
  }

  Future<void> _uploadData(Map<String, dynamic> data) async {
    try {
      await FirebaseFirestore.instance
          .collection('actor_report')
          .doc(_reportId)
          .set(data, SetOptions(merge: true));
      print('Data uploaded: $data');
    } catch (e) {
      print('Error uploading data: $e');
    }
  }

  Future<void> _syncOfflineData() async {
    while (_offlineUpdates.isNotEmpty) {
      final data = _offlineUpdates.removeAt(0);
      await _uploadData(data);
      print('Offline data synced: $data');
    }
  }

  Future<List<Map<String, dynamic>>> _loadRoutesFromJson() async {
    final String response = await rootBundle.loadString('assets/routes.json');
    final data = json.decode(response) as Map<String, dynamic>;
    return (data['routes'] as List).map((e) => e as Map<String, dynamic>).toList();
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
    _uploadTimer?.cancel();
    _routeTraceTimer?.cancel();
    return super.close();
  }
}
*/