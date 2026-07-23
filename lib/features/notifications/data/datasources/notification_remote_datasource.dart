import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_notification_model.dart';

class NotificationRemoteDataSource {
  NotificationRemoteDataSource(this._client);

  final SupabaseClient _client;

  /// Realtime stream of a user's notifications (see
  /// `notifications_select_own` RLS policy — the server itself scopes this
  /// to `auth.uid()`, the `.eq` below just avoids fetching rows this device
  /// doesn't need to render).
  Stream<List<AppNotificationModel>> watchNotifications(String userId) {
    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((rows) => rows.map(AppNotificationModel.fromMap).toList());
  }

  Future<void> markAsRead(String notificationId) async {
    await _client.from('notifications').update({'is_read': true}).eq('id', notificationId);
  }

  Future<void> markAllAsRead(String userId) async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId)
        .eq('is_read', false);
  }
}
