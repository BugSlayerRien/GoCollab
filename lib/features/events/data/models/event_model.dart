import '../../domain/entities/event.dart';

class EventModel extends Event {
  const EventModel({
    required super.id,
    required super.title,
    required super.description,
    required super.category,
    required super.startAt,
    required super.endAt,
    required super.status,
    super.bannerUrl,
    super.venueName,
    super.venueAddress,
    super.latitude,
    super.longitude,
    super.isOnline,
    super.onlineUrl,
    super.capacity,
    super.registrationDeadline,
    super.isFeatured,
    super.registeredCount,
    super.isRegistered,
    super.myQrCode,
  });

  /// [map] is a raw `events` row. [registeredCount] should be pre-aggregated
  /// by the datasource (Postgrest doesn't return `count(*)` per-row without
  /// a separate query/RPC). [registration] is the current user's own
  /// `event_registrations` row, if any, used to compute [isRegistered].
  factory EventModel.fromMap(
    Map<String, dynamic> map, {
    int registeredCount = 0,
    Map<String, dynamic>? registration,
  }) {
    return EventModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      category: EventCategory.fromKey(map['category'] as String),
      startAt: DateTime.parse(map['start_at'] as String),
      endAt: DateTime.parse(map['end_at'] as String),
      status: EventStatus.fromKey(map['status'] as String),
      bannerUrl: map['banner_url'] as String?,
      venueName: map['venue_name'] as String?,
      venueAddress: map['venue_address'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      isOnline: map['is_online'] as bool? ?? false,
      onlineUrl: map['online_url'] as String?,
      capacity: (map['capacity'] as num?)?.toInt(),
      registrationDeadline: map['registration_deadline'] != null
          ? DateTime.parse(map['registration_deadline'] as String)
          : null,
      isFeatured: map['is_featured'] as bool? ?? false,
      registeredCount: registeredCount,
      isRegistered: registration != null && registration['status'] != 'cancelled',
      myQrCode: registration?['qr_code'] as String?,
    );
  }
}
