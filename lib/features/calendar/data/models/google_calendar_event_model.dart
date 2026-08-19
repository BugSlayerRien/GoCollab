import '../../domain/entities/google_calendar_event.dart';

class GoogleCalendarEventModel {
  GoogleCalendarEventModel._();

  static const _gocollabMarker = 'GoCollab Event';

  static GoogleCalendarEvent fromApiJson(
    Map<String, dynamic> json, {
    Map<String, String> gocollabMappings = const {},
  }) {
    final id = json['id'] as String? ?? '';
    final title = (json['summary'] as String?)?.trim().isNotEmpty == true
        ? json['summary'] as String
        : '(No title)';
    final description = json['description'] as String? ?? '';
    final location = (json['location'] as String?)?.trim();
    final startMap = json['start'] as Map<String, dynamic>?;
    final endMap = json['end'] as Map<String, dynamic>?;
    final start = _parseEventDateTime(startMap);
    final end = _parseEventDateTime(endMap);
    final isAllDay = startMap?['date'] != null;

    final mappedEventId = gocollabMappings[id];
    final isGoCollab = mappedEventId != null || description.contains(_gocollabMarker);

    return GoogleCalendarEvent(
      id: id,
      title: title,
      startAt: start ?? DateTime.now(),
      endAt: end ?? start ?? DateTime.now(),
      location: location != null && location.isNotEmpty ? location : null,
      isAllDay: isAllDay,
      isGoCollabEvent: isGoCollab,
      goCollabEventId: mappedEventId,
    );
  }

  static DateTime? _parseEventDateTime(Map<String, dynamic>? value) {
    if (value == null) return null;
    final dateTime = value['dateTime'] as String?;
    if (dateTime != null) return DateTime.parse(dateTime).toLocal();
    final date = value['date'] as String?;
    if (date != null) return DateTime.parse(date);
    return null;
  }
}
