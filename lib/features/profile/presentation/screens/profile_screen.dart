import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/profile_providers.dart';
import '../widgets/profile_header.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
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
                onPressed: () async {
                  final useCase = ref.read(signOutUseCaseProvider);
                  await useCase();
                },
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          );
        },
      ),
    );
  }
}

class _GithubSection extends ConsumerWidget {
  const _GithubSection({required this.githubUsername, required this.userId});
  final String? githubUsername;
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (githubUsername == null || githubUsername!.isEmpty) {
      return Text(
        'Add your GitHub username in Edit Profile to showcase your repos and followers here.',
        style: Theme.of(context).textTheme.bodySmall,
      );
    }

    final githubAsync = ref.watch(cachedGithubProfileProvider);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceLightGray,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: githubAsync.when(
        loading: () => const SizedBox(height: 40, child: Center(child: CircularProgressIndicator())),
        error: (_, __) => const Text('Could not load GitHub stats.'),
        data: (stats) {
          if (stats == null) {
            return Row(
              children: [
                Expanded(child: Text('@$githubUsername', style: Theme.of(context).textTheme.bodyMedium)),
                TextButton(
                  onPressed: () => ref
                      .read(profileEditControllerProvider.notifier)
                      .syncGithub(userId: userId, username: githubUsername!),
                  child: const Text('Sync'),
                ),
              ],
            );
          }
          return Row(
            children: [
              const Icon(Icons.code_rounded, color: AppColors.textPrimary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('@${stats.username}', style: Theme.of(context).textTheme.titleSmall),
                    Text(
                      '${stats.publicRepos} repos • ${stats.followers} followers',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 18),
                onPressed: () => ref
                    .read(profileEditControllerProvider.notifier)
                    .syncGithub(userId: userId, username: githubUsername!),
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
              leading: Icon(
                item.attended ? Icons.check_circle_rounded : Icons.event_available_rounded,
                color: item.attended ? AppColors.googleGreen : AppColors.googleYellow,
              ),
              title: Text(item.eventTitle),
              subtitle: Text(DateFormatter.date(item.eventDate)),
              trailing: item.hasCertificate
                  ? const Icon(Icons.workspace_premium_rounded, color: AppColors.googleBlue)
                  : null,
            );
          }).toList(),
        );
      },
    );
  }
}
