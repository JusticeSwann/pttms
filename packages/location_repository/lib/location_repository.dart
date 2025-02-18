library location_repository;
export 'location_repository.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class LocationRepository {
  final Location _locationService = Location();

  LocationRepository(){
    _locationService.changeSettings(accuracy: LocationAccuracy.high);
  }

  Future<bool> requestPermission() async {
    bool serviceEnabled = await _locationService.serviceEnabled();
    if (!serviceEnabled){
      serviceEnabled = await _locationService.requestService();
      if (!serviceEnabled) return false;
    }

    PermissionStatus permissionGranted = await _locationService.hasPermission();
    if (permissionGranted == PermissionStatus.denied){
      permissionGranted = await _locationService.requestPermission();
      if (permissionGranted == PermissionStatus.denied) return false;
    }
    return true;
  }

  Future<LatLng?> getCurrentLocation() async {
    try{
      bool permissionGranted = await requestPermission();
      if (!permissionGranted) return null;

      final locationData = await _locationService.getLocation();
      return LatLng(locationData.latitude!, locationData.longitude!);
    } catch (e) {
      rethrow;
    }
  }

  Stream<LatLng> trackLocationUpdates() async* {
    bool permissionGranted = await requestPermission();
    
    if (!permissionGranted){
      throw Exception('Location permission not granted');
    }

    await for (final locationData in _locationService.onLocationChanged){
      yield LatLng(locationData.latitude!, locationData.longitude!);
    }
  }
}

