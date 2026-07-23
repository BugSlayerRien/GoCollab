import '../../domain/entities/partner.dart';

class PartnerModel extends Partner {
  const PartnerModel({
    required super.id,
    required super.name,
    required super.category,
    required super.collaborationStatus,
    super.logoUrl,
    super.description,
    super.contactPerson,
    super.contactEmail,
    super.contactPhone,
    super.address,
    super.latitude,
    super.longitude,
    super.website,
  });

  factory PartnerModel.fromMap(Map<String, dynamic> map) {
    return PartnerModel(
      id: map['id'] as String,
      name: map['name'] as String,
      category: PartnerCategory.fromKey(map['category'] as String),
      collaborationStatus: CollaborationStatus.fromKey(map['collaboration_status'] as String),
      logoUrl: map['logo_url'] as String?,
      description: map['description'] as String?,
      contactPerson: map['contact_person'] as String?,
      contactEmail: map['contact_email'] as String?,
      contactPhone: map['contact_phone'] as String?,
      address: map['address'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      website: map['website'] as String?,
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'name': name,
      'category': category.name,
      'collaboration_status': collaborationStatus.key,
      'logo_url': logoUrl,
      'description': description,
      'contact_person': contactPerson,
      'contact_email': contactEmail,
      'contact_phone': contactPhone,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'website': website,
    };
  }
}
