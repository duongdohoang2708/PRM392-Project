import '../models/focus_session_model.dart';
import 'firestore_paths.dart';

class FocusRepository {
  FocusRepository();

  Stream<List<FocusSession>> watchSessions(String uid) {
    return FirestorePaths.focusSessions(uid)
        .orderBy('time', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => FocusSession.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<void> addSession(String uid, FocusSession session) async {
    await FirestorePaths.focusSessions(uid)
        .doc(session.id)
        .set(session.toMap());
  }
}
