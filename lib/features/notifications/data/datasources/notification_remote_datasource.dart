import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_notification_model.dart';

class NotificationRemoteDataSource {
  NotificationRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<List<AppNotificationModel>> fetchNotifications(String userId) async {
    final rows = await _client
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (rows as List).map((row) => AppNotificationModel.fromMap(row as Map<String, dynamic>)).toList();
  }

  List<AppNotificationModel> _sortRows(List<Map<String, dynamic>> rows) {
    final list = rows.map(AppNotificationModel.fromMap).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  /// REST fetch first (always works with RLS), then Realtime updates when
  /// available. Supabase `.stream().order()` is unreliable on web, so we
  /// sort client-side and fall back to polling on stream errors.
  Stream<List<AppNotificationModel>> watchNotifications(String userId) async* {
    yield await fetchNotifications(userId);

    try {
      await for (final rows in _client.from('notifications').stream(primaryKey: ['id']).eq('user_id', userId)) {
        yield _sortRows(rows.cast<Map<String, dynamic>>());
      }
    } catch (_) {
      while (true) {
        await Future<void>.delayed(const Duration(seconds: 30));
        yield await fetchNotifications(userId);
      }
    }
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
