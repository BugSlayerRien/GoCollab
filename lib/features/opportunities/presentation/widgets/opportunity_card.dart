import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/entities/opportunity.dart';
import '../providers/opportunity_providers.dart';

class OpportunityCard extends ConsumerWidget {
  const OpportunityCard({super.key, required this.opportunity, required this.onTap});

  final Opportunity opportunity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daysLeft = opportunity.daysUntilDeadline;
    final isUrgent = daysLeft != null && daysLeft <= 5 && daysLeft >= 0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLightGray,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Material(
        color: Colors.transparent,
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
                    StatusBadge.success(opportunity.type.label),
                    const Spacer(),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        opportunity.isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                        color: opportunity.isSaved ? AppColors.googleBlue : AppColors.textSecondary,
                      ),
                      onPressed: () => ref.read(savedOpportunityControllerProvider.notifier).toggle(opportunity),
                    ),
                  ],
                ),
                Text(opportunity.title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  opportunity.organization,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(
                      opportunity.isRemote ? Icons.public_rounded : Icons.location_on_outlined,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        opportunity.isRemote ? 'Remote' : (opportunity.location ?? 'Location TBA'),
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (daysLeft != null)
                      StatusBadge(
                        label: daysLeft <= 0 ? 'Closed' : '$daysLeft d left',
                        color: isUrgent ? AppColors.googleRed : AppColors.googleYellow,
                        icon: Icons.timer_outlined,
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
