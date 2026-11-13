import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Emits the signed-in user (or null) whenever the auth state changes,
/// including when the user returns from the GitHub OAuth flow.
final currentUserProvider = StreamProvider<User?>((ref) async* {
  final auth = ref.watch(authServiceProvider);
  yield auth.currentUser;
  await for (final state in auth.onAuthStateChange) {
    yield state.session?.user;
  }
});
