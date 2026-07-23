import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/animations/prismatic_shimmer.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../announcements/presentation/providers/announcement_providers.dart';
import '../../../announcements/presentation/widgets/announcement_card.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../widgets/create_announcement_sheet.dart';

/// The "Community" bottom-nav tab: the org-wide announcements feed
/// (module #7 — Community Announcements). Officers get a FAB to publish
/// new announcements; members get a read-only feed with pinned items
/// surfaced first.
class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcementsAsync = ref.watch(announcementsListProvider);
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final isOfficer = currentUser?.role == UserRole.officer;

    return Scaffold(
      appBar: AppBar(title: const Text('Community')),
      floatingActionButton: isOfficer
          ? FloatingActionButton.extended(
              onPressed: () => showCreateAnnouncementSheet(context, ref, authorId: currentUser!.id),
              icon: const Icon(Icons.campaign_rounded),
              label: const Text('Announce'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(announcementsListProvider),
        child: announcementsAsync.when(
          loading: () => ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: 4,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (_, __) => const PrismaticSkeletonCard(height: 110),
          ),
          error: (error, _) => ErrorStateView(
            message: 'Could not load announcements. Pull down to retry.',
            onRetry: () => ref.invalidate(announcementsListProvider),
          ),
          data: (announcements) {
            if (announcements.isEmpty) {
              return const EmptyState(
                icon: Icons.campaign_outlined,
                title: 'No announcements yet',
                message: 'Community updates and event news will show up here.',
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: announcements.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) => AnnouncementCard(announcement: announcements[index]),
            );
          },
        ),
      ),
    );
  }
}
