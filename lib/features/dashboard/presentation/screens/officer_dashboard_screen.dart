import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../analytics/presentation/providers/analytics_providers.dart';
import '../../../analytics/presentation/widgets/stat_summary_card.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../events/presentation/providers/event_providers.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
import '../../../partnerships/presentation/providers/partnership_providers.dart';
import '../../../shell/presentation/providers/shell_providers.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/quick_actions_grid.dart';

/// Officer Dashboard: a management-focused Home tab surfacing the same
/// community pulse a member sees, plus fast access to the officer-only
/// Analytics and Partnerships modules and event check-in tooling.
class OfficerDashboardScreen extends ConsumerWidget {
  const OfficerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final analyticsAsync = ref.watch(analyticsSnapshotProvider);
    final eventsAsync = ref.watch(eventsListProvider);
    final partnersAsync = ref.watch(partnersListProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    final user = userAsync.valueOrNull;
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(analyticsSnapshotProvider);
          ref.invalidate(eventsListProvider);
          ref.invalidate(partnersListProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            DashboardHeader(
              user: user,
              unreadNotificationCount: unreadCount,
              onNotificationsTap: () => context.push('/notifications'),
            ),
            const SizedBox(height: AppSpacing.lg),
            QuickActionsGrid(
              actions: [
                QuickAction(
                  icon: Icons.bar_chart_rounded,
                  label: 'Analytics',
                  color: AppColors.googleBlue,
                  onTap: () => ref.read(selectedTabIndexProvider.notifier).state = 3,
                ),
                QuickAction(
                  icon: Icons.handshake_outlined,
                  label: 'Partners',
                  color: AppColors.googleRed,
                  onTap: () => ref.read(selectedTabIndexProvider.notifier).state = 4,
                ),
                QuickAction(
                  icon: Icons.campaign_outlined,
                  label: 'Announce',
                  color: AppColors.googleGreen,
                  onTap: () => ref.read(selectedTabIndexProvider.notifier).state = 2,
                ),
                QuickAction(
                  icon: Icons.qr_code_scanner_rounded,
                  label: 'Check-in',
                  color: AppColors.googleYellow,
                  onTap: () => ref.read(selectedTabIndexProvider.notifier).state = 1,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            SectionHeader(title: 'Community pulse', onSeeAll: () => ref.read(selectedTabIndexProvider.notifier).state = 3),
            const SizedBox(height: AppSpacing.sm),
            analyticsAsync.when(
              loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
              error: (_, __) => const SizedBox.shrink(),
              data: (snapshot) => GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppSpacing.sm,
                crossAxisSpacing: AppSpacing.sm,
                childAspectRatio: 1.6,
                children: [
                  StatSummaryCard(
                    label: 'Active members',
                    value: '${snapshot.activeMembers}',
                    icon: Icons.groups_rounded,
                    color: AppColors.googleBlue,
                  ),
                  StatSummaryCard(
                    label: 'Avg. attendance',
                    value: '${(snapshot.averageAttendanceRate * 100).toStringAsFixed(0)}%',
                    icon: Icons.check_circle_outline_rounded,
                    color: AppColors.googleGreen,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SectionHeader(title: 'Upcoming events', onSeeAll: () => ref.read(selectedTabIndexProvider.notifier).state = 1),
            const SizedBox(height: AppSpacing.sm),
            eventsAsync.when(
              loading: () => const SizedBox(height: 40, child: Center(child: CircularProgressIndicator())),
              error: (_, __) => const SizedBox.shrink(),
              data: (events) {
                final upcoming = events.where((e) => e.startAt.isAfter(DateTime.now())).take(3).toList();
                return Column(
                  children: upcoming
                      .map((e) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.event_rounded, color: AppColors.googleYellow),
                            title: Text(e.title),
                            subtitle: Text('${e.registeredCount} registered'),
                          ))
                      .toList(),
                );
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            SectionHeader(title: 'Partners', onSeeAll: () => ref.read(selectedTabIndexProvider.notifier).state = 4),
            const SizedBox(height: AppSpacing.sm),
            partnersAsync.when(
              loading: () => const SizedBox(height: 40, child: Center(child: CircularProgressIndicator())),
              error: (_, __) => const SizedBox.shrink(),
              data: (partners) => Column(
                children: partners
                    .take(3)
                    .map((p) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.business_rounded, color: AppColors.googleRed),
                          title: Text(p.name),
                          subtitle: Text(p.collaborationStatus.label),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}
