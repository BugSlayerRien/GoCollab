import '../../../../core/errors/exception_mapper.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/event.dart';
import '../../domain/repositories/event_repository.dart';
import '../datasources/event_remote_datasource.dart';

class EventRepositoryImpl implements EventRepository {
  EventRepositoryImpl(this._dataSource);

  final EventRemoteDataSource _dataSource;

  @override
  Future<Result<List<Event>>> getEvents({String? currentUserId}) async {
    try {
      final events = await _dataSource.getEvents(currentUserId: currentUserId);
      return Result.success(events);
    } catch (e) {
      return Result.failure(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<Event>> getEventById(String id, {String? currentUserId}) async {
    try {
      final event = await _dataSource.getEventById(id, currentUserId: currentUserId);
      return Result.success(event);
    } catch (e) {
      return Result.failure(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> registerForEvent({required String eventId, required String userId}) async {
    try {
      await _dataSource.registerForEvent(eventId: eventId, userId: userId);
      return const Result.success(null);
    } catch (e) {
      return Result.failure(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> cancelRegistration({required String eventId, required String userId}) async {
    try {
      await _dataSource.cancelRegistration(eventId: eventId, userId: userId);
      return const Result.success(null);
    } catch (e) {
      return Result.failure(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<String>> checkInWithQrCode({
    required String eventId,
    required String qrCode,
    required String officerId,
  }) async {
    try {
      final name = await _dataSource.checkInWithQrCode(eventId: eventId, qrCode: qrCode, officerId: officerId);
      return Result.success(name);
    } catch (e) {
      return Result.failure(mapExceptionToFailure(e));
    }
  }

  @override
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
  }) async {
    try {
      await _dataSource.createEvent(
        title: title,
        description: description,
        category: category,
        startAt: startAt,
        endAt: endAt,
        venueName: venueName,
        venueAddress: venueAddress,
        latitude: latitude,
        longitude: longitude,
        isOnline: isOnline,
        onlineUrl: onlineUrl,
        capacity: capacity,
        registrationDeadline: registrationDeadline,
        bannerUrl: bannerUrl,
        createdBy: createdBy,
        partnerId: partnerId,
      );
      return const Result.success(null);
    } catch (e) {
      return Result.failure(mapExceptionToFailure(e));
    }
  }

  @override
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
  }) async {
    try {
      await _dataSource.updateEvent(
        id: id,
        title: title,
        description: description,
        category: category,
        startAt: startAt,
        endAt: endAt,
        venueName: venueName,
        venueAddress: venueAddress,
        latitude: latitude,
        longitude: longitude,
        isOnline: isOnline,
        onlineUrl: onlineUrl,
        capacity: capacity,
        registrationDeadline: registrationDeadline,
        bannerUrl: bannerUrl,
        status: status,
        partnerId: partnerId,
      );
      return const Result.success(null);
    } catch (e) {
      return Result.failure(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> deleteEvent(String id) async {
    try {
      await _dataSource.deleteEvent(id);
      return const Result.success(null);
    } catch (e) {
      return Result.failure(mapExceptionToFailure(e));
    }
  }
}
