import 'package:flutter/material.dart';
import '../../../../core/animations/prismatic_background.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/domain/entities/app_user.dart';

/// The dashboard's signature "premium" header — a prismatic-animated card
/// greeting the member/officer by name. Per placement guidance this is one
/// of the explicitly-approved surfaces for the flowing prismatic effect.
class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key, required this.user, this.onNotificationsTap});

  final AppUser user;
  final VoidCallback? onNotificationsTap;

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
        height: 150,
        decoration: BoxDecoration(color: AppColors.surfaceWhite, borderRadius: BorderRadius.circular(AppSpacing.radiusXl)),
        child: PrismaticBackground(
          opacity: 0.16,
          loopDuration: const Duration(seconds: 18),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_greeting, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
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
                          Text('${user.points} community points', style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: onNotificationsTap,
                  icon: const Icon(Icons.notifications_none_rounded),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
