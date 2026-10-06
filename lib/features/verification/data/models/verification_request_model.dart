import '../../../../core/models/content_creator.dart';
import '../../domain/entities/verification_request.dart';

class VerificationRequestModel extends VerificationRequest {
  const VerificationRequestModel({
    required super.id,
    required super.userId,
    required super.studentNumber,
    required super.idDocumentPath,
    required super.status,
    required super.submittedAt,
    super.reviewedAt,
    super.rejectionReason,
    super.applicant,
  });

  factory VerificationRequestModel.fromMap(Map<String, dynamic> map) {
    return VerificationRequestModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      studentNumber: map['student_number'] as String,
      idDocumentPath: map['id_document_path'] as String,
      status: map['status'] as String? ?? 'pending',
      submittedAt: DateTime.parse(map['submitted_at'] as String),
      reviewedAt: map['reviewed_at'] != null ? DateTime.parse(map['reviewed_at'] as String) : null,
      rejectionReason: map['rejection_reason'] as String?,
      applicant: ContentCreator.fromProfileMap(
        map['applicant'] as Map<String, dynamic>?,
        fallbackId: map['user_id'] as String?,
      ),
    );
  }
}
