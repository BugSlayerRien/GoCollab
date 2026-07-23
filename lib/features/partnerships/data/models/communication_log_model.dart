import '../../domain/entities/communication_log.dart';

class CommunicationLogModel extends CommunicationLog {
  const CommunicationLogModel({
    required super.id,
    required super.partnerId,
    required super.subject,
    required super.direction,
    required super.contactMethod,
    required super.communicatedAt,
    super.message,
    super.communicatedByName,
  });

  factory CommunicationLogModel.fromMap(Map<String, dynamic> map) {
    final author = map['author'] as Map<String, dynamic>?;
    return CommunicationLogModel(
      id: map['id'] as String,
      partnerId: map['partner_id'] as String,
      subject: map['subject'] as String,
      direction: map['direction'] as String,
      contactMethod: map['contact_method'] as String,
      communicatedAt: DateTime.parse(map['communicated_at'] as String),
      message: map['message'] as String?,
      communicatedByName: author?['full_name'] as String?,
    );
  }
}
