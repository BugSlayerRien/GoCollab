import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../widgets/settings_widgets.dart';

class SignInSecurityScreen extends ConsumerWidget {
  const SignInSecurityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Sign-in & Security')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          if (user != null) ...[
            SettingsGroup(
              children: [
                SettingsTile(
                  icon: Icons.mail_outline_rounded,
                  title: 'Email',
                  subtitle: user.email,
                ),
                SettingsTile(
                  icon: Icons.verified_user_outlined,
                  title: 'Account role',
                  subtitle: user.role.label,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          const SettingsSectionHeader('Password'),
          SettingsGroup(
            children: [
              SettingsTile(
                icon: Icons.lock_outline_rounded,
                title: 'Change password',
                subtitle: 'Send a reset link to your email',
                onTap: () => context.push('/forgot-password'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'If you signed in with Google, manage your password from your Google Account settings.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
