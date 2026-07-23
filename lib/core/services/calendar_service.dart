import 'package:add_2_calendar/add_2_calendar.dart' as cal;
import '../../features/events/domain/entities/event.dart' as gocollab;

/// Adds a GoCollab event to the user's native device calendar (which is
/// backed by the Google Calendar app on virtually every Android device),
/// satisfying the "sync registered events to the user's calendar" /
/// "add events directly to calendar" requirements without needing a
/// separate Google Calendar OAuth flow just to write one event.
class CalendarService {
  CalendarService._();

  static Future<bool> addEventToDeviceCalendar(gocollab.Event event) {
    final calendarEvent = cal.Event(
      title: event.title,
      description: event.description,
      location: event.isOnline ? (event.onlineUrl ?? 'Online') : (event.venueName ?? ''),
      startDate: event.startAt,
      endDate: event.endAt,
      allDay: false,
    );
    return cal.Add2Calendar.addEvent2Cal(calendarEvent);
  }
}
