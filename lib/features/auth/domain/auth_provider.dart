import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/auth_repository.dart';

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>(
  (ref) => AuthController(ref.read(authRepositoryProvider)),
);

class AuthController extends StateNotifier<AsyncValue<void>> {
  AuthController(this._repo) : super(const AsyncData(null));

  final AuthRepository _repo;

  Future<void> signInWithEmail(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repo.signInWithEmail(email: email, password: password),
    );
  }

  Future<void> signUpWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repo.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      ),
    );
  }

  Future<void> signOut() async {
    await _repo.signOut();
  }
}
