import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/google_calendar_event.dart';

class GoogleCalendarEventTile extends StatelessWidget {
  const GoogleCalendarEventTile({
    super.key,
    required this.event,
    this.onTap,
  });

  final GoogleCalendarEvent event;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = event.isGoCollabEvent ? AppColors.googleBlue : AppColors.googleGreen;

    return Material(
      color: context.appSurfaceMuted,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: event.isGoCollabEvent ? AppColors.googleBlue.withValues(alpha: 0.35) : context.appBorder,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 48,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            event.title,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        if (event.isGoCollabEvent)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.googleBlue.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                            ),
                            child: Text(
                              'GoCollab',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppColors.googleBlue,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded, size: 14, color: context.appTextSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.isAllDay
                                ? 'All day • ${DateFormatter.date(event.startAt)}'
                                : DateFormatter.range(event.startAt, event.endAt),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: context.appTextSecondary,
                                ),
                          ),
                        ),
                      ],
                    ),
                    if (event.location != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Icon(Icons.place_outlined, size: 14, color: context.appTextSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              event.location!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: context.appTextSecondary,
                                  ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (onTap != null)
                Icon(Icons.chevron_right_rounded, color: context.appTextDisabled, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
