import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  // Update this URL after deploying reset-web/ to Vercel.
  static const _resetRedirectUrl = 'https://hudle-delta.vercel.app/';

  Future<void> sendPasswordReset(String email) =>
      _sb.auth.resetPasswordForEmail(email, redirectTo: _resetRedirectUrl);

  Future<void> signOut() => _sb.auth.signOut();

  Stream<AuthState> get authStateChanges => _sb.auth.onAuthStateChange;
}
