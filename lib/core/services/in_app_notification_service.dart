import 'package:supabase_flutter/supabase_flutter.dart';

/// Creates in-app notification rows in `public.notifications`.
///
/// Database triggers handle most auto-notifications; this service is used as
/// an app-side fallback (e.g. before migrations are applied) and for actions
/// that should refresh the inbox immediately after insert.
class InAppNotificationService {
  InAppNotificationService(this._client);

  final SupabaseClient _client;

  Future<void> notifyEventRegistration({
    required String userId,
    required String eventId,
    required String eventTitle,
  }) async {
    await _insert(
      userId: userId,
      title: 'Registration confirmed',
      body: 'You are registered for $eventTitle.',
      type: 'registration_confirmation',
      referenceType: 'event',
      referenceId: eventId,
    );
  }

  Future<void> _insert({
    required String userId,
    required String title,
    required String body,
    required String type,
    String? referenceType,
    String? referenceId,
  }) async {
    try {
      await _client.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'body': body,
        'type': type,
        if (referenceType != null) 'reference_type': referenceType,
        if (referenceId != null) 'reference_id': referenceId,
      });
    } catch (_) {
      // Non-fatal: registration/announcement already succeeded.
    }
  }
}
