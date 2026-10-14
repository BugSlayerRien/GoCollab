import '../../../../core/utils/result.dart';
import '../entities/event.dart';
import '../entities/event_attendee.dart';

abstract class EventRepository {
  Future<Result<List<Event>>> getEvents({String? currentUserId});

  Future<Result<Event>> getEventById(String id, {String? currentUserId});

  Future<Result<void>> registerForEvent({required String eventId, required String userId});

  Future<Result<void>> cancelRegistration({required String eventId, required String userId});

  /// Validates a scanned QR payload and records attendance. Returns the
  /// attendee's display name on success so the officer scanning gets
  /// immediate visual confirmation.
  Future<Result<String>> checkInWithQrCode({
    required String eventId,
    required String qrCode,
    required String officerId,
  });

  /// Manual check-in for a registered member (no QR available).
  Future<Result<String>> checkInMember({required String eventId, required String userId});

  Future<Result<List<EventAttendee>>> getAttendees(String eventId);

  Future<Result<void>> createEvent({
    required String title,
    required String description,
    required EventCategory category,
    required DateTime startAt,
    required DateTime endAt,
    String? venueName,
    String? venueAddress,
    double? latitude,
    double? longitude,
    required bool isOnline,
    String? onlineUrl,
    int? capacity,
    DateTime? registrationDeadline,
    String? bannerUrl,
    required String createdBy,
    String? partnerId,
  });

  Future<Result<void>> updateEvent({
    required String id,
    required String title,
    required String description,
    required EventCategory category,
    required DateTime startAt,
    required DateTime endAt,
    String? venueName,
    String? venueAddress,
    double? latitude,
    double? longitude,
    required bool isOnline,
    String? onlineUrl,
    int? capacity,
    DateTime? registrationDeadline,
    String? bannerUrl,
    required EventStatus status,
    String? partnerId,
  });

  Future<Result<void>> deleteEvent(String id);
}
