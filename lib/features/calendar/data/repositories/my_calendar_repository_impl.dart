import '../../../../core/errors/failure.dart';
import '../../../../core/services/google_calendar_service.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/google_calendar_event.dart';
import '../../domain/repositories/my_calendar_repository.dart';
import '../datasources/my_calendar_remote_datasource.dart';

class MyCalendarRepositoryImpl implements MyCalendarRepository {
  MyCalendarRepositoryImpl(this._dataSource);

  final MyCalendarRemoteDataSource _dataSource;

  @override
  Future<bool> hasCalendarAccess() => _dataSource.hasCalendarAccess();

  @override
  Future<Result<List<GoogleCalendarEvent>>> fetchEventsInRange({
    required String userId,
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) async {
    try {
      final events = await _dataSource.fetchEventsInRange(
        userId: userId,
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
      );
      return Result.success(events);
    } on CalendarAuthException catch (e) {
      return Result.failure(AuthFailure(e.message ?? e.toString()));
    } on CalendarApiException catch (e) {
      return Result.failure(ServerFailure(e.message));
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('SocketException') || msg.contains('NetworkException')) {
        return const Result.failure(NetworkFailure());
      }
      return Result.failure(ServerFailure(msg));
    }
  }
}
