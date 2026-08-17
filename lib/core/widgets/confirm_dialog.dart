import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Destructive-action confirmation. Returns `true` only if the user
/// explicitly confirms; dismissed dialogs return `false`.
Future<bool> confirmDestructiveAction(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Delete',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.googleRed),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

void showActionFeedback(
  BuildContext context, {
  required bool success,
  required String successMessage,
  String? errorMessage,
  ScaffoldMessengerState? messenger,
  bool isWarning = false,
}) {
  final target = messenger ?? ScaffoldMessenger.maybeOf(context);
  if (target == null) return;
  target.clearSnackBars();
  target.showSnackBar(
    SnackBar(
      content: Text(success ? successMessage : (errorMessage ?? 'Something went wrong. Please try again.')),
      backgroundColor: success
          ? AppColors.googleGreen
          : isWarning
              ? AppColors.googleYellow
              : AppColors.googleRed,
    ),
  );
}
