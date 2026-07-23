import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

/// Exposes the single [SupabaseClient] singleton to every repository via
/// Riverpod — the app's dependency-injection mechanism. Repositories never
/// call `Supabase.instance.client` directly; they depend on this provider,
/// which keeps the data layer testable (swap in a fake client in tests).
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return SupabaseService.client;
});

/// Live stream of Supabase auth state changes (sign in / sign out / token
/// refresh) — the single source of truth the router and session providers
/// listen to for role-based redirects.
final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.auth.onAuthStateChange;
});
