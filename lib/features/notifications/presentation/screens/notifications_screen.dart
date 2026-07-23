import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../domain/entities/app_notification.dart';
import '../providers/notification_providers.dart';

/// Full notifications inbox — the in-app counterpart to the FCM push
/// notifications members receive for announcements, event reminders,
/// registration confirmations, career opportunities, and partnership
/// updates. Backed by a Supabase Realtime stream so new notifications (and
/// the dashboard's pulsing badge) appear instantly without a manual refresh.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  void _handleTap(BuildContext context, WidgetRef ref, AppNotification notification) {
    if (!notification.isRead) {
      ref.read(notificationActionsControllerProvider.notifier).markAsRead(notification.id);
    }
    switch (notification.referenceType) {
      case 'event':
        if (notification.referenceId != null) context.push('/events/${notification.referenceId}');
      case 'opportunity':
        if (notification.referenceId != null) context.push('/opportunities/${notification.referenceId}');
      case 'partner':
        if (notification.referenceId != null) context.push('/partners/${notification.referenceId}');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: () => ref.read(notificationActionsControllerProvider.notifier).markAllAsRead(),
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => const ErrorStateView(message: 'Could not load notifications.'),
        data: (notifications) {
          if (notifications.isEmpty) {
            return const EmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'No notifications yet',
              message: "Announcements, event reminders, and updates will show up here.",
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _NotificationTile(
                notification: notification,
                onTap: () => _handleTap(context, ref, notification),
              );
            },
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = notification.type.color;
    return Material(
      color: notification.isRead ? AppColors.surfaceWhite : color.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: Icon(notification.type.icon, color: color, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(notification.body, style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 4),
                    Text(timeago.format(notification.createdAt), style: Theme.of(context).textTheme.labelSmall),
                  ],
                ),
              ),
              if (!notification.isRead)
                Container(
                  margin: const EdgeInsets.only(top: 4, left: 4),
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: AppColors.googleBlue, shape: BoxShape.circle),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
