/// Centralized environment/configuration access point.
///
/// Values are supplied at build time via `--dart-define-from-file=env.json`
/// (see `env.example.json` in the repo root) or individual `--dart-define`
/// flags. Supabase's project URL and publishable (anon) key are safe to ship
/// inside the client binary by design — they are NOT secrets — so sensible
/// defaults are provided for local development and grading convenience.
///
/// Keys that ARE sensitive (OAuth client secrets, service-role keys) must
/// never be placed here; they belong on the server / Supabase Edge Functions.
class Env {
  Env._();

  /// Supabase project REST/Auth/Realtime endpoint.
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://nhuoziavgyxtcutmygtl.supabase.co',
  );

  /// Supabase publishable (anon) key — safe for client-side use, protected
  /// by Row Level Security policies on every table.
  static const String supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_0dTO5gPz68bTVW_2xxrs1A_t7qjZk_r',
  );

  /// OAuth 2.0 Web Client ID used by `google_sign_in` so Supabase can verify
  /// the Google ID token server-side. Create this in Google Cloud Console
  /// (APIs & Services > Credentials > OAuth client ID > Web application) and
  /// register it under Supabase Dashboard > Authentication > Providers >
  /// Google. Left blank by default so the app still builds/runs without it;
  /// the Google Sign-In button will surface a friendly "not configured"
  /// message instead of crashing.
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '',
  );

  /// Google Maps SDK API key. Required for the Events venue map and the
  /// Partner Directory map. Configure in Google Cloud Console and inject via
  /// --dart-define plus the native AndroidManifest.xml / Info.plist
  /// placeholders documented in README.md.
  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );

  /// Firebase project sender id — used only for diagnostics; the real
  /// Firebase config lives in `firebase_options.dart` (generated via
  /// `flutterfire configure`, see README.md).
  static const String firebaseSenderId = String.fromEnvironment(
    'FIREBASE_SENDER_ID',
    defaultValue: '',
  );

  static bool get hasGoogleSignIn => googleWebClientId.isNotEmpty;

  static bool get hasGoogleMaps => googleMapsApiKey.isNotEmpty;
}
