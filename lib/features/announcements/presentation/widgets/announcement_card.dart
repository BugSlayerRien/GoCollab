import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/entities/announcement.dart';

class AnnouncementCard extends StatelessWidget {
  const AnnouncementCard({super.key, required this.announcement});

  final Announcement announcement;

  Color _categoryColor(AnnouncementCategory category) {
    return switch (category) {
      AnnouncementCategory.career => AppColors.googleGreen,
      AnnouncementCategory.event => AppColors.googleYellow,
      AnnouncementCategory.partnership => AppColors.googleRed,
      AnnouncementCategory.urgent => AppColors.googleRed,
      AnnouncementCategory.general => AppColors.googleBlue,
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor(announcement.category);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceLightGray,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (announcement.isPinned) ...[
                const Icon(Icons.push_pin_rounded, size: 14, color: AppColors.googleRed),
                const SizedBox(width: 4),
              ],
              StatusBadge(label: announcement.category.label, color: color),
              const Spacer(),
              Text(
                timeago.format(announcement.publishedAt),
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(announcement.title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(announcement.body, style: Theme.of(context).textTheme.bodyMedium),
          if (announcement.authorName != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              '— ${announcement.authorName}',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ],
      ),
    );
  }
}
