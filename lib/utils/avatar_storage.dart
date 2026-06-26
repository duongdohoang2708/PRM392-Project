import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

class AvatarPickException implements Exception {
  final String message;

  AvatarPickException(this.message);

  @override
  String toString() => message;
}

class AvatarStorage {
  AvatarStorage._();

  static const String base64Prefix = 'base64:';
  static const int _maxBytes = 4 * 1024 * 1024;

  static bool isNetworkUrl(String? value) =>
      value != null &&
      (value.startsWith('http://') || value.startsWith('https://'));

  static bool isDeviceAvatar(String? value) =>
      value != null && value.isNotEmpty && !isNetworkUrl(value);

  static bool isLocalFilePath(String? value) =>
      value != null &&
      !kIsWeb &&
      !isNetworkUrl(value) &&
      !value.startsWith(base64Prefix);

  static ImageProvider? imageProvider(String? avatarUrl) {
    if (avatarUrl == null || avatarUrl.isEmpty) return null;
    if (isNetworkUrl(avatarUrl)) return NetworkImage(avatarUrl);
    if (avatarUrl.startsWith(base64Prefix)) {
      return MemoryImage(
        base64Decode(avatarUrl.substring(base64Prefix.length)),
      );
    }
    if (kIsWeb) return NetworkImage(avatarUrl);
    return FileImage(File(avatarUrl));
  }

  static void evictFromCache(String? avatarUrl) {
    final provider = imageProvider(avatarUrl);
    if (provider != null) {
      imageCache.evict(provider);
    }
  }

  static Future<void> _deleteLocalFile(String? path) async {
    if (!isLocalFilePath(path)) return;

    final file = File(path!);
    if (await file.exists()) {
      await file.delete();
    }
    evictFromCache(path);
  }

  static Future<Uint8List> _readPickedBytes(PlatformFile picked) async {
    var bytes = picked.bytes;
    if (bytes != null && bytes.isNotEmpty) {
      return Uint8List.fromList(bytes);
    }

    final path = picked.path;
    if (!kIsWeb && path != null && path.isNotEmpty) {
      final file = File(path);
      if (await file.exists()) {
        bytes = await file.readAsBytes();
        if (bytes.isNotEmpty) return bytes;
      }
    }

    throw AvatarPickException('Could not read the selected image.');
  }

  static Future<String> persistBytes(
    Uint8List bytes, {
    String? replacePath,
  }) async {
    if (bytes.length > _maxBytes) {
      throw AvatarPickException(
        'Image is too large. Please choose a photo under 4 MB.',
      );
    }

    await _deleteLocalFile(replacePath);

    if (kIsWeb) {
      evictFromCache(replacePath);
      return '$base64Prefix${base64Encode(bytes)}';
    }

    final dir = await getApplicationDocumentsDirectory();
    final avatarDir = Directory('${dir.path}/avatars');
    if (!await avatarDir.exists()) {
      await avatarDir.create(recursive: true);
    }

    final destPath =
        '${avatarDir.path}/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(destPath).writeAsBytes(bytes, flush: true);
    return destPath;
  }

  static Future<Uint8List?> pickImageBytesFromGallery() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
      lockParentWindow: true,
    );

    if (result == null || result.files.isEmpty) return null;

    return _readPickedBytes(result.files.single);
  }
}
