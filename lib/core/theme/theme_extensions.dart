import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Convenience accessors so widgets can pick light/dark surface & text colors
/// without hardcoding [Brightness] checks at every call site.
extension GoCollabThemeX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get appSurface => isDark ? AppColors.darkSurface : AppColors.surfaceWhite;
  Color get appSurfaceMuted => isDark ? AppColors.darkSurfaceMuted : AppColors.surfaceLightGray;
  Color get appBorder => isDark ? AppColors.darkBorder : AppColors.surfaceBorder;
  Color get appTextPrimary => isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
  Color get appTextSecondary => isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
  Color get appTextDisabled => isDark ? AppColors.darkTextDisabled : AppColors.textDisabled;
}
