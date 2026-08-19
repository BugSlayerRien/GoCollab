import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Persists Google OAuth tokens from Supabase sessions.
///
/// Supabase only includes [Session.providerToken] on the initial OAuth exchange;
/// later [refreshSession] calls often drop it. We cache the token locally so
/// Calendar API calls keep working across app restarts.
class GoogleTokenStorage {
  GoogleTokenStorage._();

  static String _tokenKey(String userId) => 'google_provider_token:$userId';
  static String _refreshKey(String userId) => 'google_provider_refresh_token:$userId';

  static Future<void> saveFromSession(Session session) async {
    final token = session.providerToken;
    final refresh = session.providerRefreshToken;
    if ((token == null || token.isEmpty) && (refresh == null || refresh.isEmpty)) {
      return;
    }
    await save(
      userId: session.user.id,
      token: token,
      refreshToken: refresh,
    );
  }

  static Future<void> save({
    required String userId,
    String? token,
    String? refreshToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (token != null && token.isNotEmpty) {
      await prefs.setString(_tokenKey(userId), token);
    }
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await prefs.setString(_refreshKey(userId), refreshToken);
    }
  }

  static Future<String?> getToken(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey(userId));
  }

  static Future<String?> getRefreshToken(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshKey(userId));
  }

  static Future<void> clear(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey(userId));
    await prefs.remove(_refreshKey(userId));
  }
}
