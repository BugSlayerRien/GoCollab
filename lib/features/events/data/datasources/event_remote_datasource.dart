import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/event.dart';
import '../../domain/entities/event_attendee.dart';
import '../models/event_model.dart';

class EventRemoteDataSource {
  EventRemoteDataSource(this._client);

  final SupabaseClient _client;

  static const _eventSelect =
      '*, creator:profiles!events_created_by_fkey(id, full_name, avatar_url)';

  /// `partners` is officer-only (contact details), so members read the
  /// promotional columns through the `partner_public` view instead.
  Future<Map<String, Map<String, dynamic>>> _partnersById(Iterable<String> ids) async {
    final unique = ids.toSet().toList();
    if (unique.isEmpty) return {};
    final rows = await _client
        .from('partner_public')
        .select('id, name, logo_url, description, website')
        .inFilter('id', unique);
    return {for (final r in rows as List) r['id'] as String: r as Map<String, dynamic>};
  }

  Future<List<EventModel>> getEvents({String? currentUserId}) async {
    final rows = await _client.from('events').select(_eventSelect).order('start_at');

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

    final partners = await _partnersById(
      (rows as List).map((r) => r['partner_id']).whereType<String>(),
    );

    return rows
        .map((row) => EventModel.fromMap(
              {...row, 'partner': partners[row['partner_id']]},
              registeredCount: countsByEvent[row['id']] ?? 0,
              registration: myRegistrationByEvent[row['id']],
            ))
        .toList();
  }

  Future<EventModel> getEventById(String id, {String? currentUserId}) async {
    final row = await _client.from('events').select(_eventSelect).eq('id', id).single();

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

    final partnerId = row['partner_id'] as String?;
    final partners = await _partnersById([?partnerId]);

    return EventModel.fromMap(
      {...row, 'partner': partnerId != null ? partners[partnerId] : null},
      registeredCount: (registrationRows).length,
      registration: myRegistration,
    );
  }

  Future<void> registerForEvent({required String eventId, required String userId}) async {
    await _client.from('event_registrations').upsert({
      'event_id': eventId,
      'user_id': userId,
      'status': 'registered',
      'cancelled_at': null,
    }, onConflict: 'event_id,user_id');

    try {
      await _client.from('engagement_logs').insert({
        'user_id': userId,
        'action_type': 'event_register',
        'reference_type': 'event',
        'reference_id': eventId,
      });
    } catch (_) {}
  }

  Future<void> cancelRegistration({required String eventId, required String userId}) async {
    await _client
        .from('event_registrations')
        .update({'status': 'cancelled', 'cancelled_at': DateTime.now().toIso8601String()})
        .eq('event_id', eventId)
        .eq('user_id', userId);
  }

  /// Check-in runs entirely server-side (`check_in_attendee`): it validates
  /// the registration, the event time window and duplicates, records
  /// attendance and awards the points in one transaction.
  Future<String> checkInWithQrCode({
    required String eventId,
    required String qrCode,
    required String officerId,
  }) async {
    final name = await _client.rpc('check_in_attendee', params: {
      'p_event_id': eventId,
      'p_qr_code': qrCode,
    });
    return name as String;
  }

  Future<String> checkInMember({required String eventId, required String userId}) async {
    final name = await _client.rpc('check_in_attendee', params: {
      'p_event_id': eventId,
      'p_user_id': userId,
    });
    return name as String;
  }

  /// Officer view: everyone registered for the event and whether they have
  /// been checked in.
  Future<List<EventAttendee>> getAttendees(String eventId) async {
    final rows = await _client
        .from('event_registrations')
        .select('user_id, status, registered_at, member:profiles!event_registrations_user_id_fkey(full_name, avatar_url, student_number)')
        .eq('event_id', eventId)
        .neq('status', 'cancelled')
        .order('registered_at');
    final attendance = await _client
        .from('attendance')
        .select('user_id, checked_in_at, method')
        .eq('event_id', eventId);
    final byUser = {for (final a in attendance as List) a['user_id'] as String: a as Map<String, dynamic>};

    return (rows as List).map((r) {
      final m = r as Map<String, dynamic>;
      final member = m['member'] as Map<String, dynamic>?;
      final a = byUser[m['user_id']];
      return EventAttendee(
        userId: m['user_id'] as String,
        name: (member?['full_name'] as String?) ?? 'Member',
        avatarUrl: member?['avatar_url'] as String?,
        studentNumber: member?['student_number'] as String?,
        checkedInAt: a != null ? DateTime.parse(a['checked_in_at'] as String) : null,
        method: a?['method'] as String?,
      );
    }).toList();
  }

  Future<void> createEvent({
    required String title,
    required String description,
    required EventCategory category,
    required DateTime startAt,
    required DateTime endAt,
    String? venueName,
    String? venueAddress,
    double? latitude,
    double? longitude,
    required bool isOnline,
    String? onlineUrl,
    int? capacity,
    DateTime? registrationDeadline,
    String? bannerUrl,
    required String createdBy,
    String? partnerId,
  }) async {
    await _client.from('events').insert({
      'title': title,
      'description': description,
      'category': category.key,
      'start_at': startAt.toIso8601String(),
      'end_at': endAt.toIso8601String(),
      'venue_name': venueName,
      'venue_address': venueAddress,
      'latitude': latitude,
      'longitude': longitude,
      'is_online': isOnline,
      'online_url': onlineUrl,
      'capacity': capacity,
      'registration_deadline': registrationDeadline?.toIso8601String(),
      'banner_url': bannerUrl,
      'status': 'upcoming',
      'created_by': createdBy,
      'partner_id': partnerId,
    });
  }

  Future<void> updateEvent({
    required String id,
    required String title,
    required String description,
    required EventCategory category,
    required DateTime startAt,
    required DateTime endAt,
    String? venueName,
    String? venueAddress,
    double? latitude,
    double? longitude,
    required bool isOnline,
    String? onlineUrl,
    int? capacity,
    DateTime? registrationDeadline,
    String? bannerUrl,
    required EventStatus status,
    String? partnerId,
  }) async {
    await _client.from('events').update({
      'title': title,
      'description': description,
      'category': category.key,
      'start_at': startAt.toIso8601String(),
      'end_at': endAt.toIso8601String(),
      'venue_name': venueName,
      'venue_address': venueAddress,
      'latitude': latitude,
      'longitude': longitude,
      'is_online': isOnline,
      'online_url': onlineUrl,
      'capacity': capacity,
      'registration_deadline': registrationDeadline?.toIso8601String(),
      'banner_url': bannerUrl,
      'status': status.name,
      'partner_id': partnerId,
    }).eq('id', id);
  }

  Future<void> deleteEvent(String id) async {
    await _client.from('events').delete().eq('id', id);
  }
}
