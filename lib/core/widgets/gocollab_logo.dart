import 'package:flutter/material.dart';
import '../constants/app_assets.dart';
import '../theme/app_spacing.dart';

/// Official GoCollab prismatic bracket logo mark.
class GoCollabLogo extends StatelessWidget {
  const GoCollabLogo({
    super.key,
    this.size = 88,
    this.borderRadius,
    this.showShadow = false,
  });

  final double size;
  final double? borderRadius;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? AppSpacing.radiusXl;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        AppAssets.gocollabLogo,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => ColoredBox(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            Icons.groups_2_rounded,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            size: size * 0.5,
          ),
        ),
      ),
    );
  }
}
