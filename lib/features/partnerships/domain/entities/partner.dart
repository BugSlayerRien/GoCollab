import 'package:equatable/equatable.dart';

enum PartnerCategory {
  industry,
  academic,
  government,
  ngo,
  startup,
  other;

  static PartnerCategory fromKey(String key) {
    return PartnerCategory.values.firstWhere((c) => c.name == key, orElse: () => PartnerCategory.other);
  }

  String get label => switch (this) {
        PartnerCategory.industry => 'Industry',
        PartnerCategory.academic => 'Academic',
        PartnerCategory.government => 'Government',
        PartnerCategory.ngo => 'NGO',
        PartnerCategory.startup => 'Startup',
        PartnerCategory.other => 'Other',
      };
}

enum CollaborationStatus {
  prospect,
  active,
  onHold,
  ended;

  static CollaborationStatus fromKey(String key) {
    return switch (key) {
      'prospect' => CollaborationStatus.prospect,
      'active' => CollaborationStatus.active,
      'on-hold' => CollaborationStatus.onHold,
      'ended' => CollaborationStatus.ended,
      _ => CollaborationStatus.prospect,
    };
  }

  String get key => switch (this) {
        CollaborationStatus.prospect => 'prospect',
        CollaborationStatus.active => 'active',
        CollaborationStatus.onHold => 'on-hold',
        CollaborationStatus.ended => 'ended',
      };

  String get label => switch (this) {
        CollaborationStatus.prospect => 'Prospect',
        CollaborationStatus.active => 'Active',
        CollaborationStatus.onHold => 'On Hold',
        CollaborationStatus.ended => 'Ended',
      };
}

class Partner extends Equatable {
  const Partner({
    required this.id,
    required this.name,
    required this.category,
    required this.collaborationStatus,
    this.logoUrl,
    this.description,
    this.contactPerson,
    this.contactEmail,
    this.contactPhone,
    this.address,
    this.latitude,
    this.longitude,
    this.website,
  });

  final String id;
  final String name;
  final PartnerCategory category;
  final CollaborationStatus collaborationStatus;
  final String? logoUrl;
  final String? description;
  final String? contactPerson;
  final String? contactEmail;
  final String? contactPhone;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? website;

  bool get hasLocation => latitude != null && longitude != null;

  @override
  List<Object?> get props => [
        id,
        name,
        category,
        collaborationStatus,
        logoUrl,
        description,
        contactPerson,
        contactEmail,
        contactPhone,
        address,
        latitude,
        longitude,
        website,
      ];
}
