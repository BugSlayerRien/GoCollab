import 'package:equatable/equatable.dart';

/// A single past-event record shown on the member's Profile > Event History
/// tab — merges `event_registrations` + `attendance` + `certificates`.
class EventHistoryItem extends Equatable {
  const EventHistoryItem({
    required this.eventId,
    required this.eventTitle,
    required this.eventDate,
    required this.attended,
    this.certificateUrl,
    this.certificateNumber,
  });

  final String eventId;
  final String eventTitle;
  final DateTime eventDate;
  final bool attended;
  final String? certificateUrl;
  final String? certificateNumber;

  bool get hasCertificate => certificateUrl != null;

  @override
  List<Object?> get props => [eventId, eventTitle, eventDate, attended, certificateUrl, certificateNumber];
}
