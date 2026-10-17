import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/animations/prismatic_shimmer.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/gdg_providers.dart';
import 'gdg_event_card.dart';

/// The "GDG Community" side of the Events tab: upcoming events from the
/// configured chapters, shown natively instead of sending members to the
/// gdg.community.dev website.
class GdgEventsView extends ConsumerWidget {
  const GdgEventsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(gdgUpcomingEventsProvider);
    final isOfficer = ref.watch(currentUserProvider).valueOrNull?.role == UserRole.officer;

    return RefreshIndicator(
      onRefresh: () => refreshGdgEvents(ref),
      child: eventsAsync.when(
        loading: () => ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: 4,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (_, __) => const PrismaticSkeletonCard(height: 110),
        ),
        error: (_, __) => ErrorStateView(
          message: 'Could not load GDG events. Check your connection and pull down to retry.',
          onRetry: () => refreshGdgEvents(ref),
        ),
        data: (events) => ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Upcoming events from GDG chapters',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (isOfficer)
                  TextButton.icon(
                    onPressed: () => context.push('/gdg-chapters'),
                    icon: const Icon(Icons.tune_rounded, size: 18),
                    label: const Text('Chapters'),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (events.isEmpty)
              const EmptyState(
                icon: Icons.public_off_rounded,
                title: 'No upcoming GDG events',
                message: 'Nothing is scheduled by the chapters we follow right now. Check back soon.',
              )
            else
              for (final event in events) ...[
                GdgEventCard(event: event, onTap: () => context.push('/gdg-events/${event.id}')),
                const SizedBox(height: AppSpacing.md),
              ],
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.xl),
              child: Text(
                'Event information from gdg.community.dev. Registration for these events happens on the GDG site.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.appTextSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
