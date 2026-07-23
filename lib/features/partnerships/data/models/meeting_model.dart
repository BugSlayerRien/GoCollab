import '../../domain/entities/meeting.dart';

class MeetingModel extends Meeting {
  const MeetingModel({
    required super.id,
    required super.partnerId,
    required super.title,
    required super.scheduledAt,
    required super.status,
    super.agenda,
    super.location,
    super.notes,
  });

  factory MeetingModel.fromMap(Map<String, dynamic> map) {
    return MeetingModel(
      id: map['id'] as String,
      partnerId: map['partner_id'] as String,
      title: map['title'] as String,
      scheduledAt: DateTime.parse(map['scheduled_at'] as String),
      status: map['status'] as String,
      agenda: map['agenda'] as String?,
      location: map['location'] as String?,
      notes: map['notes'] as String?,
    );
  }
}
