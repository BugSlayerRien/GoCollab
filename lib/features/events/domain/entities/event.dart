import 'package:equatable/equatable.dart';

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

  bool get hasLocation => latitude != null && longitude != null;
  bool get isFull => capacity != null && registeredCount >= capacity!;
  bool get registrationOpen =>
      status == EventStatus.upcoming &&
      (registrationDeadline == null || registrationDeadline!.isAfter(DateTime.now())) &&
      !isFull;

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
      ];
}
