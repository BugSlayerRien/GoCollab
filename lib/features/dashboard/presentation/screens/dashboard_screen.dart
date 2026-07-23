import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../announcements/presentation/providers/announcement_providers.dart';
import '../../../announcements/presentation/widgets/announcement_card.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../events/presentation/providers/event_providers.dart';
import '../../../events/presentation/widgets/event_card.dart';
import '../../../opportunities/presentation/providers/opportunity_providers.dart';
import '../../../opportunities/presentation/widgets/opportunity_card.dart';
import '../../../shell/presentation/providers/shell_providers.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/quick_actions_grid.dart';

/// Member Dashboard (module #2): announcements, upcoming events, saved
/// opportunities, community statistics, and quick actions.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final statsAsync = ref.watch(communityStatsProvider);
    final announcementsAsync = ref.watch(announcementsListProvider);
    final eventsAsync = ref.watch(eventsListProvider);
    final savedAsync = ref.watch(savedOpportunitiesProvider);

    final user = userAsync.valueOrNull;
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(communityStatsProvider);
          ref.invalidate(announcementsListProvider);
          ref.invalidate(eventsListProvider);
          ref.invalidate(savedOpportunitiesProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            DashboardHeader(user: user, onNotificationsTap: () {}),
            const SizedBox(height: AppSpacing.lg),
            statsAsync.when(
              loading: () => const SizedBox(height: 72, child: Center(child: CircularProgressIndicator())),
              error: (_, __) => const SizedBox.shrink(),
              data: (stats) {
                if (stats == null) return const SizedBox.shrink();
                return Row(
                  children: [
                    Expanded(
                      child: _StatChip(
                        icon: Icons.groups_rounded,
                        label: 'Members',
                        value: '${stats.totalMembers}',
                        color: AppColors.googleBlue,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _StatChip(
                        icon: Icons.event_rounded,
                        label: 'Events',
                        value: '${stats.upcomingEventsCount}',
                        color: AppColors.googleYellow,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _StatChip(
                        icon: Icons.work_outline_rounded,
                        label: 'Opportunities',
                        value: '${stats.openOpportunitiesCount}',
                        color: AppColors.googleGreen,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            QuickActionsGrid(
              actions: [
                QuickAction(
                  icon: Icons.event_available_rounded,
                  label: 'Events',
                  color: AppColors.googleYellow,
                  onTap: () => ref.read(selectedTabIndexProvider.notifier).state = 2,
                ),
                QuickAction(
                  icon: Icons.work_outline_rounded,
                  label: 'Career Hub',
                  color: AppColors.googleGreen,
                  onTap: () => ref.read(selectedTabIndexProvider.notifier).state = 1,
                ),
                QuickAction(
                  icon: Icons.campaign_outlined,
                  label: 'Community',
                  color: AppColors.googleBlue,
                  onTap: () => ref.read(selectedTabIndexProvider.notifier).state = 3,
                ),
                QuickAction(
                  icon: Icons.person_outline_rounded,
                  label: 'Profile',
                  color: AppColors.googleRed,
                  onTap: () => ref.read(selectedTabIndexProvider.notifier).state = 4,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            SectionHeader(title: 'Announcements', onSeeAll: () => ref.read(selectedTabIndexProvider.notifier).state = 3),
            const SizedBox(height: AppSpacing.sm),
            announcementsAsync.when(
              loading: () => const SizedBox(height: 40, child: Center(child: CircularProgressIndicator())),
              error: (_, __) => const SizedBox.shrink(),
              data: (announcements) {
                final top = announcements.take(2).toList();
                if (top.isEmpty) {
                  return const EmptyState(icon: Icons.campaign_outlined, title: 'No announcements yet', message: '');
                }
                return Column(
                  children: top
                      .map((a) => Padding(padding: const EdgeInsets.only(bottom: AppSpacing.sm), child: AnnouncementCard(announcement: a)))
                      .toList(),
                );
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            SectionHeader(title: 'Upcoming events', onSeeAll: () => ref.read(selectedTabIndexProvider.notifier).state = 2),
            const SizedBox(height: AppSpacing.sm),
            eventsAsync.when(
              loading: () => const SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
              error: (_, __) => const SizedBox.shrink(),
              data: (events) {
                final upcoming = events.where((e) => e.startAt.isAfter(DateTime.now())).take(5).toList();
                if (upcoming.isEmpty) {
                  return const EmptyState(icon: Icons.event_busy_rounded, title: 'No upcoming events', message: '');
                }
                return SizedBox(
                  height: 150,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: upcoming.length,
                    separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
                    itemBuilder: (context, index) => SizedBox(
                      width: 220,
                      child: EventCard(event: upcoming[index], onTap: () => context.push('/events/${upcoming[index].id}'), dense: true),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            SectionHeader(title: 'Saved opportunities', onSeeAll: () => ref.read(selectedTabIndexProvider.notifier).state = 1),
            const SizedBox(height: AppSpacing.sm),
            savedAsync.when(
              loading: () => const SizedBox(height: 40, child: Center(child: CircularProgressIndicator())),
              error: (_, __) => const SizedBox.shrink(),
              data: (saved) {
                if (saved.isEmpty) {
                  return const EmptyState(icon: Icons.bookmark_border_rounded, title: 'Nothing saved yet', message: '');
                }
                return Column(
                  children: saved
                      .take(2)
                      .map((o) => Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: OpportunityCard(opportunity: o, onTap: () => context.push('/opportunities/${o.id}')),
                          ))
                      .toList(),
                );
              },
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label, required this.value, required this.color});
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surfaceLightGray,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}
