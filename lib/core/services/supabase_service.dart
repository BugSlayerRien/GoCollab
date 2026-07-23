import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/env.dart';

/// Thin wrapper around Supabase initialization so `main.dart` stays
/// declarative. Called once before `runApp`.
class SupabaseService {
  SupabaseService._();

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      publishableKey: Env.supabasePublishableKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
      realtimeClientOptions: const RealtimeClientOptions(
        eventsPerSecond: 5,
      ),
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
