import '../../../../core/models/content_creator.dart';
import '../../domain/entities/opportunity.dart';
import '../../domain/entities/opportunity_applicant.dart';

class OpportunityModel extends Opportunity {
  const OpportunityModel({
    required super.id,
    required super.title,
    required super.organization,
    required super.type,
    required super.description,
    super.requirements,
    super.location,
    super.isRemote,
    super.applicationUrl,
    super.bannerUrl,
    super.deadline,
    super.status,
    super.isSaved,
    super.hasApplied,
    super.appliedAt,
    super.applicationNote,
    super.applicants,
    super.postedBy,
    super.creatorName,
    super.creatorAvatarUrl,
  });

  factory OpportunityModel.fromMap(
    Map<String, dynamic> map, {
    bool isSaved = false,
    Map<String, dynamic>? myApplication,
    List<OpportunityApplicant> applicants = const [],
  }) {
    final creator = ContentCreator.fromProfileMap(
      map['creator'] as Map<String, dynamic>?,
      fallbackId: map['posted_by'] as String?,
    );
    return OpportunityModel(
      id: map['id'] as String,
      title: map['title'] as String,
      organization: map['organization'] as String,
      type: OpportunityType.fromKey(map['type'] as String),
      description: map['description'] as String,
      requirements: map['requirements'] as String?,
      location: map['location'] as String?,
      isRemote: map['is_remote'] as bool? ?? false,
      applicationUrl: map['application_url'] as String?,
      bannerUrl: map['banner_url'] as String?,
      deadline: map['deadline'] != null ? DateTime.parse(map['deadline'] as String) : null,
      status: map['status'] as String? ?? 'open',
      isSaved: isSaved,
      hasApplied: myApplication != null,
      appliedAt: myApplication?['applied_at'] != null
          ? DateTime.parse(myApplication!['applied_at'] as String)
          : null,
      applicationNote: myApplication?['note'] as String?,
      applicants: applicants,
      postedBy: creator?.id ?? map['posted_by'] as String?,
      creatorName: creator?.name,
      creatorAvatarUrl: creator?.avatarUrl,
    );
  }
}

class OpportunityApplicantModel extends OpportunityApplicant {
  const OpportunityApplicantModel({
    required super.userId,
    required super.appliedAt,
    super.note,
    super.applicant,
  });

  factory OpportunityApplicantModel.fromMap(Map<String, dynamic> map) {
    return OpportunityApplicantModel(
      userId: map['user_id'] as String,
      appliedAt: DateTime.parse(map['applied_at'] as String),
      note: map['note'] as String?,
      applicant: ContentCreator.fromProfileMap(
        map['applicant'] as Map<String, dynamic>?,
        fallbackId: map['user_id'] as String?,
      ),
    );
  }
}
