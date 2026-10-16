import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/app_button.dart';

class _Section {
  const _Section(this.title, this.points);
  final String title;
  final List<String> points;
}

const _sections = [
  _Section('Be respectful', [
    'Treat every member, officer and partner with courtesy. No harassment, hate speech, bullying or discrimination.',
    'Keep discussion and announcements relevant to the chapter and campus community.',
  ]),
  _Section('Use your real identity', [
    'Sign up with your own name. One person, one account.',
    'Your school email or school ID is used only to confirm you are a student member. ID photos are stored privately and are visible only to chapter officers.',
    'Never submit someone else’s ID or a doctored photo.',
  ]),
  _Section('Events and attendance', [
    'Register only for events you plan to attend, and cancel if your plans change so others can take the slot.',
    'Your QR code is personal. Do not share it or check in on behalf of someone else.',
    'Attendance is recorded by officers at the event.',
  ]),
  _Section('Points and opportunities', [
    'Community points reward genuine participation. Do not fake attendance or submit false proof of an application.',
    'Screenshots submitted to claim points are reviewed by officers. Fabricated proof can lead to points being removed.',
    'Only apply to opportunities you are actually eligible for.',
  ]),
  _Section('Privacy and safety', [
    'Do not share other members’ personal information without their consent.',
    'Report suspicious activity or content to a chapter officer.',
  ]),
  _Section('Moderation', [
    'Officers may remove content or restrict accounts that break these guidelines.',
    'Repeated or serious violations may result in removal from the community.',
  ]),
];

/// Shows the community guidelines in a scrollable sheet. Resolves to `true`
/// when the member taps "I agree", so callers can tick their checkbox.
Future<bool> showCommunityGuidelines(BuildContext context) async {
  final agreed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Column(
        children: [
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
              children: [
                Text('Community guidelines', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'GoCollab is built around a trusted student community. By joining, you agree to the following.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.appTextSecondary),
                ),
                const SizedBox(height: AppSpacing.lg),
                for (final section in _sections) ...[
                  Text(section.title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  for (final point in section.points)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 7, right: AppSpacing.sm),
                            child: Icon(Icons.circle, size: 5),
                          ),
                          Expanded(child: Text(point, style: Theme.of(context).textTheme.bodyMedium)),
                        ],
                      ),
                    ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Close',
                    variant: AppButtonVariant.outlined,
                    onPressed: () => Navigator.of(sheetContext).pop(false),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppButton(label: 'I agree', onPressed: () => Navigator.of(sheetContext).pop(true)),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
  return agreed ?? false;
}
