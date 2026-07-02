import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../repositories/auth_repository.dart';
import '../repositories/user_repository.dart';
import '../repositories/storage_repository.dart';
import '../utils/avatar_storage.dart';
import '../services/google_auth_service.dart';

class UserProvider with ChangeNotifier {
  UserProvider({
    AuthRepository? authRepository,
    UserRepository? userRepository,
    StorageRepository? storageRepository,
  })  : _authRepository = authRepository ?? AuthRepository(),
        _userRepository = userRepository ?? UserRepository(),
        _storageRepository = storageRepository ?? StorageRepository();

  final AuthRepository _authRepository;
  final UserRepository _userRepository;
  final StorageRepository _storageRepository;

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<UserProfile?>? _profileSubscription;

  User? _firebaseUser;
  String _fullName = '';
  String _email = '';
  String? _avatarUrl;
  bool _loaded = false;

  User? get firebaseUser => _firebaseUser;
  String? get uid => _firebaseUser?.uid;
  bool get isAuthenticated => _firebaseUser != null;
  String get fullName => _fullName.isNotEmpty ? _fullName : 'User';
  String get email => _email;
  String? get avatarUrl => _avatarUrl;
  bool get isLoaded => _loaded;

  String get initials {
    final parts = _fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Future<void> load() async {
    _authSubscription?.cancel();
    _authSubscription = _authRepository.authStateChanges().listen(_onAuthChanged);
    _onAuthChanged(_authRepository.currentUser);
  }

  void _onAuthChanged(User? user) {
    _firebaseUser = user;
    _profileSubscription?.cancel();
    _profileSubscription = null;

    if (user == null) {
      _fullName = '';
      _email = '';
      _avatarUrl = null;
      _loaded = true;
      notifyListeners();
      return;
    }

    _email = user.email ?? '';
    _profileSubscription = _userRepository.watchProfile(user.uid).listen((profile) {
      if (profile != null) {
        _fullName = profile.fullName;
        _email = profile.email;
        _avatarUrl = profile.avatarUrl;
      } else {
        _fullName = user.displayName ?? _deriveNameFromEmail(user.email);
        _email = user.email ?? '';
      }
      _loaded = true;
      notifyListeners();
    });
  }

  String _deriveNameFromEmail(String? email) {
    if (email == null || !email.contains('@')) return 'User';
    final local = email.split('@').first;
    if (local.isEmpty) return 'User';
    return local[0].toUpperCase() + local.substring(1);
  }

  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _authRepository.signInWithEmail(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return _mapAuthError(e);
    }
  }

  Future<String?> signUp({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final trimmedName = fullName.trim();
    if (trimmedName.isEmpty) return 'Full name is required.';
    if (password.length < 6) return 'Password must be at least 6 characters.';
    if (password != confirmPassword) return 'Passwords do not match.';

    try {
      final credential = await _authRepository.signUpWithEmail(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user != null) {
        await user.updateDisplayName(trimmedName);
        await _userRepository.createProfile(
          uid: user.uid,
          fullName: trimmedName,
          email: email.trim(),
        );
      }
      return null;
    } on FirebaseAuthException catch (e) {
      return _mapAuthError(e);
    }
  }

  Future<String?> sendPasswordReset(String email) async {
    if (email.trim().isEmpty) return 'Email is required.';
    try {
      await _authRepository.sendPasswordResetEmail(email);
      return null;
    } on FirebaseAuthException catch (e) {
      return _mapAuthError(e);
    }
  }

  Future<void> signOut() async {
    await Future.wait([
      _authRepository.signOut(),
      GoogleAuthService.signOutCompletely(),
    ]);
  }

  Future<void> updateAvatar(String? avatarUrl) async {
    final uid = this.uid;
    if (uid == null) return;

    final previous = _avatarUrl;
    _avatarUrl = avatarUrl == null || avatarUrl.isEmpty ? null : avatarUrl;

    await _userRepository.updateProfile(uid: uid, avatarUrl: _avatarUrl);

    if (previous != null && previous != _avatarUrl) {
      AvatarStorage.evictFromCache(previous);
    }

    notifyListeners();
  }

  Future<void> updateProfile({
    required String fullName,
    String? avatarUrl,
  }) async {
    final uid = this.uid;
    if (uid == null) return;

    final trimmed = fullName.trim();
    if (trimmed.isEmpty) return;

    _fullName = trimmed;
    if (avatarUrl != null) {
      _avatarUrl = avatarUrl.isEmpty ? null : avatarUrl;
    }

    await _userRepository.updateProfile(
      uid: uid,
      fullName: _fullName,
      avatarUrl: _avatarUrl,
    );
    await _firebaseUser?.updateDisplayName(_fullName);
    notifyListeners();
  }

  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (currentPassword.isEmpty) return 'Current password is required.';
    if (newPassword.length < 6) {
      return 'New password must be at least 6 characters.';
    }
    if (newPassword != confirmPassword) return 'Passwords do not match.';

    try {
      await _authRepository.updatePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return _mapAuthError(e);
    }
  }

  Future<String?> uploadAvatarBytes({
    required List<int> bytes,
    required String contentType,
  }) async {
    final uid = this.uid;
    if (uid == null) return 'You must be signed in to upload an avatar.';

    try {
      final url = await _storageRepository.uploadUserAvatar(
        uid: uid,
        bytes: bytes,
        contentType: contentType,
      );
      await updateAvatar(url);
      return null;
    } catch (_) {
      return 'Failed to upload avatar.';
    }
  }

  Future<String?> signInWithGoogle({
    required String idToken,
    String? accessToken,
  }) async {
    try {
      final credential = await _authRepository.signInWithGoogle(
        idToken: idToken,
        accessToken: accessToken,
      );
      final user = credential.user;
      if (user != null) {
        final existing = await _userRepository.fetchProfile(user.uid);
        if (existing == null) {
          await _userRepository.createProfile(
            uid: user.uid,
            fullName: user.displayName ?? _deriveNameFromEmail(user.email),
            email: user.email ?? '',
            avatarUrl: user.photoURL,
          );
        }
      }
      return null;
    } on FirebaseAuthException catch (e) {
      return _mapAuthError(e);
    }
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return e.message ?? 'Authentication failed.';
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _profileSubscription?.cancel();
    super.dispose();
  }
}
