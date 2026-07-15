import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

class StorageRepository {
  StorageRepository({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  Future<String> uploadUserAvatar({
    required String uid,
    required List<int> bytes,
    required String contentType,
  }) async {
    final ref = _storage.ref().child('users/$uid/avatar.jpg');
    await ref.putData(
      Uint8List.fromList(bytes),
      SettableMetadata(contentType: contentType),
    );
    return ref.getDownloadURL();
  }

  Future<String> uploadUserAvatarFile({
    required String uid,
    required String filePath,
    required String contentType,
  }) async {
    final ref = _storage.ref().child('users/$uid/avatar.jpg');
    final file = File(filePath);
    await ref.putFile(
      file,
      SettableMetadata(contentType: contentType),
    );
    return ref.getDownloadURL();
  }

  Future<void> deleteUserAvatar(String uid) async {
    final ref = _storage.ref().child('users/$uid/avatar.jpg');
    try {
      await ref.delete();
    } on FirebaseException catch (e) {
      if (e.code != 'object-not-found') rethrow;
    }
  }
}
