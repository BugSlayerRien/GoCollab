import 'package:supabase_flutter/supabase_flutter.dart';

/// Manages the `gcal_event_sync` table — the mapping between GoCollab
/// event IDs and Google Calendar event IDs, scoped per user.
class GcalDataSource {
  GcalDataSource(this._client);

  final SupabaseClient _client;

  Future<String?> getGcalEventId({required String userId, required String eventId}) async {
    final row = await _client
        .from('gcal_event_sync')
        .select('gcal_event_id')
        .eq('user_id', userId)
        .eq('event_id', eventId)
        .maybeSingle();
    return row?['gcal_event_id'] as String?;
  }

  Future<void> saveGcalEventId({
    required String userId,
    required String eventId,
    required String gcalEventId,
  }) async {
    await _client.from('gcal_event_sync').upsert({
      'user_id': userId,
      'event_id': eventId,
      'gcal_event_id': gcalEventId,
      'synced_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id,event_id');
  }

  Future<void> deleteGcalEventId({required String userId, required String eventId}) async {
    await _client
        .from('gcal_event_sync')
        .delete()
        .eq('user_id', userId)
        .eq('event_id', eventId);
  }

  /// Returns Google Calendar event IDs synced from GoCollab for [userId].
  /// Map key = `gcal_event_id`, value = GoCollab `event_id`.
  Future<Map<String, String>> listUserGcalMappings(String userId) async {
    final rows = await _client
        .from('gcal_event_sync')
        .select('gcal_event_id, event_id')
        .eq('user_id', userId);
    final mappings = <String, String>{};
    for (final row in rows as List) {
      final gcalId = row['gcal_event_id'] as String?;
      final eventId = row['event_id'] as String?;
      if (gcalId != null && eventId != null) {
        mappings[gcalId] = eventId;
      }
    }
    return mappings;
  }
}
