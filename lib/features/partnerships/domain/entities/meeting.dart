import 'package:equatable/equatable.dart';

class Meeting extends Equatable {
  const Meeting({
    required this.id,
    required this.partnerId,
    required this.title,
    required this.scheduledAt,
    required this.status,
    this.agenda,
    this.location,
    this.notes,
  });

  final String id;
  final String partnerId;
  final String title;
  final DateTime scheduledAt;
  final String status;
  final String? agenda;
  final String? location;
  final String? notes;

  @override
  List<Object?> get props => [id, partnerId, title, scheduledAt, status, agenda, location, notes];
}
