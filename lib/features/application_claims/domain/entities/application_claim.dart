import 'package:equatable/equatable.dart';

/// A member's request to redeem points for applying on an external site.
/// clicked -> pending (proof uploaded) -> approved | rejected.
class ApplicationClaim extends Equatable {
  const ApplicationClaim({
    required this.id,
    required this.userId,
    required this.opportunityId,
    required this.status,
    required this.clickedAt,
    this.proofPath,
    this.submittedAt,
    this.rejectionReason,
    this.applicantName,
    this.applicantAvatarUrl,
    this.opportunityTitle,
    this.opportunityOrganization,
    this.ocrResult = 'not_run',
  });

  final String id;
  final String userId;
  final String opportunityId;
  final String status;
  final DateTime clickedAt;
  final String? proofPath;
  final DateTime? submittedAt;
  final String? rejectionReason;
  final String? applicantName;
  final String? applicantAvatarUrl;
  final String? opportunityTitle;
  final String? opportunityOrganization;

  /// Advisory on-device OCR of the proof: not_run | matched | partial | mismatch.
  final String ocrResult;

  bool get canSubmitProof => status == 'clicked' || status == 'rejected';
  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  factory ApplicationClaim.fromMap(Map<String, dynamic> map) {
    final applicant = map['applicant'] as Map<String, dynamic>?;
    final opportunity = map['opportunity'] as Map<String, dynamic>?;
    return ApplicationClaim(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      opportunityId: map['opportunity_id'] as String,
      status: map['status'] as String,
      clickedAt: DateTime.parse(map['clicked_at'] as String),
      proofPath: map['proof_path'] as String?,
      submittedAt: map['submitted_at'] != null ? DateTime.parse(map['submitted_at'] as String) : null,
      rejectionReason: map['rejection_reason'] as String?,
      applicantName: applicant?['full_name'] as String?,
      applicantAvatarUrl: applicant?['avatar_url'] as String?,
      opportunityTitle: opportunity?['title'] as String?,
      opportunityOrganization: opportunity?['organization'] as String?,
      ocrResult: map['ocr_result'] as String? ?? 'not_run',
    );
  }

  @override
  List<Object?> get props => [id, userId, opportunityId, status, clickedAt, proofPath, submittedAt, rejectionReason, ocrResult];
}
