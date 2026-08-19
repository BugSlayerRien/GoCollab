import 'package:equatable/equatable.dart';

/// A single event retrieved from the user's Google Calendar (primary calendar).
class GoogleCalendarEvent extends Equatable {
  const GoogleCalendarEvent({
    required this.id,
    required this.title,
    required this.startAt,
    required this.endAt,
    this.location,
    this.isAllDay = false,
    this.isGoCollabEvent = false,
    this.goCollabEventId,
  });

  final String id;
  final String title;
  final DateTime startAt;
  final DateTime endAt;
  final String? location;
  final bool isAllDay;

  /// Whether this entry was created or synced from GoCollab.
  final bool isGoCollabEvent;

  /// GoCollab event UUID when [isGoCollabEvent] is true and mapping exists.
  final String? goCollabEventId;

  bool occursOn(DateTime day) {
    final localDay = DateTime(day.year, day.month, day.day);
    final eventStart = DateTime(startAt.year, startAt.month, startAt.day);
    final eventEnd = DateTime(endAt.year, endAt.month, endAt.day);
    return !localDay.isBefore(eventStart) && !localDay.isAfter(eventEnd);
  }

  @override
  List<Object?> get props => [
        id,
        title,
        startAt,
        endAt,
        location,
        isAllDay,
        isGoCollabEvent,
        goCollabEventId,
      ];
}
