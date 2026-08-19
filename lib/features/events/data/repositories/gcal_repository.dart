import '../../../../core/errors/failure.dart';
import '../../../../core/services/google_calendar_service.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/event.dart';
import '../datasources/gcal_datasource.dart';

/// Orchestrates Google Calendar REST API calls with Supabase persistence
/// of the calendar-event mapping. Each method corresponds to one of the
/// required HTTP verbs (GET, POST, PATCH, DELETE).
class GcalRepository {
  GcalRepository(this._gcalDataSource);

  final GcalDataSource _gcalDataSource;

  /// GET — Checks whether the GoCollab event is synced and still exists
  /// on the user's Google Calendar.
  Future<Result<bool>> isSynced({required String userId, required String eventId}) async {
    try {
      final gcalId = await _gcalDataSource.getGcalEventId(userId: userId, eventId: eventId);
      if (gcalId == null) return const Result.success(false);

      final gcalEvent = await GoogleCalendarService.getEvent(gcalId);
      if (gcalEvent == null) {
        await _gcalDataSource.deleteGcalEventId(userId: userId, eventId: eventId);
        return const Result.success(false);
      }
      return const Result.success(true);
    } on CalendarAuthException {
      return const Result.success(false);
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  /// POST — Creates a Google Calendar event and stores the mapping.
  Future<Result<String>> addToCalendar({
    required String userId,
    required Event event,
  }) async {
    try {
      final existing = await _gcalDataSource.getGcalEventId(userId: userId, eventId: event.id);
      if (existing != null) {
        final gcalEvent = await GoogleCalendarService.getEvent(existing);
        if (gcalEvent != null) {
          return const Result.failure(ServerFailure('This event is already in your Google Calendar.'));
        }
        await _gcalDataSource.deleteGcalEventId(userId: userId, eventId: event.id);
      }

      final location = event.isOnline
          ? (event.onlineUrl ?? 'Online')
          : [event.venueName, event.venueAddress].where((s) => s != null && s.isNotEmpty).join(', ');

      final gcalId = await GoogleCalendarService.createEvent(
        summary: event.title,
        description: '${event.description}\n\nGoCollab Event • ${event.category.label}',
        startTime: event.startAt,
        endTime: event.endAt,
        location: location,
      );

      await _gcalDataSource.saveGcalEventId(userId: userId, eventId: event.id, gcalEventId: gcalId);
      return Result.success(gcalId);
    } on CalendarAuthException catch (e) {
      return Result.failure(AuthFailure(e.toString()));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  /// PATCH — Updates the synced Google Calendar event with new event data.
  Future<Result<void>> updateCalendarEvent({
    required String userId,
    required Event event,
  }) async {
    try {
      final gcalId = await _gcalDataSource.getGcalEventId(userId: userId, eventId: event.id);
      if (gcalId == null) {
        return const Result.failure(ServerFailure('This event is not synced to Google Calendar.'));
      }

      final location = event.isOnline
          ? (event.onlineUrl ?? 'Online')
          : [event.venueName, event.venueAddress].where((s) => s != null && s.isNotEmpty).join(', ');

      await GoogleCalendarService.updateEvent(
        calendarEventId: gcalId,
        summary: event.title,
        description: '${event.description}\n\nGoCollab Event • ${event.category.label}',
        startTime: event.startAt,
        endTime: event.endAt,
        location: location,
      );

      await _gcalDataSource.saveGcalEventId(userId: userId, eventId: event.id, gcalEventId: gcalId);
      return const Result.success(null);
    } on CalendarAuthException catch (e) {
      return Result.failure(AuthFailure(e.toString()));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  /// DELETE — Removes the synced event from Google Calendar.
  Future<Result<void>> removeFromCalendar({
    required String userId,
    required String eventId,
  }) async {
    try {
      final gcalId = await _gcalDataSource.getGcalEventId(userId: userId, eventId: eventId);
      if (gcalId == null) {
        return const Result.failure(ServerFailure('This event is not synced to Google Calendar.'));
      }

      await GoogleCalendarService.deleteEvent(gcalId);
      await _gcalDataSource.deleteGcalEventId(userId: userId, eventId: eventId);
      return const Result.success(null);
    } on CalendarAuthException catch (e) {
      return Result.failure(AuthFailure(e.toString()));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }
}
