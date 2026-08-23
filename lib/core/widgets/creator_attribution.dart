import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/content_creator.dart';
import '../theme/app_spacing.dart';
import '../theme/theme_extensions.dart';

/// Subtle attribution row for content created by an officer or member.
class CreatorAttribution extends StatelessWidget {
  const CreatorAttribution({
    super.key,
    required this.label,
    this.creator,
    this.compact = false,
  });

  /// e.g. "Posted by" or "Organizer"
  final String label;
  final ContentCreator? creator;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (creator == null || !creator!.hasDisplay) return const SizedBox.shrink();

    final avatarSize = compact ? 20.0 : 24.0;

    return Row(
      children: [
        CircleAvatar(
          radius: avatarSize / 2,
          backgroundColor: context.appSurface,
          backgroundImage: creator!.avatarUrl != null
              ? CachedNetworkImageProvider(creator!.avatarUrl!)
              : null,
          child: creator!.avatarUrl == null
              ? Icon(Icons.person_rounded, size: compact ? 12 : 14, color: context.appTextSecondary)
              : null,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.appTextSecondary),
              children: [
                TextSpan(text: '$label '),
                TextSpan(
                  text: creator!.name,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.appTextPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
