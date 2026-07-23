import 'package:equatable/equatable.dart';

/// Lightweight aggregate stats shown on the member dashboard's "Community
/// statistics" widget (module #2). Officers see a deeper breakdown in the
/// dedicated Analytics module — this is intentionally a quick summary.
class CommunityStats extends Equatable {
  const CommunityStats({
    required this.totalMembers,
    required this.upcomingEventsCount,
    required this.openOpportunitiesCount,
    required this.userPoints,
  });

  final int totalMembers;
  final int upcomingEventsCount;
  final int openOpportunitiesCount;
  final int userPoints;

  @override
  List<Object?> get props => [totalMembers, upcomingEventsCount, openOpportunitiesCount, userPoints];
}
