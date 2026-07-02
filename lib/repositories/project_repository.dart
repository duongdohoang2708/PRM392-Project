import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/project_model.dart';
import 'firestore_paths.dart';

class ProjectRepository {
  ProjectRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(String uid) =>
      FirestorePaths.projects(uid);

  Stream<List<Project>> watchProjects(String uid) {
    return _collection(uid)
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Project.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<void> createProject(String uid, Project project) async {
    await _collection(uid).doc(project.id).set(project.toMap());
  }

  Future<void> updateProject(String uid, Project project) async {
    await _collection(uid).doc(project.id).update(project.toMap());
  }

  Future<void> deleteProject(String uid, String projectId) async {
    await _collection(uid).doc(projectId).delete();
  }
}
