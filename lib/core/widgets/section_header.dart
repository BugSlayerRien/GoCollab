import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// "Section title" + "See all" affordance used across the Dashboard for
/// each content rail (Announcements, Upcoming events, Saved opportunities).
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.onSeeAll});

  final String title;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            style: TextButton.styleFrom(foregroundColor: AppColors.googleBlue, padding: EdgeInsets.zero),
            child: const Text('See all'),
          ),
      ],
    );
  }
}
