import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthTokens {
  final String idToken;
  final String? accessToken;

  const GoogleAuthTokens({
    required this.idToken,
    this.accessToken,
  });
}

class GoogleAuthService {
  GoogleAuthService._();

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const ['email', 'profile'],
  );

  static Future<GoogleAuthTokens?> signIn() async {
    // Clear cached account so the Google account picker is shown.
    await _googleSignIn.signOut();

    final account = await _googleSignIn.signIn();
    if (account == null) return null;

    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null) {
      throw StateError('Google Sign-In did not return an ID token.');
    }

    return GoogleAuthTokens(
      idToken: idToken,
      accessToken: auth.accessToken,
    );
  }

  static Future<void> signOut() => _googleSignIn.signOut();

  /// Fully clears the Google session so a different account can be chosen later.
  static Future<void> signOutCompletely() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    try {
      await _googleSignIn.disconnect();
    } catch (_) {}
  }
}
