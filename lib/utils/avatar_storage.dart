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

  static String? documentDirPath;

  static const String base64Prefix = 'base64:';
  static const int _maxBytes = 8 * 1024 * 1024;

  static bool isNetworkUrl(String? value) =>
      value != null &&
      (value.startsWith('http://') || value.startsWith('https://'));

  static bool isAssetUrl(String? value) =>
      value != null && value.startsWith('assets/');

  static bool isDeviceAvatar(String? value) =>
      value != null && value.isNotEmpty && !isNetworkUrl(value) && !isAssetUrl(value);

  static bool isLocalFilePath(String? value) =>
      value != null &&
      !kIsWeb &&
      !isNetworkUrl(value) &&
      !isAssetUrl(value) &&
      !value.startsWith(base64Prefix);

  static String? _getCachePath(String url) {
    if (documentDirPath == null) return null;
    final cleanUrl = url.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final filename = cleanUrl.length > 100 
        ? '${cleanUrl.substring(0, 100)}_${url.hashCode}'
        : cleanUrl;
    return '$documentDirPath/avatars/cache_$filename.jpg';
  }

  static void _cacheNetworkImageInBackground(String url, String cachePath) {
    Future.microtask(() async {
      try {
        final file = File(cachePath);
        if (await file.exists()) return;

        final parent = file.parent;
        if (!await parent.exists()) {
          await parent.create(recursive: true);
        }

        final client = HttpClient();
        client.connectionTimeout = const Duration(seconds: 5);
        final request = await client.getUrl(Uri.parse(url));
        final response = await request.close();
        
        if (response.statusCode == 200) {
          final bytes = await response.fold<List<int>>([], (p, e) => p..addAll(e));
          if (bytes.isNotEmpty) {
            await file.writeAsBytes(bytes, flush: true);
          }
        }
      } catch (_) {
        // Ignore background cache errors
      }
    });
  }

  static ImageProvider? imageProvider(String? avatarUrl) {
    if (avatarUrl == null || avatarUrl.isEmpty) return null;
    if (isNetworkUrl(avatarUrl)) {
      final cachePath = _getCachePath(avatarUrl);
      if (cachePath != null && File(cachePath).existsSync()) {
        return FileImage(File(cachePath));
      }
      if (cachePath != null) {
        _cacheNetworkImageInBackground(avatarUrl, cachePath);
      }
      return NetworkImage(avatarUrl);
    }
    if (avatarUrl.startsWith('assets/')) {
      return AssetImage(avatarUrl);
    }
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
        'Image is too large. Please choose a photo under 8 MB.',
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
