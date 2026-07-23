import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/env.dart';
import '../models/app_user_model.dart';

/// Talks directly to Supabase Auth + the `profiles` table. This is the only
/// place in the app that imports `supabase_flutter` auth APIs for
/// authentication concerns — everything above it (repository, use cases,
/// UI) works purely with domain/data models.
class AuthRemoteDataSource {
  AuthRemoteDataSource(this._client);

  final SupabaseClient _client;

  GoTrueClient get _auth => _client.auth;

  Stream<AuthState> get onAuthStateChange => _auth.onAuthStateChange;

  User? get currentSupabaseUser => _auth.currentUser;

  Future<AppUserModel?> fetchProfile(String userId) async {
    final row = await _client.from('profiles').select().eq('id', userId).maybeSingle();
    if (row == null) return null;
    return AppUserModel.fromMap(row);
  }

  Future<AppUserModel> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final response = await _auth.signInWithPassword(email: email, password: password);
    final user = response.user;
    if (user == null) {
      throw const AuthException('Sign in failed. Please try again.');
    }
    return _ensureProfile(user);
  }

  Future<AppUserModel> signUpWithEmailPassword({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final response = await _auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
    final user = response.user;
    if (user == null) {
      throw const AuthException('Registration failed. Please try again.');
    }
    return _ensureProfile(user, fallbackName: fullName);
  }

  /// Google Sign-In via the native Google SDK, exchanged for a Supabase
  /// session using the ID token flow (`signInWithIdToken`). Requires a Web
  /// OAuth client id registered both in Google Cloud Console and in the
  /// Supabase Dashboard (Authentication > Providers > Google) — see
  /// [Env.googleWebClientId] and README.md for the full setup steps.
  Future<AppUserModel> signInWithGoogle() async {
    if (!Env.hasGoogleSignIn) {
      throw const AuthException(
        'Google Sign-In is not configured for this build. Please use email & password, '
        'or ask the maintainer to supply GOOGLE_WEB_CLIENT_ID.',
      );
    }

    final googleSignIn = GoogleSignIn(
      serverClientId: Env.googleWebClientId,
      scopes: const ['email', 'profile'],
    );

    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw const AuthException('Google sign-in was cancelled.');
    }

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    final accessToken = googleAuth.accessToken;

    if (idToken == null) {
      throw const AuthException('Could not retrieve Google ID token. Please try again.');
    }

    final response = await _auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );

    final user = response.user;
    if (user == null) {
      throw const AuthException('Google sign-in failed. Please try again.');
    }

    return _ensureProfile(
      user,
      fallbackName: googleUser.displayName,
      fallbackAvatar: googleUser.photoUrl,
    );
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.resetPasswordForEmail(email);
  }

  Future<void> updatePassword(String newPassword) async {
    await _auth.updateUser(UserAttributes(password: newPassword));
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// The `handle_new_user` Postgres trigger creates a profile row
  /// automatically on sign-up, but we defensively upsert here too in case
  /// the row hasn't propagated yet (e.g. first Google sign-in) or the
  /// trigger is disabled in a given environment.
  Future<AppUserModel> _ensureProfile(User user, {String? fallbackName, String? fallbackAvatar}) async {
    var profile = await fetchProfile(user.id);
    if (profile == null) {
      final inserted = await _client
          .from('profiles')
          .upsert({
            'id': user.id,
            'email': user.email,
            'full_name': fallbackName ?? user.email?.split('@').first ?? 'GoCollab Member',
            'avatar_url': fallbackAvatar,
          })
          .select()
          .single();
      profile = AppUserModel.fromMap(inserted);
    }
    return profile;
  }
}
