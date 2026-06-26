import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/avatar_storage.dart';

class UserProvider with ChangeNotifier {
  static const String _nameKey = 'user_full_name';
  static const String _emailKey = 'user_email';
  static const String _avatarKey = 'user_avatar_url';
  static const String _mockPassword = 'password123';

  static const String defaultName = 'Dương';
  static const String defaultEmail = 'duong@taskflow.app';

  String _fullName = defaultName;
  String _email = defaultEmail;
  String? _avatarUrl;
  bool _loaded = false;

  String get fullName => _fullName;
  String get email => _email;
  String? get avatarUrl => _avatarUrl;
  bool get isLoaded => _loaded;

  String get initials {
    final parts = _fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.isNotEmpty ? parts.first[0].toUpperCase() : '?';
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _fullName = prefs.getString(_nameKey) ?? defaultName;
    _email = prefs.getString(_emailKey) ?? defaultEmail;
    _avatarUrl = prefs.getString(_avatarKey);
    _loaded = true;
    notifyListeners();
  }

  Future<void> updateAvatar(String? avatarUrl) async {
    final previous = _avatarUrl;
    _avatarUrl = avatarUrl == null || avatarUrl.isEmpty ? null : avatarUrl;

    final prefs = await SharedPreferences.getInstance();
    if (_avatarUrl != null) {
      await prefs.setString(_avatarKey, _avatarUrl!);
    } else {
      await prefs.remove(_avatarKey);
    }

    if (previous != null && previous != _avatarUrl) {
      AvatarStorage.evictFromCache(previous);
    }

    notifyListeners();
  }

  Future<void> updateProfile({
    required String fullName,
    String? avatarUrl,
  }) async {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) return;

    _fullName = trimmed;
    if (avatarUrl != null) {
      _avatarUrl = avatarUrl.isEmpty ? null : avatarUrl;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, _fullName);
    await prefs.setString(_emailKey, _email);
    if (_avatarUrl != null) {
      await prefs.setString(_avatarKey, _avatarUrl!);
    } else {
      await prefs.remove(_avatarKey);
    }
    notifyListeners();
  }

  /// Mock password change — validates against [_mockPassword].
  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (currentPassword.isEmpty) {
      return 'Current password is required.';
    }
    if (currentPassword != _mockPassword) {
      return 'Current password is incorrect.';
    }
    if (newPassword.length < 6) {
      return 'New password must be at least 6 characters.';
    }
    if (newPassword != confirmPassword) {
      return 'Passwords do not match.';
    }
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return null;
  }
}
