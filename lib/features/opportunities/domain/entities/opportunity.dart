import 'package:equatable/equatable.dart';
import '../../../../core/models/content_creator.dart';
import 'opportunity_applicant.dart';

enum OpportunityType {
  internship,
  scholarship,
  certification,
  hackathon,
  job,
  fellowship;

  static OpportunityType fromKey(String key) {
    return OpportunityType.values.firstWhere((t) => t.name == key, orElse: () => OpportunityType.internship);
  }

  String get label => switch (this) {
        OpportunityType.internship => 'Internship',
        OpportunityType.scholarship => 'Scholarship',
        OpportunityType.certification => 'Certification',
        OpportunityType.hackathon => 'Hackathon',
        OpportunityType.job => 'Job',
        OpportunityType.fellowship => 'Fellowship',
      };
}

class Opportunity extends Equatable {
  const Opportunity({
    required this.id,
    required this.title,
    required this.organization,
    required this.type,
    required this.description,
    this.requirements,
    this.location,
    this.isRemote = false,
    this.applicationUrl,
    this.bannerUrl,
    this.deadline,
    this.status = 'open',
    this.isSaved = false,
    this.hasApplied = false,
    this.appliedAt,
    this.applicationNote,
    this.applicants = const [],
    this.postedBy,
    this.creatorName,
    this.creatorAvatarUrl,
  });

  final String id;
  final String title;
  final String organization;
  final OpportunityType type;
  final String description;
  final String? requirements;
  final String? location;
  final bool isRemote;
  final String? applicationUrl;
  final String? bannerUrl;
  final DateTime? deadline;
  final String status;
  final bool isSaved;

  /// Whether the current user has self-reported applying via "Mark as
  /// applied". This is an honest self-report, not a verified action — see
  /// [applicants] for the officer-visible list used for manual follow-up.
  final bool hasApplied;
  final DateTime? appliedAt;
  final String? applicationNote;

  /// Populated only on the detail fetch. RLS restricts this to the current
  /// user's own record unless they are an officer, in which case it is the
  /// full applicant list for this opportunity.
  final List<OpportunityApplicant> applicants;

  final String? postedBy;
  final String? creatorName;
  final String? creatorAvatarUrl;

  ContentCreator? get creator => ContentCreator(
        id: postedBy,
        name: creatorName,
        avatarUrl: creatorAvatarUrl,
      );

  bool get isExpired => deadline != null && deadline!.isBefore(DateTime.now());
  bool get isOpen => status == 'open' && !isExpired;

  int? get daysUntilDeadline {
    if (deadline == null) return null;
    return deadline!.difference(DateTime.now()).inDays;
  }

  @override
  List<Object?> get props => [
        id,
        title,
        organization,
        type,
        description,
        requirements,
        location,
        isRemote,
        applicationUrl,
        bannerUrl,
        deadline,
        status,
        isSaved,
        hasApplied,
        appliedAt,
        applicationNote,
        applicants,
        postedBy,
        creatorName,
        creatorAvatarUrl,
      ];
}
