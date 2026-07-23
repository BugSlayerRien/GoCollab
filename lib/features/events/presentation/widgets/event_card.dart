import 'package:flutter/material.dart';
import '../../../../core/animations/prismatic_glow_border.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/entities/event.dart';

/// Card used across the dashboard's "Upcoming events" rail and the Events
/// tab list. Featured events get the animated [PrismaticGlowBorder]
/// treatment per the design spec's placement guidance.
class EventCard extends StatelessWidget {
  const EventCard({super.key, required this.event, required this.onTap, this.dense = false});

  final Event event;
  final VoidCallback onTap;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final card = _CardContent(event: event, onTap: onTap, dense: dense);
    if (event.isFeatured) {
      return PrismaticGlowBorder(borderRadius: AppSpacing.radiusLg, child: card);
    }
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLightGray,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: card,
    );
  }
}

class _CardContent extends StatelessWidget {
  const _CardContent({required this.event, required this.onTap, required this.dense});

  final Event event;
  final VoidCallback onTap;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceLightGray,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  StatusBadge.pending(event.category.label),
                  const SizedBox(width: AppSpacing.xs),
                  if (event.isRegistered) StatusBadge.success('Registered'),
                  const Spacer(),
                  if (event.isFeatured)
                    const Icon(Icons.auto_awesome_rounded, size: 16, color: AppColors.googleYellow),
                ],
              ),
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
                  const Icon(Icons.schedule_rounded, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      DateFormatter.weekdayDate(event.startAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
              if (!dense) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      event.isOnline ? Icons.videocam_outlined : Icons.place_outlined,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        event.isOnline ? 'Online' : (event.venueName ?? 'Venue TBA'),
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
