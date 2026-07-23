import '../../domain/entities/sponsorship.dart';

class SponsorshipModel extends Sponsorship {
  const SponsorshipModel({
    required super.id,
    required super.partnerId,
    required super.title,
    required super.sponsorshipType,
    required super.status,
    super.amount,
    super.currency,
    super.startDate,
    super.endDate,
    super.notes,
  });

  factory SponsorshipModel.fromMap(Map<String, dynamic> map) {
    return SponsorshipModel(
      id: map['id'] as String,
      partnerId: map['partner_id'] as String,
      title: map['title'] as String,
      sponsorshipType: map['sponsorship_type'] as String,
      status: map['status'] as String,
      amount: (map['amount'] as num?)?.toDouble(),
      currency: map['currency'] as String? ?? 'PHP',
      startDate: map['start_date'] != null ? DateTime.parse(map['start_date'] as String) : null,
      endDate: map['end_date'] != null ? DateTime.parse(map['end_date'] as String) : null,
      notes: map['notes'] as String?,
    );
  }
}
