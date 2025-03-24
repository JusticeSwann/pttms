import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pttms/data/models/vehicle_location_data.dart';

class ActiveVehicleStreamRepository {
  final FirebaseFirestore _firestore;

  ActiveVehicleStreamRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Returns a stream of active vehicle location data for a given route.
  Stream<List<VehicleLocationData>> streamActiveVehicleLocations(String routeName) {
    return _firestore
        .collection('actor_report')
        .where('route_name', isEqualTo: routeName)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((querySnapshot) {
      return querySnapshot.docs
          .map((doc) => VehicleLocationData.fromDocument(doc))
          .toList();
    });
  }
}
