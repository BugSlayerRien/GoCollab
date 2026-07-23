import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Mirrors the `type` check constraint on `public.notifications` — each
/// value corresponds to one of the push-notification categories called out
/// in the spec (announcements, event reminders, registration confirmations,
/// career opportunities, partnership updates).
enum NotificationType {
  announcement,
  eventReminder,
  registrationConfirmation,
  careerOpportunity,
  partnershipUpdate,
  general;

  static NotificationType fromKey(String key) {
    return switch (key) {
      'announcement' => NotificationType.announcement,
      'event_reminder' => NotificationType.eventReminder,
      'registration_confirmation' => NotificationType.registrationConfirmation,
      'career_opportunity' => NotificationType.careerOpportunity,
      'partnership_update' => NotificationType.partnershipUpdate,
      _ => NotificationType.general,
    };
  }

  IconData get icon => switch (this) {
        NotificationType.announcement => Icons.campaign_rounded,
        NotificationType.eventReminder => Icons.event_rounded,
        NotificationType.registrationConfirmation => Icons.check_circle_rounded,
        NotificationType.careerOpportunity => Icons.work_rounded,
        NotificationType.partnershipUpdate => Icons.handshake_rounded,
        NotificationType.general => Icons.notifications_rounded,
      };

  Color get color => switch (this) {
        NotificationType.announcement => AppColors.googleBlue,
        NotificationType.eventReminder => AppColors.googleYellow,
        NotificationType.registrationConfirmation => AppColors.googleGreen,
        NotificationType.careerOpportunity => AppColors.googleGreen,
        NotificationType.partnershipUpdate => AppColors.googleRed,
        NotificationType.general => AppColors.googleBlue,
      };
}

/// An in-app notification record (`public.notifications`). Populated either
/// directly by officers (announcements, partnership updates) or by database
/// triggers/Edge Functions reacting to registrations, deadlines, etc., and
/// mirrored to the device via FCM by [NotificationService].
class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.referenceType,
    this.referenceId,
  });

  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final bool isRead;
  final DateTime createdAt;
  final String? referenceType;
  final String? referenceId;

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        title: title,
        body: body,
        type: type,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
        referenceType: referenceType,
        referenceId: referenceId,
      );

  @override
  List<Object?> get props => [id, title, body, type, isRead, createdAt, referenceType, referenceId];
}
