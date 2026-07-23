import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/event_model.dart';

class EventRemoteDataSource {
  EventRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<List<EventModel>> getEvents({String? currentUserId}) async {
    final rows = await _client.from('events').select().order('start_at');

    final registrationRows = await _client
        .from('event_registrations')
        .select('event_id, user_id, status, qr_code')
        .neq('status', 'cancelled');

    final countsByEvent = <String, int>{};
    final myRegistrationByEvent = <String, Map<String, dynamic>>{};
    for (final r in registrationRows as List) {
      final eventId = r['event_id'] as String;
      countsByEvent[eventId] = (countsByEvent[eventId] ?? 0) + 1;
      if (currentUserId != null && r['user_id'] == currentUserId) {
        myRegistrationByEvent[eventId] = r as Map<String, dynamic>;
      }
    }

    return (rows as List)
        .map((row) => EventModel.fromMap(
              row as Map<String, dynamic>,
              registeredCount: countsByEvent[row['id']] ?? 0,
              registration: myRegistrationByEvent[row['id']],
            ))
        .toList();
  }

  Future<EventModel> getEventById(String id, {String? currentUserId}) async {
    final row = await _client.from('events').select().eq('id', id).single();

    final registrationRows = await _client
        .from('event_registrations')
        .select('user_id, status, qr_code')
        .eq('event_id', id)
        .neq('status', 'cancelled');

    Map<String, dynamic>? myRegistration;
    if (currentUserId != null) {
      for (final r in registrationRows as List) {
        if (r['user_id'] == currentUserId) {
          myRegistration = r as Map<String, dynamic>;
          break;
        }
      }
    }

    return EventModel.fromMap(
      row,
      registeredCount: (registrationRows).length,
      registration: myRegistration,
    );
  }

  Future<void> registerForEvent({required String eventId, required String userId}) async {
    await _client.from('event_registrations').upsert({
      'event_id': eventId,
      'user_id': userId,
      'status': 'registered',
    }, onConflict: 'event_id,user_id');

    await _client.from('engagement_logs').insert({
      'user_id': userId,
      'action_type': 'event_register',
      'reference_type': 'event',
      'reference_id': eventId,
    });
  }

  Future<void> cancelRegistration({required String eventId, required String userId}) async {
    await _client
        .from('event_registrations')
        .update({'status': 'cancelled', 'cancelled_at': DateTime.now().toIso8601String()})
        .eq('event_id', eventId)
        .eq('user_id', userId);
  }

  Future<String> checkInWithQrCode({
    required String eventId,
    required String qrCode,
    required String officerId,
  }) async {
    final registration = await _client
        .from('event_registrations')
        .select('id, user_id, status')
        .eq('event_id', eventId)
        .eq('qr_code', qrCode)
        .maybeSingle();

    if (registration == null) {
      throw Exception('This QR code is not registered for this event.');
    }
    if (registration['status'] == 'cancelled') {
      throw Exception('This registration was cancelled.');
    }

    final userId = registration['user_id'] as String;

    final alreadyCheckedIn = await _client
        .from('attendance')
        .select('id')
        .eq('event_id', eventId)
        .eq('user_id', userId)
        .maybeSingle();

    final profile = await _client.from('profiles').select('full_name').eq('id', userId).single();
    final name = profile['full_name'] as String? ?? 'Attendee';

    if (alreadyCheckedIn != null) {
      throw Exception('$name has already checked in.');
    }

    await _client.from('attendance').insert({
      'event_id': eventId,
      'user_id': userId,
      'registration_id': registration['id'],
      'checked_in_by': officerId,
      'method': 'qr',
    });

    await _client
        .from('event_registrations')
        .update({'status': 'attended'})
        .eq('id', registration['id']);

    await _client.from('engagement_logs').insert({
      'user_id': userId,
      'action_type': 'event_attend',
      'reference_type': 'event',
      'reference_id': eventId,
    });

    return name;
  }
}
