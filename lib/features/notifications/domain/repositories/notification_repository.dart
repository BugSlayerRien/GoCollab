import '../../../../core/utils/result.dart';
import '../entities/app_notification.dart';

abstract class NotificationRepository {
  /// Live feed of the signed-in user's notifications, newest first, backed
  /// by Supabase Realtime so the list and unread badge update instantly
  /// when an officer publishes an announcement or a trigger fires.
  Stream<List<AppNotification>> watchNotifications(String userId);

  Future<Result<void>> markAsRead(String notificationId);

  Future<Result<void>> markAllAsRead(String userId);
}
