import '../../../../core/utils/result.dart';
import '../entities/event.dart';

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
}
