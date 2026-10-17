import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/in_app_browser.dart';

class _GoogleProgram {
  const _GoogleProgram(this.title, this.blurb, this.url, this.icon);
  final String title;
  final String blurb;
  final String url;
  final IconData icon;
}

// Links last checked 2026-10. These are Google's own pages, so they are listed
// here rather than posted as opportunities; officer-posted openings stay below.
const _programs = [
  _GoogleProgram(
    'Google STEP internship',
    'Paid internship for first and second-year university students.',
    'https://buildyourfuture.withgoogle.com/internships/step',
    Icons.work_outline_rounded,
  ),
  _GoogleProgram(
    'Google Summer of Code',
    'Contribute to open-source projects with a stipend.',
    'https://summerofcode.withgoogle.com',
    Icons.code_rounded,
  ),
  _GoogleProgram(
    'Google Skills',
    'Free cloud and AI learning paths with hands-on labs.',
    'https://www.skills.google',
    Icons.school_outlined,
  ),
  _GoogleProgram(
    'Developer certifications',
    'Prove your skills in Android, Cloud and web development.',
    'https://developers.google.com/certification',
    Icons.verified_outlined,
  ),
  _GoogleProgram(
    'Google Career Certificates',
    'Job-ready training in data, UX, cybersecurity and more.',
    'https://grow.google/certificates',
    Icons.workspace_premium_outlined,
  ),
  _GoogleProgram(
    'Google for Startups',
    'Programs and resources for student founders.',
    'https://startup.google.com',
    Icons.rocket_launch_outlined,
  ),
  _GoogleProgram(
    'Google Developer Program',
    'Join the developer community and unlock member benefits.',
    'https://developers.google.com/program',
    Icons.groups_outlined,
  ),
];

/// "Google programs" entry shown under the Career Hub categories. Tapping it
/// opens a modal listing the programs; each one opens inside the app.
class GoogleProgramsSection extends StatelessWidget {
  const GoogleProgramsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.xs),
      child: Material(
        color: context.appSurfaceMuted,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          onTap: () => _showPrograms(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: context.appBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_rounded),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Google programs', style: Theme.of(context).textTheme.titleSmall),
                      Text(
                        'Internships, learning and certifications from Google',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.appTextSecondary),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPrograms(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.xs),
              child: Text('Google programs', style: Theme.of(sheetContext).textTheme.titleMedium),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final p in _programs)
                    ListTile(
                      leading: Icon(p.icon),
                      title: Text(p.title),
                      subtitle: Text(p.blurb),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        openInApp(context, p.url, title: p.title);
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
