import 'package:equatable/equatable.dart';
import '../../../../core/models/content_creator.dart';

/// A member's self-reported "I applied" record for an opportunity. Only
/// visible to the member themselves and to officers (see RLS on
/// `opportunity_applications`) — officers use this list to manually cross-
/// check with the partner organization, since GoCollab cannot verify actions
/// taken on an external site.
class OpportunityApplicant extends Equatable {
  const OpportunityApplicant({
    required this.userId,
    required this.appliedAt,
    this.note,
    this.applicant,
  });

  final String userId;
  final DateTime appliedAt;
  final String? note;
  final ContentCreator? applicant;

  @override
  List<Object?> get props => [userId, appliedAt, note, applicant?.id, applicant?.name, applicant?.avatarUrl];
}
