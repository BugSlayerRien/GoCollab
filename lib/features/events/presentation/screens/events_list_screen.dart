import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/animations/prismatic_shimmer.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../gdg_events/presentation/providers/gdg_providers.dart';
import '../../../gdg_events/presentation/widgets/gdg_events_view.dart';
import '../../domain/entities/event.dart';
import '../providers/event_providers.dart';
import '../widgets/create_event_sheet.dart';
import '../widgets/event_card.dart';

class EventsListScreen extends ConsumerStatefulWidget {
  const EventsListScreen({super.key});

  @override
  ConsumerState<EventsListScreen> createState() => _EventsListScreenState();
}

class _EventsListScreenState extends ConsumerState<EventsListScreen> {
  EventCategory? _filter;
  bool _showHistory = false;

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventsListProvider);
    ref.watch(eventActionsControllerProvider);
    final isOfficer =
        ref.watch(currentUserProvider).valueOrNull?.role == UserRole.officer;
    final gdgMode = ref.watch(gdgModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_showHistory ? 'Event history' : 'Events'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: 'My Calendar',
            onPressed: () => context.push('/my-calendar'),
          ),
          IconButton(
            icon: Icon(
              _showHistory
                  ? Icons.event_available_rounded
                  : Icons.history_rounded,
            ),
            tooltip: _showHistory ? 'Available events' : 'Event history',
            onPressed: () => setState(() => _showHistory = !_showHistory),
          ),
        ],
      ),
      floatingActionButton: isOfficer && !_showHistory && !gdgMode
          ? FloatingActionButton.extended(
              onPressed: () => showEventEditorSheet(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Event'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: false,
                    label: Text('GoCollab'),
                    icon: Icon(Icons.event_rounded),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text('GDG Community'),
                    icon: Icon(Icons.public_rounded),
                  ),
                ],
                selected: {gdgMode},
                onSelectionChanged: (v) =>
                    ref.read(gdgModeProvider.notifier).state = v.first,
              ),
            ),
          ),
          Expanded(
            child: gdgMode
                ? const GdgEventsView()
                : RefreshIndicator(
                    onRefresh: () async => ref.invalidate(eventsListProvider),
                    child: eventsAsync.when(
                      loading: () => ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: 4,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.md),
                        itemBuilder: (_, __) =>
                            const PrismaticSkeletonCard(height: 120),
                      ),
                      error: (error, _) => ErrorStateView(
                        message: 'Could not load events. Pull down to retry.',
                        onRetry: () => ref.invalidate(eventsListProvider),
                      ),
                      data: (events) {
                        final scoped = events.where((e) {
                          if (!isOfficer && e.status == EventStatus.draft)
                            return false;
                          if (isOfficer) {
                            return _showHistory ? e.isPast : !e.isPast;
                          }
                          return _showHistory ? !e.isAvailable : e.isAvailable;
                        }).toList();
                        final filtered = _filter == null
                            ? scoped
                            : scoped
                                  .where((e) => e.category == _filter)
                                  .toList();
                        return Column(
                          children: [
                            _CategoryFilterBar(
                              selected: _filter,
                              onSelected: (cat) =>
                                  setState(() => _filter = cat),
                            ),
                            Expanded(
                              child: filtered.isEmpty
                                  ? EmptyState(
                                      icon: _showHistory
                                          ? Icons.history_rounded
                                          : Icons.event_busy_rounded,
                                      title: _showHistory
                                          ? 'No past or closed events'
                                          : 'No available events',
                                      message: _showHistory
                                          ? 'Past events and closed registrations appear here, including ones you joined.'
                                          : 'Check back soon — new GDGoC events are added regularly.',
                                    )
                                  : ListView.separated(
                                      padding: const EdgeInsets.all(
                                        AppSpacing.md,
                                      ),
                                      itemCount: filtered.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(height: AppSpacing.md),
                                      itemBuilder: (context, index) {
                                        final event = filtered[index];
                                        return EventCard(
                                          event: event,
                                          onTap: () => context.push(
                                            '/events/${event.id}',
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
          ),
        ],
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
          ...EventCategory.values.map(
            (c) => _chip(context, label: c.label, value: c),
          ),
        ],
      ),
    );
  }

  Widget _chip(
    BuildContext context, {
    required String label,
    required EventCategory? value,
  }) {
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
