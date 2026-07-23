import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/supabase_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/notification_remote_datasource.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';

final notificationRemoteDataSourceProvider = Provider<NotificationRemoteDataSource>((ref) {
  return NotificationRemoteDataSource(ref.watch(supabaseClientProvider));
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepositoryImpl(ref.watch(notificationRemoteDataSourceProvider));
});

/// Live (Supabase Realtime) feed of the signed-in user's notifications.
/// Emits an empty list — rather than erroring — while signed out.
final notificationsProvider = StreamProvider.autoDispose<List<AppNotification>>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return Stream.value(const []);
  return ref.watch(notificationRepositoryProvider).watchNotifications(user.id);
});

/// Derived unread count, driving the pulsing badge on the dashboard bell icon.
final unreadNotificationCountProvider = Provider.autoDispose<int>((ref) {
  final notifications = ref.watch(notificationsProvider).valueOrNull ?? const [];
  return notifications.where((n) => !n.isRead).length;
});

class NotificationActionsController extends StateNotifier<bool> {
  NotificationActionsController(this._ref) : super(false);
  final Ref _ref;

  Future<void> markAsRead(String notificationId) async {
    await _ref.read(notificationRepositoryProvider).markAsRead(notificationId);
  }

  Future<void> markAllAsRead() async {
    final user = _ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;
    state = true;
    await _ref.read(notificationRepositoryProvider).markAllAsRead(user.id);
    state = false;
  }
}

final notificationActionsControllerProvider =
    StateNotifierProvider.autoDispose<NotificationActionsController, bool>(
  (ref) => NotificationActionsController(ref),
);
