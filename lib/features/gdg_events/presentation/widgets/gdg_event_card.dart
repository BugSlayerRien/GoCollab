import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/entities/gdg_event.dart';

/// Row card for an event from a GDG chapter, styled like [EventCard].
class GdgEventCard extends StatelessWidget {
  const GdgEventCard({super.key, required this.event, required this.onTap});

  final GdgEvent event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final place = [event.city, event.country].whereType<String>().where((s) => s.isNotEmpty).join(', ');
    return Container(
      decoration: BoxDecoration(
        color: context.appSurfaceMuted,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: context.appBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatusBadge(label: 'GDG Community', color: AppColors.googleBlue, icon: Icons.public_rounded),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  event.title,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: 14, color: context.appTextSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        DateFormatter.weekdayDate(event.startAt),
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.groups_outlined, size: 14, color: context.appTextSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        place.isEmpty ? event.chapterName : '${event.chapterName} · $place',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.appTextSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
