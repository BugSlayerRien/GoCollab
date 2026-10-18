import 'package:flutter/material.dart';
import '../../../../core/animations/prismatic_background.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../notifications/presentation/widgets/notification_badge.dart';

/// The dashboard's signature "premium" header — a prismatic-animated card
/// greeting the member/officer by name. Per placement guidance this is one
/// of the explicitly-approved surfaces for the flowing prismatic effect.
class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    required this.user,
    this.onNotificationsTap,
    this.onProfileTap,
    this.unreadNotificationCount = 0,
    this.communityPoints,
    this.leading,
  });

  final AppUser user;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onProfileTap;
  final int unreadNotificationCount;
  final int? communityPoints;

  /// e.g. the sidebar burger button for officers.
  final Widget? leading;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      child: Container(
        height: 150 * MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.3),
        decoration: BoxDecoration(color: context.appSurface, borderRadius: BorderRadius.circular(AppSpacing.radiusXl)),
        child: PrismaticBackground(
          opacity: 0.34,
          loopDuration: const Duration(seconds: 14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (leading != null) ...[leading!, const SizedBox(width: AppSpacing.xs)],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _greeting,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.appTextSecondary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.fullName.split(' ').first,
                        style: Theme.of(context).textTheme.headlineMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 16, color: AppColors.googleYellow),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '${communityPoints ?? user.points} community points',
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                NotificationBellButton(
                  unreadCount: unreadNotificationCount,
                  onPressed: onNotificationsTap ?? () {},
                ),
                if (onProfileTap != null) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Tooltip(
                    message: 'Profile',
                    child: InkWell(
                      onTap: onProfileTap,
                      customBorder: const CircleBorder(),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.googleBlue,
                          backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                          child: user.avatarUrl == null
                              ? Text(
                                  user.initials,
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
