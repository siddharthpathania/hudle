import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/supabase_service.dart';

final authRepositoryProvider =
    Provider<AuthRepository>((_) => AuthRepository());

class AuthRepository {
  SupabaseClient get _sb => SupabaseService.client;

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final res = await _sb.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': displayName},
    );
    if (res.user == null) {
      throw Exception('Sign up failed');
    }
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await _sb.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      throw Exception('Google sign-in cancelled');
    }
    final googleAuth = await googleUser.authentication;
    if (googleAuth.idToken == null) {
      throw Exception('Missing Google ID token');
    }

    await fb.FirebaseAuth.instance.signInWithCredential(
      fb.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      ),
    );

    await _sb.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: googleAuth.idToken!,
      accessToken: googleAuth.accessToken,
    );
  }

  Future<void> sendPasswordReset(String email) =>
      _sb.auth.resetPasswordForEmail(email);

  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    try {
      await fb.FirebaseAuth.instance.signOut();
    } catch (_) {/* firebase may not be initialised */}
    await _sb.auth.signOut();
  }

  Stream<AuthState> get authStateChanges => _sb.auth.onAuthStateChange;
}
