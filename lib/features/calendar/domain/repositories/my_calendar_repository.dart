import '../../../../core/utils/result.dart';
import '../entities/google_calendar_event.dart';

abstract class MyCalendarRepository {
  /// Fetches live events from Google Calendar API for the given range.
  Future<Result<List<GoogleCalendarEvent>>> fetchEventsInRange({
    required String userId,
    required DateTime rangeStart,
    required DateTime rangeEnd,
  });

  /// Whether the user currently has a usable Google Calendar access token.
  Future<bool> hasCalendarAccess();
}
