import 'package:equatable/equatable.dart';
import '../../../../core/models/content_creator.dart';

/// A member's submitted proof of enrolment, awaiting officer review.
/// Only created when the account's email domain isn't on the school
/// allowlist — school-email signups are verified automatically and never
/// produce one of these.
class VerificationRequest extends Equatable {
  const VerificationRequest({
    required this.id,
    required this.userId,
    required this.studentNumber,
    required this.idDocumentPath,
    required this.status,
    required this.submittedAt,
    this.reviewedAt,
    this.rejectionReason,
    this.applicant,
  });

  final String id;
  final String userId;
  final String studentNumber;

  /// Storage object path inside the private `verification-docs` bucket.
  /// Needs a signed URL to be displayed — there is no public URL.
  final String idDocumentPath;
  final String status;
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final String? rejectionReason;
  final ContentCreator? applicant;

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  @override
  List<Object?> get props => [
        id,
        userId,
        studentNumber,
        idDocumentPath,
        status,
        submittedAt,
        reviewedAt,
        rejectionReason,
        applicant?.id,
        applicant?.name,
        applicant?.avatarUrl,
      ];
}
