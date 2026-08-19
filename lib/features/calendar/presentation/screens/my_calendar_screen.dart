import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../events/presentation/providers/event_providers.dart';
import '../../domain/entities/google_calendar_event.dart';
import '../providers/my_calendar_providers.dart';
import '../widgets/google_calendar_event_tile.dart';

class MyCalendarScreen extends ConsumerWidget {
  const MyCalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(myCalendarEventsProvider);
    final selectedDay = ref.watch(myCalendarSelectedDayProvider);
    final focusedMonth = ref.watch(myCalendarFocusedMonthProvider);
    final dayEvents = ref.watch(myCalendarSelectedDayEventsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(myCalendarEventsProvider),
          ),
        ],
      ),
      body: eventsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorBody(error: error, onRetry: () => ref.invalidate(myCalendarEventsProvider)),
        data: (events) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(myCalendarEventsProvider),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              _CalendarCard(
                events: events,
                selectedDay: selectedDay,
                focusedMonth: focusedMonth,
                onDaySelected: (day) {
                  ref.read(myCalendarSelectedDayProvider.notifier).state =
                      DateTime(day.year, day.month, day.day);
                },
                onPageChanged: (month) {
                  ref.read(myCalendarFocusedMonthProvider.notifier).state =
                      DateTime(month.year, month.month);
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Events on ${DateFormatter.weekdayDate(selectedDay)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              if (dayEvents.isEmpty)
                EmptyState(
                  icon: Icons.event_busy_rounded,
                  title: 'No events',
                  message: 'Nothing scheduled on this date in your Google Calendar.',
                )
              else
                ...dayEvents.map(
                  (event) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: GoogleCalendarEventTile(
                      event: event,
                      onTap: event.goCollabEventId != null
                          ? () => context.push('/events/${event.goCollabEventId}')
                          : null,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CalendarCard extends StatelessWidget {
  const _CalendarCard({
    required this.events,
    required this.selectedDay,
    required this.focusedMonth,
    required this.onDaySelected,
    required this.onPageChanged,
  });

  final List<GoogleCalendarEvent> events;
  final DateTime selectedDay;
  final DateTime focusedMonth;
  final ValueChanged<DateTime> onDaySelected;
  final ValueChanged<DateTime> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final eventDays = <DateTime, bool>{};
    for (final e in events) {
      var day = DateTime(e.startAt.year, e.startAt.month, e.startAt.day);
      final last = DateTime(e.endAt.year, e.endAt.month, e.endAt.day);
      while (!day.isAfter(last)) {
        eventDays[day] = true;
        day = day.add(const Duration(days: 1));
      }
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: context.appSurfaceMuted,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: context.appBorder),
      ),
      child: TableCalendar<void>(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2035, 12, 31),
        focusedDay: focusedMonth,
        selectedDayPredicate: (day) => isSameDay(day, selectedDay),
        calendarFormat: CalendarFormat.month,
        startingDayOfWeek: StartingDayOfWeek.monday,
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: Theme.of(context).textTheme.titleSmall!,
        ),
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: AppColors.googleBlue.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          selectedDecoration: const BoxDecoration(
            color: AppColors.googleBlue,
            shape: BoxShape.circle,
          ),
          markerDecoration: const BoxDecoration(
            color: AppColors.googleGreen,
            shape: BoxShape.circle,
          ),
          markersMaxCount: 1,
        ),
        eventLoader: (day) {
          final key = DateTime(day.year, day.month, day.day);
          return eventDays.containsKey(key) ? [Object()] : [];
        },
        onDaySelected: (selected, focused) => onDaySelected(selected),
        onPageChanged: onPageChanged,
      ),
    );
  }
}

class _ErrorBody extends ConsumerWidget {
  const _ErrorBody({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (error is CalendarAccessRequired) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.calendar_month_outlined, size: 48, color: AppColors.googleBlue),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Connect Google Calendar',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Sign in with Google and grant calendar access to view your real events here.',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: 'Connect Google Calendar',
                icon: Icons.link_rounded,
                onPressed: () async {
                  final controller = ref.read(gcalActionsControllerProvider.notifier);
                  final err = await controller.connectGoogleCalendar();
                  if (!context.mounted) return;
                  if (err != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(err), backgroundColor: AppColors.googleRed),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      );
    }

    final message = switch (error) {
      AuthFailure(:final message) => message,
      NetworkFailure(:final message) => message,
      ServerFailure(:final message) => message,
      Failure(:final message) => message,
      _ => 'Could not load your Google Calendar. Please try again.',
    };

    return ErrorStateView(message: message, onRetry: onRetry);
  }
}
