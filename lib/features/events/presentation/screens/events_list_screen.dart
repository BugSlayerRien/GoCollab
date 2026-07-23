import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/animations/prismatic_shimmer.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../domain/entities/event.dart';
import '../providers/event_providers.dart';
import '../widgets/event_card.dart';

class EventsListScreen extends ConsumerStatefulWidget {
  const EventsListScreen({super.key});

  @override
  ConsumerState<EventsListScreen> createState() => _EventsListScreenState();
}

class _EventsListScreenState extends ConsumerState<EventsListScreen> {
  EventCategory? _filter;

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventsListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Events')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(eventsListProvider),
        child: eventsAsync.when(
          loading: () => ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: 4,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (_, __) => const PrismaticSkeletonCard(height: 120),
          ),
          error: (error, _) => ErrorStateView(
            message: 'Could not load events. Pull down to retry.',
            onRetry: () => ref.invalidate(eventsListProvider),
          ),
          data: (events) {
            final filtered = _filter == null ? events : events.where((e) => e.category == _filter).toList();
            return Column(
              children: [
                _CategoryFilterBar(
                  selected: _filter,
                  onSelected: (cat) => setState(() => _filter = cat),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? const EmptyState(
                          icon: Icons.event_busy_rounded,
                          title: 'No events found',
                          message: 'Check back soon — new GDGoC events are added regularly.',
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                          itemBuilder: (context, index) {
                            final event = filtered[index];
                            return EventCard(
                              event: event,
                              onTap: () => context.push('/events/${event.id}'),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CategoryFilterBar extends StatelessWidget {
  const _CategoryFilterBar({required this.selected, required this.onSelected});

  final EventCategory? selected;
  final void Function(EventCategory?) onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        children: [
          _chip(context, label: 'All', value: null),
          ...EventCategory.values.map((c) => _chip(context, label: c.label, value: c)),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, {required String label, required EventCategory? value}) {
    final isSelected = selected == value;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.xs),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onSelected(value),
      ),
    );
  }
}
