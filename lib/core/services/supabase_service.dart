import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';
import 'web_url_cleaner_stub.dart'
    if (dart.library.html) 'web_url_cleaner_web.dart';

/// Thin wrapper around Supabase initialization so `main.dart` stays
/// declarative. Called once before `runApp`.
class SupabaseService {
  SupabaseService._();

  /// Set to `true` after a password-recovery PKCE callback is exchanged.
  static bool pendingPasswordRecovery = false;

  /// Non-null when the auth URL callback failed (e.g. missing PKCE verifier).
  static String? authCallbackError;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      publishableKey: Env.supabasePublishableKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        // We exchange `?code=` explicitly in [handleWebAuthCallback] before runApp.
        detectSessionInUri: false,
      ),
      realtimeClientOptions: const RealtimeClientOptions(
        eventsPerSecond: 5,
      ),
    );

    await handleWebAuthCallback();
  }

  /// Exchanges `?code=` (PKCE) or hash tokens from Supabase auth redirects.
  /// Must run before [runApp] so the router sees a recovery session.
  static Future<void> handleWebAuthCallback() async {
    if (!kIsWeb) return;

    final uri = Uri.base;
    final hasCode = uri.queryParameters.containsKey('code');
    final hasToken =
        uri.queryParameters.containsKey('access_token') || uri.fragment.contains('access_token');
    if (!hasCode && !hasToken) return;

    try {
      final response = await client.auth.getSessionFromUrl(uri);
      final type = response.redirectType;
      pendingPasswordRecovery = type == AuthChangeEvent.passwordRecovery.name ||
          type == 'recovery' ||
          type == 'PASSWORD_RECOVERY';
      authCallbackError = null;
      clearAuthParamsFromBrowserUrl();
    } on AuthException catch (e) {
      authCallbackError = e.message.contains('Code verifier')
          ? 'This reset link must be opened in the same browser where you requested it. '
              'Go to Forgot password, send a new link, then open it here without switching browsers.'
          : e.message;
      debugPrint('[SupabaseService] Auth callback failed: ${e.message}');
    } catch (e, st) {
      authCallbackError = e.toString();
      debugPrint('[SupabaseService] Auth callback failed: $e\n$st');
    }
  }

  static SupabaseClient get client => Supabase.instance.client;
}
