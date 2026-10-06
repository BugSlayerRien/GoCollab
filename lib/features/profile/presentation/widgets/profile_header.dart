import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/animations/prismatic_glow_border.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../providers/profile_providers.dart';

class ProfileHeader extends ConsumerWidget {
  const ProfileHeader({super.key, required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final points = ref.watch(communityPointsProvider).valueOrNull ?? user.points;
    return PrismaticGlowBorder(
      borderRadius: AppSpacing.radiusLg,
      child: Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.appSurfaceMuted,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg - 2),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.googleBlue,
            backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
            child: user.avatarUrl == null
                ? Text(user.initials, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700))
                : null,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.fullName, style: Theme.of(context).textTheme.titleLarge, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(user.email, style: Theme.of(context).textTheme.bodySmall, overflow: TextOverflow.ellipsis),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
                      decoration: BoxDecoration(
                        color: (user.role == UserRole.officer ? AppColors.googleRed : AppColors.googleBlue)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                      ),
                      child: Text(
                        user.role.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: user.role == UserRole.officer ? AppColors.googleRed : AppColors.googleBlue,
                        ),
                      ),
                    ),
                    if (user.isVerified) ...[
                      const SizedBox(width: AppSpacing.xs),
                      Icon(Icons.verified_rounded, size: 14, color: AppColors.googleGreen),
                      const SizedBox(width: 2),
                      Text(
                        'Verified',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.googleGreen,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                    const SizedBox(width: AppSpacing.xs),
                    Icon(Icons.star_rounded, size: 14, color: AppColors.googleYellow),
                    const SizedBox(width: 2),
                    Text('$points pts', style: Theme.of(context).textTheme.labelSmall),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }
}
