import 'package:equatable/equatable.dart';

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
      ];
}
