import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

/// Result from a social sign-in attempt.
class SocialAuthResult {
  final String idToken;
  final String? name;
  final String? email;
  final String? avatarUrl;

  const SocialAuthResult({
    required this.idToken,
    this.name,
    this.email,
    this.avatarUrl,
  });
}

/// Handles the native OS-level OAuth flow for Google.
/// Call [signInWithGoogle] and pass the result straight to
/// [AuthProvider.signInWithGoogle].
class AuthService {
  static final AuthService _instance = AuthService._();
  factory AuthService() => _instance;
  AuthService._();

  // ─── Google ───────────────────────────────────────────────────────────────

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId:
        '601731908423-6cj4851hqklbsk73heret3k13gp6hp22.apps.googleusercontent.com',
  );

  /// Triggers the Google sign-in sheet.
  /// Returns [SocialAuthResult] on success, or throws [SocialAuthException].
  Future<SocialAuthResult> signInWithGoogle() async {
    try {
      // Sign out first to always show the account picker.
      await _googleSignIn.signOut();

      final account = await _googleSignIn.signIn();
      if (account == null) throw SocialAuthException.cancelled();

      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        debugPrint('Google did not return an ID token. ');
        debugPrint(
            'Make sure SHA-1/SHA-256 fingerprints are registered in Firebase.');
        throw SocialAuthException(
          'Google did not return an ID token. '
          'Make sure SHA-1/SHA-256 fingerprints are registered in Firebase.',
        );
      }

      return SocialAuthResult(
        idToken: idToken,
        name: account.displayName,
        email: account.email,
        avatarUrl: account.photoUrl,
      );
    } on SocialAuthException {
      rethrow;
    } catch (e, stack) {
      debugPrint('=== Google Sign-In Error ===');
      debugPrint('Type: ${e.runtimeType}');
      debugPrint('Error: $e');
      debugPrint('Stack: $stack');
      throw SocialAuthException('Google sign-in failed: $e');
    }
  }
}

// ─── Exception ────────────────────────────────────────────────────────────────

class SocialAuthException implements Exception {
  final String message;
  final bool cancelled;

  const SocialAuthException(this.message, {this.cancelled = false});
  const SocialAuthException.cancelled()
      : message = 'Sign-in was cancelled.',
        cancelled = true;

  @override
  String toString() => 'SocialAuthException: $message';
}
