import 'package:equatable/equatable.dart';

class Sponsorship extends Equatable {
  const Sponsorship({
    required this.id,
    required this.partnerId,
    required this.title,
    required this.sponsorshipType,
    required this.status,
    this.amount,
    this.currency = 'PHP',
    this.startDate,
    this.endDate,
    this.notes,
  });

  final String id;
  final String partnerId;
  final String title;
  final String sponsorshipType;
  final String status;
  final double? amount;
  final String currency;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? notes;

  @override
  List<Object?> get props =>
      [id, partnerId, title, sponsorshipType, status, amount, currency, startDate, endDate, notes];
}
