import 'package:equatable/equatable.dart';
import '../../../../core/models/content_creator.dart';

enum EventCategory {
  workshop,
  hackathon,
  seminar,
  meetup,
  studyJam,
  competition,
  other;

  static EventCategory fromKey(String key) {
    return switch (key) {
      'workshop' => EventCategory.workshop,
      'hackathon' => EventCategory.hackathon,
      'seminar' => EventCategory.seminar,
      'meetup' => EventCategory.meetup,
      'study-jam' => EventCategory.studyJam,
      'competition' => EventCategory.competition,
      _ => EventCategory.other,
    };
  }

  String get label => switch (this) {
        EventCategory.workshop => 'Workshop',
        EventCategory.hackathon => 'Hackathon',
        EventCategory.seminar => 'Seminar',
        EventCategory.meetup => 'Meetup',
        EventCategory.studyJam => 'Study Jam',
        EventCategory.competition => 'Competition',
        EventCategory.other => 'Other',
      };

  String get key => switch (this) {
        EventCategory.studyJam => 'study-jam',
        _ => name,
      };
}

enum EventStatus {
  draft,
  upcoming,
  ongoing,
  completed,
  cancelled;

  static EventStatus fromKey(String key) {
    return EventStatus.values.firstWhere((e) => e.name == key, orElse: () => EventStatus.upcoming);
  }
}

class Event extends Equatable {
  const Event({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.startAt,
    required this.endAt,
    required this.status,
    this.bannerUrl,
    this.venueName,
    this.venueAddress,
    this.latitude,
    this.longitude,
    this.isOnline = false,
    this.onlineUrl,
    this.capacity,
    this.registrationDeadline,
    this.isFeatured = false,
    this.registeredCount = 0,
    this.isRegistered = false,
    this.myQrCode,
    this.createdBy,
    this.creatorName,
    this.creatorAvatarUrl,
    this.partnerId,
    this.partnerName,
    this.partnerLogoUrl,
    this.partnerDescription,
    this.partnerWebsite,
    this.isAttended = false,
  });

  final String id;
  final String title;
  final String description;
  final EventCategory category;
  final DateTime startAt;
  final DateTime endAt;
  final EventStatus status;
  final String? bannerUrl;
  final String? venueName;
  final String? venueAddress;
  final double? latitude;
  final double? longitude;
  final bool isOnline;
  final String? onlineUrl;
  final int? capacity;
  final DateTime? registrationDeadline;
  final bool isFeatured;
  final int registeredCount;
  final bool isRegistered;
  final String? myQrCode;
  final String? createdBy;
  final String? creatorName;
  final String? creatorAvatarUrl;

  /// Optional partner/sponsor attached to this event (from Partnerships),
  /// shown on the event detail screen when set.
  final String? partnerId;
  final String? partnerName;
  final String? partnerLogoUrl;
  final String? partnerDescription;
  final String? partnerWebsite;

  /// The member was checked in at the event (registration status 'attended').
  final bool isAttended;

  ContentCreator? get creator => ContentCreator(
        id: createdBy,
        name: creatorName,
        avatarUrl: creatorAvatarUrl,
      );

  bool get hasLocation => latitude != null && longitude != null;
  bool get isFull => capacity != null && registeredCount >= capacity!;
  bool get isPast =>
      endAt.isBefore(DateTime.now()) ||
      status == EventStatus.completed ||
      status == EventStatus.cancelled;
  bool get registrationOpen =>
      status == EventStatus.upcoming &&
      startAt.isAfter(DateTime.now()) &&
      (registrationDeadline == null || registrationDeadline!.isAfter(DateTime.now())) &&
      !isFull;

  /// Shown on the member Events "Available" list: not past, and still open to register.
  bool get isAvailable => registrationOpen && status != EventStatus.draft;

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        category,
        startAt,
        endAt,
        status,
        bannerUrl,
        venueName,
        venueAddress,
        latitude,
        longitude,
        isOnline,
        onlineUrl,
        capacity,
        registrationDeadline,
        isFeatured,
        registeredCount,
        isRegistered,
        myQrCode,
        createdBy,
        creatorName,
        creatorAvatarUrl,
        partnerId,
        partnerName,
        partnerLogoUrl,
        partnerDescription,
        partnerWebsite,
        isAttended,
      ];
}
