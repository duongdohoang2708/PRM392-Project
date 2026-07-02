import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/task_model.dart';
import 'firestore_paths.dart';

class TaskRepository {
  TaskRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(String uid) =>
      FirestorePaths.tasks(uid);

  Stream<List<Task>> watchTasks(String uid) {
    return _collection(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Task.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<void> createTask(String uid, Task task) async {
    await _collection(uid).doc(task.id).set(task.toMap());
  }

  Future<void> updateTask(String uid, Task task) async {
    final data = task.toMap();
    if (!task.hasProject) {
      data['projectId'] = FieldValue.delete();
    }
    await _collection(uid).doc(task.id).update(data);
  }

  Future<void> deleteTask(String uid, String taskId) async {
    await _collection(uid).doc(taskId).delete();
  }

  Future<void> deleteTasksByProjectId(String uid, String projectId) async {
    final snapshot = await _collection(uid)
        .where('projectId', isEqualTo: projectId)
        .get();
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
