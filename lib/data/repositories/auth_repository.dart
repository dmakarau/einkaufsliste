import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/supabase_config.dart';
import '../models/auth_user.dart';

class AuthRepositoryException implements Exception {
  const AuthRepositoryException(this.message);

  final String message;
}

class AuthRepositoryCancelledException implements Exception {
  const AuthRepositoryCancelledException();
}

class AuthRepository {
  const AuthRepository(this._client);

  static Future<void> initialize() async {
    await GoogleSignIn.instance.initialize(
      serverClientId: SupabaseConfig.googleWebClientId,
      clientId: SupabaseConfig.googleIosClientId,
    );
  }

  final SupabaseClient _client;

  AppUser? get currentUser {
    final u = _client.auth.currentUser;
    if (u == null) return null;
    return AppUser(id: u.id, email: u.email);
  }

  Stream<AppUser?> get authStateStream =>
      _client.auth.onAuthStateChange.map((event) {
        final u = event.session?.user;
        if (u == null) return null;
        return AppUser(id: u.id, email: u.email);
      });

  Future<void> signUp({required String email, required String password}) async {
    try {
      await _client.auth.signUp(email: email, password: password);
    } on AuthException catch (e) {
      throw AuthRepositoryException(e.message);
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (e) {
      throw AuthRepositoryException(e.message);
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      GoogleSignInAccount? googleUser = await GoogleSignIn.instance
          .attemptLightweightAuthentication();
      googleUser ??= await GoogleSignIn.instance.authenticate();

      final idToken = googleUser.authentication.idToken;
      if (idToken == null) {
        throw const AuthRepositoryException('No ID token received from Google');
      }

      await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted ||
          e.code == GoogleSignInExceptionCode.uiUnavailable) {
        throw const AuthRepositoryCancelledException();
      }
      throw AuthRepositoryException(e.toString());
    } on AuthException catch (e) {
      throw AuthRepositoryException(e.message);
    } catch (e) {
      throw AuthRepositoryException(e.toString());
    }
  }

  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Best-effort — Google session revocation must not block Supabase sign-out.
    }
    await _client.auth.signOut();
  }
}
