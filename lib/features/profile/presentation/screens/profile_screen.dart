import '../../../shell/presentation/widgets/collapsible_sidebar.dart';
import 'package:printing/printing.dart';
import '../../domain/certificate_pdf.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/in_app_browser.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../verification/presentation/widgets/verification_prompt_card.dart';
import '../providers/profile_providers.dart';
import '../widgets/profile_header.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        leading: sidebarMenuLeading(ref),
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/profile/edit'),
          ),
        ],
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const ErrorStateView(message: 'Could not load your profile.'),
        data: (user) {
          if (user == null) return const SizedBox.shrink();
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              ProfileHeader(user: user),
              const SizedBox(height: AppSpacing.lg),
              const VerificationPromptCard(),
              if (user.bio != null && user.bio!.isNotEmpty) ...[
                Text('Bio', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(user.bio!, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: AppSpacing.lg),
              ],
              Text('Skills', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              user.skills.isEmpty
                  ? Text('No skills added yet.', style: Theme.of(context).textTheme.bodySmall)
                  : Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: user.skills.map((s) => Chip(label: Text(s))).toList(),
                    ),
              const SizedBox(height: AppSpacing.lg),
              _GithubSection(githubUsername: user.githubUsername, userId: user.id),
              const SizedBox(height: AppSpacing.lg),
              Text('Event history', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              const _EventHistorySection(),
              const SizedBox(height: AppSpacing.xxl),
              AppButton(
                label: 'Sign out',
                variant: AppButtonVariant.outlined,
                color: AppColors.googleRed,
                icon: Icons.logout_rounded,
                onPressed: () => _signOut(context, ref),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          );
        },
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
}

class _GithubSection extends ConsumerWidget {
  const _GithubSection({required this.githubUsername, required this.userId});
  final String? githubUsername;
  final String userId;

  Future<void> _sync(BuildContext context, WidgetRef ref, String username) async {
    final error = await ref.read(profileEditControllerProvider.notifier).syncGithub(
          userId: userId,
          username: username,
        );
    if (!context.mounted) return;
    showActionFeedback(
      context,
      success: error == null,
      successMessage: 'GitHub profile updated from api.github.com.',
      errorMessage: error,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (githubUsername == null || githubUsername!.isEmpty) {
      return Text(
        'Add your GitHub username in Edit Profile to load live stats from the GitHub API.',
        style: Theme.of(context).textTheme.bodySmall,
      );
    }

    final githubAsync = ref.watch(cachedGithubProfileProvider);
    final isSyncing = ref.watch(profileEditControllerProvider).isLoading;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.appSurfaceMuted,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: context.appBorder),
      ),
      child: githubAsync.when(
        loading: () => const SizedBox(height: 56, child: Center(child: CircularProgressIndicator())),
        error: (e, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              e.toString().replaceFirst('Exception: ', ''),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.googleRed),
            ),
            TextButton(
              onPressed: isSyncing ? null : () => _sync(context, ref, githubUsername!),
              child: const Text('Retry'),
            ),
          ],
        ),
        data: (stats) {
          if (stats == null) {
            return Row(
              children: [
                Expanded(child: Text('@$githubUsername', style: Theme.of(context).textTheme.bodyMedium)),
                TextButton(
                  onPressed: isSyncing ? null : () => _sync(context, ref, githubUsername!),
                  child: Text(isSyncing ? 'Syncing…' : 'Sync from GitHub'),
                ),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (stats.avatarUrl != null)
                    CircleAvatar(radius: 22, backgroundImage: NetworkImage(stats.avatarUrl!))
                  else
                    Icon(Icons.code_rounded, color: context.appTextPrimary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stats.displayName?.isNotEmpty == true ? stats.displayName! : '@${stats.username}',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text('@${stats.username}', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Refresh from GitHub',
                    icon: isSyncing
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.refresh_rounded, size: 18),
                    onPressed: isSyncing ? null : () => _sync(context, ref, githubUsername!),
                  ),
                ],
              ),
              if (stats.bio != null && stats.bio!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(stats.bio!, style: Theme.of(context).textTheme.bodySmall),
              ],
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${stats.publicRepos} repos  ·  ${stats.followers} followers  ·  ${stats.following} following',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (stats.profileUrl != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => openInApp(context, stats.profileUrl!, title: 'GitHub'),
                    child: const Text('Open GitHub profile'),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _EventHistorySection extends ConsumerWidget {
  const _EventHistorySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(eventHistoryProvider);

    return historyAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const Text('Could not load event history.'),
      data: (items) {
        if (items.isEmpty) {
          return const EmptyState(
            icon: Icons.history_rounded,
            title: 'No events yet',
            message: 'Events you register for will show up here.',
          );
        }
        return Column(
          children: items.map((item) {
            return ListTile(
              contentPadding: EdgeInsets.zero,
              onTap: () => context.push('/events/${item.eventId}'),
              leading: Icon(
                item.attended ? Icons.check_circle_rounded : Icons.event_available_rounded,
                color: item.attended ? AppColors.googleGreen : AppColors.googleYellow,
              ),
              title: Text(item.eventTitle),
              subtitle: Text(DateFormatter.date(item.eventDate)),
              trailing: item.hasCertificate
                  ? IconButton(
                      icon: const Icon(Icons.workspace_premium_rounded, color: AppColors.googleBlue),
                      tooltip: 'Download certificate',
                      onPressed: () async {
                        final name = ref.read(currentUserProvider).valueOrNull?.fullName ?? 'Member';
                        final bytes = await buildCertificatePdf(
                          memberName: name,
                          eventTitle: item.eventTitle,
                          eventDate: item.eventDate,
                          certificateNumber: item.certificateNumber!,
                        );
                        await Printing.sharePdf(bytes: bytes, filename: 'certificate-${item.certificateNumber}.pdf');
                      },
                    )
                  : null,
            );
          }).toList(),
        );
      },
    );
  }
}
