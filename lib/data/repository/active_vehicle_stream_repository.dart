import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pttms/data/models/vehicle_location_data.dart';

class ActiveVehicleStreamRepository {
  final FirebaseFirestore _firestore;

  ActiveVehicleStreamRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Returns a stream of active vehicle location data (filtered only by status).
  Stream<List<VehicleLocationData>> streamActiveVehicleLocations() {
    return _firestore
        .collection('actor_report')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((querySnapshot) {
      return querySnapshot.docs
          .map((doc) => VehicleLocationData.fromDocument(doc))
          .toList();
    });
  }
}
