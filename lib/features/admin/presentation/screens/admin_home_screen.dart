import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// Admin tab: platform maintenance only. Day-to-day chapter work (events,
/// verification, claims) stays with each chapter's officers.
class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    return Scaffold(
      appBar: AppBar(title: const Text('Administration')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            'Hello${user == null ? '' : ', ${user.fullName.split(' ').first}'}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'You maintain the platform: chapters, officers and the audit trail. '
            "Chapter officers handle events, verification and claims for their own chapter.",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.appTextSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          _AdminTile(
            icon: Icons.apartment_rounded,
            title: 'Chapters',
            subtitle: 'Create, deactivate or remove chapters',
            onTap: () => context.push('/admin/chapters'),
          ),
          _AdminTile(
            icon: Icons.manage_accounts_rounded,
            title: 'Members & roles',
            subtitle: 'Appoint or remove officers, move members between chapters',
            onTap: () => context.push('/admin/members'),
          ),
          _AdminTile(
            icon: Icons.history_rounded,
            title: 'Audit log',
            subtitle: 'Who approved, rejected or changed what',
            onTap: () => context.push('/audit-log'),
          ),
        ],
      ),
    );
  }
}

class _AdminTile extends StatelessWidget {
  const _AdminTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
