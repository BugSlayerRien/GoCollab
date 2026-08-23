import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_mode_provider.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/notification_preferences_provider.dart';
import '../widgets/settings_widgets.dart';
import 'privacy_settings_screen.dart';
import 'settings_info_screen.dart';
import 'sign_in_security_screen.dart';

const _appVersion = '1.0.0';
const _buildNumber = '1';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final notifPrefs = ref.watch(notificationPreferencesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const SettingsSectionHeader('Appearance'),
          SettingsGroup(
            children: [
              AppearanceSettingsTile(
                isDark: isDark,
                onChanged: (value) => ref.read(themeModeProvider.notifier).toggleDark(value),
              ),
            ],
          ),
          const SettingsSectionHeader('Notifications'),
          Text(
            'Push Notifications',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          SettingsGroup(
            children: [
              SettingsSwitchTile(
                icon: Icons.event_available_outlined,
                title: 'Event Reminders',
                subtitle: 'Reminders before events you registered for.',
                value: notifPrefs.eventReminders,
                onChanged: ref.read(notificationPreferencesProvider.notifier).setEventReminders,
              ),
              SettingsSwitchTile(
                icon: Icons.campaign_outlined,
                title: 'Community Announcements',
                subtitle: 'New posts from chapter officers.',
                value: notifPrefs.communityAnnouncements,
                onChanged: ref.read(notificationPreferencesProvider.notifier).setCommunityAnnouncements,
              ),
              SettingsSwitchTile(
                icon: Icons.work_outline_rounded,
                title: 'Opportunity Alerts',
                subtitle: 'New career hub listings and deadline reminders.',
                value: notifPrefs.opportunityAlerts,
                onChanged: ref.read(notificationPreferencesProvider.notifier).setOpportunityAlerts,
              ),
            ],
          ),
          const SettingsSectionHeader('Privacy & Security'),
          SettingsGroup(
            children: [
              SettingsTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Settings',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const PrivacySettingsScreen()),
                ),
              ),
              SettingsTile(
                icon: Icons.security_outlined,
                title: 'Sign-in & Security',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const SignInSecurityScreen()),
                ),
              ),
              SettingsTile(
                icon: Icons.delete_outline_rounded,
                title: 'Delete Account',
                titleColor: AppColors.googleRed,
                iconColor: AppColors.googleRed,
                onTap: () => _confirmDeleteAccount(context),
              ),
            ],
          ),
          const SettingsSectionHeader('App'),
          SettingsGroup(
            children: [
              SettingsTile(
                icon: Icons.info_outline_rounded,
                title: 'About GoCollab',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const SettingsInfoScreen(
                      title: 'About GoCollab',
                      body: _aboutBody,
                    ),
                  ),
                ),
              ),
              SettingsTile(
                icon: Icons.description_outlined,
                title: 'Terms of Service',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const SettingsInfoScreen(
                      title: 'Terms of Service',
                      body: _termsBody,
                    ),
                  ),
                ),
              ),
              SettingsTile(
                icon: Icons.policy_outlined,
                title: 'Privacy Policy',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const SettingsInfoScreen(
                      title: 'Privacy Policy',
                      body: _privacyPolicyBody,
                    ),
                  ),
                ),
              ),
              SettingsTile(
                icon: Icons.new_releases_outlined,
                title: 'App Version',
                subtitle: 'Version $_appVersion (build $_buildNumber)',
              ),
            ],
          ),
          const SettingsSectionHeader('Session'),
          SettingsGroup(
            children: [
              SettingsTile(
                icon: Icons.logout_rounded,
                title: 'Sign Out',
                titleColor: AppColors.googleRed,
                iconColor: AppColors.googleRed,
                onTap: () => _signOut(context, ref),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await confirmDestructiveAction(
      context,
      title: 'Sign out?',
      message: 'You will need to sign in again to access GoCollab.',
      confirmLabel: 'Sign out',
    );
    if (!confirmed) return;
    await ref.read(signOutUseCaseProvider)();
    if (context.mounted) context.go('/login');
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final confirmed = await confirmDestructiveAction(
      context,
      title: 'Delete account?',
      message:
          'This permanently removes your GoCollab profile, registrations, and saved data. '
          'Contact your chapter officer if you need help recovering your account.',
      confirmLabel: 'Request deletion',
    );
    if (!confirmed || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Account deletion requests are handled by chapter officers. '
          'We have noted your request.',
        ),
      ),
    );
  }
}

const _aboutBody = '''
GoCollab is the centralized community management app for Google Developer Groups on Campus (GDGoC) Philippines.

Built with Flutter and Supabase, GoCollab helps members discover events, career opportunities, and community announcements while giving chapter officers tools for analytics, partnerships, and engagement.

Aligned with SDG 17 — Partnerships for the Goals.
''';

const _termsBody = '''
Terms of Service

By using GoCollab you agree to use the platform respectfully and in accordance with your university and GDGoC chapter policies.

You are responsible for the accuracy of information on your profile. Officers may moderate content that violates community guidelines.

GoCollab is provided as-is for educational and community purposes. Features may change as the platform evolves.

For questions, contact your chapter officers.
''';

const _privacyPolicyBody = '''
Privacy Policy

GoCollab stores your account email, profile information, event registrations, and preferences in Supabase with row-level security.

Third-party services:
• Google Sign-In and Google Calendar (when you connect them)
• GitHub API (when you add a username)
• Firebase Cloud Messaging (optional push notifications)

We do not sell your personal data. You may request account deletion through Settings.

Data is hosted on Supabase infrastructure. See supabase.com for their privacy practices.
''';
