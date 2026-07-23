import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

enum AppButtonVariant { filled, outlined, text }

/// A single, reusable button widget covering every visual variant used in
/// the app (filled CTA, outlined secondary, text/tertiary) with a built-in
/// loading spinner state — avoids duplicating `ElevatedButton` +
/// `CircularProgressIndicator` boilerplate across every screen.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.filled,
    this.isLoading = false,
    this.icon,
    this.expand = true,
    this.color,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final bool expand;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = isLoading ? null : onPressed;
    final child = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              valueColor: AlwaysStoppedAnimation<Color>(
                variant == AppButtonVariant.filled ? Colors.white : (color ?? AppColors.googleBlue),
              ),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(label),
            ],
          );

    Widget button;
    switch (variant) {
      case AppButtonVariant.filled:
        button = ElevatedButton(
          onPressed: effectiveOnPressed,
          style: color != null ? ElevatedButton.styleFrom(backgroundColor: color) : null,
          child: child,
        );
      case AppButtonVariant.outlined:
        button = OutlinedButton(
          onPressed: effectiveOnPressed,
          style: color != null
              ? OutlinedButton.styleFrom(foregroundColor: color, side: BorderSide(color: color!))
              : null,
          child: child,
        );
      case AppButtonVariant.text:
        button = TextButton(
          onPressed: effectiveOnPressed,
          style: color != null ? TextButton.styleFrom(foregroundColor: color) : null,
          child: child,
        );
    }

    return expand ? SizedBox(width: double.infinity, height: 52, child: button) : button;
  }
}
