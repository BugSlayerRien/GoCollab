import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  /// Google Sign-In using Supabase's built-in OAuth flow. On web this opens
  /// a redirect to Google's consent page; Supabase handles the token exchange
  /// server-side and redirects back with a valid session.
  Future<void> signInWithGoogle() async {
    await _auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? Uri.base.origin : null,
    );
  }

  /// Sends a password-recovery OTP to the user's email via Supabase Auth.
  Future<void> sendPasswordResetOtp(String email) {
    return _auth.resetPasswordForEmail(email);
  }

  /// Verifies the 6-digit OTP and establishes a recovery session.
  Future<void> verifyPasswordOtp({required String email, required String token}) async {
    await _auth.verifyOTP(type: OtpType.recovery, email: email, token: token);
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
