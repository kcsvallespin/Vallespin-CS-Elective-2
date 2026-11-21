import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;

import '../models/profile.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final profileServiceProvider =
    Provider<ProfileService>((ref) => ProfileService());

/// Emits the signed-in user (or null) whenever the auth state changes,
/// including when the user returns from the Google OAuth flow.
final currentUserProvider = StreamProvider<User?>((ref) async* {
  final auth = ref.watch(authServiceProvider);
  yield auth.currentUser;
  await for (final state in auth.onAuthStateChange) {
    yield state.session?.user;
  }
});

/// The signed-in user's id. Only changes on sign-in / sign-out (not on token
/// refreshes), so per-user state such as the cart can safely watch it.
final currentUserIdProvider = Provider<String?>(
  (ref) => ref.watch(currentUserProvider).valueOrNull?.id,
);

/// The signed-in user's profile, including their role.
final profileProvider = FutureProvider<Profile?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;
  return ref.watch(profileServiceProvider).fetchProfile(userId);
});

final isAdminProvider = Provider<bool>(
  (ref) => ref.watch(profileProvider).valueOrNull?.isAdmin ?? false,
);

/// Sign-in / sign-up / sign-out actions. The state is loading while a
/// request runs and holds the error if it failed, so screens can show a
/// spinner and an error message without calling Supabase themselves.
final authControllerProvider =
    AsyncNotifierProvider<AuthController, void>(AuthController.new);

class AuthController extends AsyncNotifier<void> {
  AuthService get _auth => ref.read(authServiceProvider);

  @override
  FutureOr<void> build() {}

  Future<bool> signIn(String email, String password) =>
      _run(() => _auth.signInWithEmail(email, password));

  /// Returns true if signed in right away, false if email confirmation is
  /// required, or null if sign-up failed.
  Future<bool?> signUp({
    required String email,
    required String password,
    required String firstname,
    required String lastname,
  }) async {
    var signedIn = false;
    final ok = await _run(() async {
      signedIn = await _auth.signUpWithEmail(
        email: email,
        password: password,
        firstname: firstname,
        lastname: lastname,
      );
    });
    return ok ? signedIn : null;
  }

  Future<bool> signInWithGoogle() => _run(_auth.signInWithGoogle);

  Future<bool> signOut() => _run(_auth.signOut);

  Future<bool> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(action);
    return !state.hasError;
  }
}
