import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_paths.dart';

class SettingsRepository {
  SettingsRepository();

  Stream<Map<String, dynamic>?> watchSettings(String uid) {
    return FirestorePaths.userSettings(uid).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return Map<String, dynamic>.from(snapshot.data()!);
    });
  }

  Future<Map<String, dynamic>?> fetchSettings(String uid) async {
    final snapshot = await FirestorePaths.userSettings(uid).get();
    if (!snapshot.exists || snapshot.data() == null) return null;
    return Map<String, dynamic>.from(snapshot.data()!);
  }

  Future<void> saveSettings(String uid, Map<String, dynamic> data) async {
    await FirestorePaths.userSettings(uid).set(data, SetOptions(merge: true));
  }

  Future<void> mergeSettings(String uid, Map<String, dynamic> patch) async {
    await FirestorePaths.userSettings(uid).set(patch, SetOptions(merge: true));
  }
}
