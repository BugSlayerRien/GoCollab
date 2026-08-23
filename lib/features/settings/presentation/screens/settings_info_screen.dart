import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';

/// Scrollable text screen for About, Terms, and Privacy Policy content.
class SettingsInfoScreen extends StatelessWidget {
  const SettingsInfoScreen({super.key, required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(body, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
