import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/data/models/app_user_model.dart';
import '../../domain/entities/event_history_item.dart';

class ProfileRemoteDataSource {
  ProfileRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<AppUserModel> updateProfile(String userId, Map<String, dynamic> updates) async {
    final row = await _client.from('profiles').update(updates).eq('id', userId).select().single();
    return AppUserModel.fromMap(row);
  }

  Future<List<EventHistoryItem>> getEventHistory(String userId) async {
    final rows = await _client
        .from('event_registrations')
        .select('event_id, status, events(title, start_at)')
        .eq('user_id', userId)
        .neq('status', 'cancelled')
        .order('registered_at', ascending: false);

    final certificateRows = await _client
        .from('certificates')
        .select('event_id, certificate_url, certificate_number')
        .eq('user_id', userId);

    final certByEvent = <String, Map<String, dynamic>>{
      for (final c in certificateRows as List) c['event_id'] as String: c as Map<String, dynamic>,
    };

    return (rows as List).where((r) => r['events'] != null).map((r) {
      final event = r['events'] as Map<String, dynamic>;
      final cert = certByEvent[r['event_id']];
      return EventHistoryItem(
        eventId: r['event_id'] as String,
        eventTitle: event['title'] as String,
        eventDate: DateTime.parse(event['start_at'] as String),
        attended: r['status'] == 'attended',
        certificateUrl: cert?['certificate_url'] as String?,
        certificateNumber: cert?['certificate_number'] as String?,
      );
    }).toList();
  }
}
