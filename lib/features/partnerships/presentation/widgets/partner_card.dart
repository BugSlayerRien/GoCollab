import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/entities/partner.dart';

class PartnerCard extends StatelessWidget {
  const PartnerCard({super.key, required this.partner, required this.onTap});

  final Partner partner;
  final VoidCallback onTap;

  StatusBadge _statusBadge(CollaborationStatus status) {
    return switch (status) {
      CollaborationStatus.active => StatusBadge.success('Active'),
      CollaborationStatus.prospect => StatusBadge.pending('Prospect'),
      CollaborationStatus.onHold => StatusBadge.pending('On Hold'),
      CollaborationStatus.ended => StatusBadge.alert('Ended'),
    };
  }

  @override
  Widget build(BuildContext context) {
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
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.googleBlue.withValues(alpha: 0.12),
                  backgroundImage: partner.logoUrl != null ? NetworkImage(partner.logoUrl!) : null,
                  child: partner.logoUrl == null
                      ? Text(partner.name.isNotEmpty ? partner.name[0].toUpperCase() : '?')
                      : null,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(partner.name, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        partner.category.label,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                _statusBadge(partner.collaborationStatus),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
