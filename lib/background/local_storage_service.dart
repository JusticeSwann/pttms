// lib/services/local_storage_service.dart
import 'package:hive/hive.dart';

class LocalStorageService {
  static const String boxName = 'trackingUpdates';

  Future<void> init() async {
    await Hive.openBox(boxName);
  }

  Box get _box => Hive.box(boxName);

  /// Save a tracking update locally.
  Future<void> saveTrackingUpdate(Map<String, dynamic> update) async {
    final key = DateTime.now().millisecondsSinceEpoch.toString();
    await _box.put(key, update);
    print("Tracking update saved locally with key: $key");
  }

  /// Retrieve all pending tracking updates.
  List<Map<String, dynamic>> getPendingUpdates() {
    final updates = <Map<String, dynamic>>[];
    for (var key in _box.keys) {
      final data = _box.get(key);
      if (data is Map<String, dynamic>) {
        updates.add(data);
      }
    }
    return updates;
  }

  /// Remove a specific tracking update.
  Future<void> removeTrackingUpdate(String key) async {
    await _box.delete(key);
    print("Tracking update with key $key removed from local storage");
  }

  /// Clear all pending tracking updates.
  Future<void> clearPendingUpdates() async {
    await _box.clear();
    print("All pending tracking updates cleared from local storage");
  }
}
