import '../../../../core/services/google_calendar_service.dart';
import '../../../events/data/datasources/gcal_datasource.dart';
import '../models/google_calendar_event_model.dart';
import '../../domain/entities/google_calendar_event.dart';

/// Fetches Google Calendar events via the shared REST client and enriches
/// them with GoCollab sync metadata from Supabase.
class MyCalendarRemoteDataSource {
  MyCalendarRemoteDataSource(this._gcalDataSource);

  final GcalDataSource _gcalDataSource;

  Future<bool> hasCalendarAccess() => GoogleCalendarService.hasAccess();

  Future<List<GoogleCalendarEvent>> fetchEventsInRange({
    required String userId,
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) async {
    final mappings = await _gcalDataSource.listUserGcalMappings(userId);
    final items = await GoogleCalendarService.listEventsInRange(
      timeMin: rangeStart,
      timeMax: rangeEnd,
    );
    return items
        .map((json) => GoogleCalendarEventModel.fromApiJson(json, gocollabMappings: mappings))
        .toList();
  }
}
