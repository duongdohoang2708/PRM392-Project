import 'package:cloud_firestore/cloud_firestore.dart';

class FirestorePaths {
  static CollectionReference<Map<String, dynamic>> users() =>
      FirebaseFirestore.instance.collection('users');

  static DocumentReference<Map<String, dynamic>> user(String uid) =>
      users().doc(uid);

  static CollectionReference<Map<String, dynamic>> projects(String uid) =>
      user(uid).collection('projects');

  static CollectionReference<Map<String, dynamic>> tasks(String uid) =>
      user(uid).collection('tasks');

  static CollectionReference<Map<String, dynamic>> focusSessions(String uid) =>
      user(uid).collection('focusSessions');

  static CollectionReference<Map<String, dynamic>> notifications(String uid) =>
      user(uid).collection('notifications');

  static DocumentReference<Map<String, dynamic>> userSettings(String uid) =>
      user(uid).collection('settings').doc('userSettings');
}

DateTime? timestampToDateTime(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

Timestamp? dateTimeToTimestamp(DateTime? value) =>
    value == null ? null : Timestamp.fromDate(value);

Map<String, dynamic> stripNulls(Map<String, dynamic> data) {
  return Map<String, dynamic>.fromEntries(
    data.entries.where((entry) => entry.value != null),
  );
}
