import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_paths.dart';

class UserProfile {
  final String uid;
  final String fullName;
  final String email;
  final String? avatarUrl;
  final DateTime? createdAt;
  final bool? hasSeenWelcome;

  const UserProfile({
    required this.uid,
    required this.fullName,
    required this.email,
    this.avatarUrl,
    this.createdAt,
    this.hasSeenWelcome,
  });

  factory UserProfile.fromFirestore(String uid, Map<String, dynamic> data) {
    return UserProfile(
      uid: uid,
      fullName: data['fullName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      avatarUrl: data['avatarUrl'] as String?,
      createdAt: timestampToDateTime(data['createdAt']),
      hasSeenWelcome: data['hasSeenWelcome'] as bool?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return stripNulls({
      'fullName': fullName,
      'email': email,
      'avatarUrl': avatarUrl,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      if (hasSeenWelcome != null) 'hasSeenWelcome': hasSeenWelcome,
    });
  }
}

class UserRepository {
  UserRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      FirestorePaths.user(uid);

  Future<UserProfile?> fetchProfile(String uid) async {
    final snapshot = await _doc(uid).get();
    if (!snapshot.exists || snapshot.data() == null) return null;
    return UserProfile.fromFirestore(uid, snapshot.data()!);
  }

  Stream<UserProfile?> watchProfile(String uid) {
    return _doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return UserProfile.fromFirestore(uid, snapshot.data()!);
    });
  }

  Future<void> createProfile({
    required String uid,
    required String fullName,
    required String email,
    String? avatarUrl,
  }) async {
    await _doc(uid).set(
      UserProfile(
        uid: uid,
        fullName: fullName,
        email: email,
        avatarUrl: avatarUrl,
        createdAt: DateTime.now(),
        hasSeenWelcome: false,
      ).toFirestore(),
      SetOptions(merge: true),
    );
  }

  Future<void> markWelcomeSeen(String uid) async {
    await _doc(uid).set(
      {'hasSeenWelcome': true},
      SetOptions(merge: true),
    );
  }

  Future<void> updateProfile({
    required String uid,
    String? fullName,
    String? avatarUrl,
  }) async {
    await _doc(uid).set(
      stripNulls({
        if (fullName != null) 'fullName': fullName,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
      }),
      SetOptions(merge: true),
    );
  }
}
