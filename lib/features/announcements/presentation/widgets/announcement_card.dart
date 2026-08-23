import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/creator_attribution.dart';
import '../../domain/entities/announcement.dart';

class AnnouncementCard extends StatelessWidget {
  const AnnouncementCard({
    super.key,
    required this.announcement,
    this.onEdit,
    this.onDelete,
  });

  final Announcement announcement;
  final VoidCallback? onEdit;
  final Future<void> Function()? onDelete;

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
        color: context.appSurfaceMuted,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: context.appBorder),
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
              if (onEdit != null)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Edit',
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: onEdit,
                ),
              if (onDelete != null)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Delete',
                  icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.googleRed),
                  onPressed: () => onDelete!.call(),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(announcement.title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(announcement.body, style: Theme.of(context).textTheme.bodyMedium),
          if (announcement.creator != null) ...[
            const SizedBox(height: AppSpacing.sm),
            CreatorAttribution(label: 'Posted by', creator: announcement.creator, compact: true),
          ],
        ],
      ),
    );
  }
}
