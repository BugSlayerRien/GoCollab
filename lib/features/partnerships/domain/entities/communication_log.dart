import 'package:equatable/equatable.dart';

class CommunicationLog extends Equatable {
  const CommunicationLog({
    required this.id,
    required this.partnerId,
    required this.subject,
    required this.direction,
    required this.contactMethod,
    required this.communicatedAt,
    this.message,
    this.communicatedByName,
  });

  final String id;
  final String partnerId;
  final String subject;
  final String direction;
  final String contactMethod;
  final DateTime communicatedAt;
  final String? message;
  final String? communicatedByName;

  @override
  List<Object?> get props =>
      [id, partnerId, subject, direction, contactMethod, communicatedAt, message, communicatedByName];
}
