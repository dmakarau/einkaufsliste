import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/auth_user.dart';

class AuthRepositoryException implements Exception {
  const AuthRepositoryException(this.message);

  final String message;
}

class AuthRepository {
  const AuthRepository(this._client);

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

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
