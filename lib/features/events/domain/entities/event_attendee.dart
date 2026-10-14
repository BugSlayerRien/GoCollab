import 'package:equatable/equatable.dart';

/// One registered member as seen by an officer on the attendee list.
class EventAttendee extends Equatable {
  const EventAttendee({
    required this.userId,
    required this.name,
    this.avatarUrl,
    this.studentNumber,
    this.checkedInAt,
    this.method,
  });

  final String userId;
  final String name;
  final String? avatarUrl;
  final String? studentNumber;
  final DateTime? checkedInAt;

  /// 'qr' or 'manual'.
  final String? method;

  bool get isCheckedIn => checkedInAt != null;

  @override
  List<Object?> get props => [userId, name, avatarUrl, studentNumber, checkedInAt, method];
}
