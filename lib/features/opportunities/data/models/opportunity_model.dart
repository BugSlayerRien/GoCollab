import '../../domain/entities/opportunity.dart';

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
  });

  factory OpportunityModel.fromMap(Map<String, dynamic> map, {bool isSaved = false}) {
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
    );
  }
}
