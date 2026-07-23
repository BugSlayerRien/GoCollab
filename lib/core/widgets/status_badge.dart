import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Small pill-shaped badge used for opportunity types, event status,
/// registration state, and partnership collaboration status — keeps color
/// semantics consistent with the design spec (green = success/career,
/// yellow = pending/event, red = alert/deadline, blue = default/info).
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, this.color = AppColors.googleBlue, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  factory StatusBadge.success(String label) => StatusBadge(label: label, color: AppColors.googleGreen);
  factory StatusBadge.pending(String label) => StatusBadge(label: label, color: AppColors.googleYellow);
  factory StatusBadge.alert(String label) => StatusBadge(label: label, color: AppColors.googleRed);
  factory StatusBadge.info(String label) => StatusBadge(label: label, color: AppColors.googleBlue);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
