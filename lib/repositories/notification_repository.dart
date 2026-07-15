import '../models/notification_record.dart';
import 'firestore_paths.dart';

class NotificationRepository {
  NotificationRepository();

  Stream<List<NotificationRecord>> watchNotifications(String uid) {
    return FirestorePaths.notifications(uid)
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => NotificationRecord.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<void> addNotification(String uid, NotificationRecord record) async {
    await FirestorePaths.notifications(uid)
        .doc(record.id)
        .set(record.toFirestore());
  }

  Future<bool> hasNotification(String uid, String notificationId) async {
    final snapshot =
        await FirestorePaths.notifications(uid).doc(notificationId).get();
    return snapshot.exists;
  }

  Future<void> updateNotification(
    String uid,
    NotificationRecord record,
  ) async {
    await FirestorePaths.notifications(uid)
        .doc(record.id)
        .update(record.toFirestore());
  }

  Future<void> deleteNotifications(String uid, List<String> notificationIds) async {
    if (notificationIds.isEmpty) return;
    final batch = FirestorePaths.notifications(uid).firestore.batch();
    for (final id in notificationIds) {
      final docRef = FirestorePaths.notifications(uid).doc(id);
      batch.delete(docRef);
    }
    await batch.commit();
  }

  Future<void> markAllRead(String uid) async {
    final snapshot = await FirestorePaths.notifications(uid)
        .where('isRead', isEqualTo: false)
        .get();
    if (snapshot.docs.isEmpty) return;

    final batch = FirestorePaths.notifications(uid).firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}
