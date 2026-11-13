import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Deep link the OAuth provider sends the user back to on mobile.
/// Must also be added under Supabase > Authentication > URL Configuration >
/// Redirect URLs, and is registered in AndroidManifest.xml / Info.plist.
const oauthRedirectUrl = 'io.supabase.reniacc://login-callback/';

/// Thin wrapper around Supabase Auth.
///
/// Supports email/password (Supabase's built-in provider) plus GitHub as the
/// additional third-party OAuth provider.
class AuthService {
  AuthService([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  GoTrueClient get _auth => _client.auth;

  User? get currentUser => _auth.currentUser;

  Stream<AuthState> get onAuthStateChange => _auth.onAuthStateChange;

  Future<void> signInWithEmail(String email, String password) =>
      _auth.signInWithPassword(email: email, password: password);

  /// Returns true if the user is signed in right away, false if Supabase
  /// requires them to confirm their email first.
  Future<bool> signUpWithEmail(String email, String password) async {
    final res = await _auth.signUp(email: email, password: password);
    return res.session != null;
  }

  /// Opens GitHub's consent page. On web the page redirects back to the app's
  /// own URL; on mobile it returns through [oauthRedirectUrl].
  Future<void> signInWithGitHub() => _auth.signInWithOAuth(
        OAuthProvider.github,
        redirectTo: kIsWeb ? null : oauthRedirectUrl,
        authScreenLaunchMode: kIsWeb
            ? LaunchMode.platformDefault
            : LaunchMode.externalApplication,
      );

  Future<void> signOut() => _auth.signOut();
}
