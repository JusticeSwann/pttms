import 'package:location/location.dart';
import 'package:workmanager/workmanager.dart';

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // Initialize the location service.
    Location location = Location();
    
    // Optionally, request permission if not already granted
    bool _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) return Future.value(false);
    }
    
    PermissionStatus _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) return Future.value(false);
    }
    
    // Get the user's current location
    LocationData locationData = await location.getLocation();
    
    // Log or send the location data
    print("Lat: ${locationData.latitude}, Long: ${locationData.longitude}");
    
    return Future.value(true);
  });
}
