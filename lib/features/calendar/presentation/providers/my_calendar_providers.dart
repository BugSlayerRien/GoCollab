import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../events/presentation/providers/event_providers.dart';
import '../../data/datasources/my_calendar_remote_datasource.dart';
import '../../data/repositories/my_calendar_repository_impl.dart';
import '../../domain/entities/google_calendar_event.dart';
import '../../domain/repositories/my_calendar_repository.dart';

final myCalendarRemoteDataSourceProvider = Provider<MyCalendarRemoteDataSource>((ref) {
  return MyCalendarRemoteDataSource(ref.watch(gcalDataSourceProvider));
});

final myCalendarRepositoryProvider = Provider<MyCalendarRepository>((ref) {
  return MyCalendarRepositoryImpl(ref.watch(myCalendarRemoteDataSourceProvider));
});

/// Month currently shown in the calendar widget (first day of month).
final myCalendarFocusedMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

/// Day selected by the user in the calendar grid.
final myCalendarSelectedDayProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

DateTime _monthRangeStart(DateTime month) => DateTime(month.year, month.month, 1);

DateTime _monthRangeEnd(DateTime month) =>
    DateTime(month.year, month.month + 1, 0, 23, 59, 59, 999);

/// Live Google Calendar events for the focused month (GET primary/events).
final myCalendarEventsProvider = FutureProvider.autoDispose<List<GoogleCalendarEvent>>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return [];

  final hasAccess = await ref.watch(myCalendarRepositoryProvider).hasCalendarAccess();
  if (!hasAccess) {
    throw const CalendarAccessRequired();
  }

  final month = ref.watch(myCalendarFocusedMonthProvider);
  final repo = ref.watch(myCalendarRepositoryProvider);
  final result = await repo.fetchEventsInRange(
    userId: user.id,
    rangeStart: _monthRangeStart(month),
    rangeEnd: _monthRangeEnd(month),
  );

  return result.when(
    success: (events) => events,
    failure: (f) => throw f,
  );
});

/// Events on the currently selected day, sorted by start time.
final myCalendarSelectedDayEventsProvider = Provider<List<GoogleCalendarEvent>>((ref) {
  final events = ref.watch(myCalendarEventsProvider).valueOrNull ?? [];
  final selected = ref.watch(myCalendarSelectedDayProvider);
  return events.where((e) => e.occursOn(selected)).toList()
    ..sort((a, b) => a.startAt.compareTo(b.startAt));
});

/// Sentinel thrown by [myCalendarEventsProvider] when OAuth token is missing.
class CalendarAccessRequired implements Exception {
  const CalendarAccessRequired();
}
