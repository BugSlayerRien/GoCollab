import '../../../../core/errors/exception_mapper.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_remote_datasource.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl(this._dataSource);

  final NotificationRemoteDataSource _dataSource;

  @override
  Stream<List<AppNotification>> watchNotifications(String userId) {
    return _dataSource.watchNotifications(userId);
  }

  @override
  Future<Result<void>> markAsRead(String notificationId) async {
    try {
      await _dataSource.markAsRead(notificationId);
      return const Result.success(null);
    } catch (e) {
      return Result.failure(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void>> markAllAsRead(String userId) async {
    try {
      await _dataSource.markAllAsRead(userId);
      return const Result.success(null);
    } catch (e) {
      return Result.failure(mapExceptionToFailure(e));
    }
  }
}
