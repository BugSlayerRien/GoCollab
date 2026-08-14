import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/supabase_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../data/datasources/event_remote_datasource.dart';
import '../../data/repositories/event_repository_impl.dart';
import '../../domain/entities/event.dart';
import '../../domain/repositories/event_repository.dart';

final eventRemoteDataSourceProvider = Provider<EventRemoteDataSource>((ref) {
  return EventRemoteDataSource(ref.watch(supabaseClientProvider));
});

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return EventRepositoryImpl(ref.watch(eventRemoteDataSourceProvider));
});

/// All events, sorted by start time, annotated with the current user's own
/// registration status. `autoDispose` + `keepAlive` pattern isn't needed
/// here since the list is cheap to refetch; `ref.invalidate` after mutating
/// actions (register/cancel) keeps this simple and always fresh.
final eventsListProvider = FutureProvider.autoDispose<List<Event>>((ref) async {
  final currentUser = await ref.watch(currentUserProvider.future);
  final repository = ref.watch(eventRepositoryProvider);
  final result = await repository.getEvents(currentUserId: currentUser?.id);
  return result.when(success: (data) => data, failure: (f) => throw f);
});

final eventDetailProvider = FutureProvider.autoDispose.family<Event, String>((ref, eventId) async {
  final currentUser = await ref.watch(currentUserProvider.future);
  final repository = ref.watch(eventRepositoryProvider);
  final result = await repository.getEventById(eventId, currentUserId: currentUser?.id);
  return result.when(success: (data) => data, failure: (f) => throw f);
});

class EventActionsController extends StateNotifier<bool> {
  EventActionsController(this._ref) : super(false);
  final Ref _ref;

  Future<String?> register(String eventId) async {
    final user = _ref.read(currentUserProvider).valueOrNull;
    if (user == null) return 'You must be signed in.';
    state = true;
    final repository = _ref.read(eventRepositoryProvider);
    final result = await repository.registerForEvent(eventId: eventId, userId: user.id);
    state = false;
    if (result.isSuccess) {
      _ref.invalidate(eventDetailProvider(eventId));
      _ref.invalidate(eventsListProvider);
      _ref.invalidate(eventHistoryProvider);
    }
    return result.when(success: (_) => null, failure: (f) => f.message);
  }

  Future<String?> cancel(String eventId) async {
    final user = _ref.read(currentUserProvider).valueOrNull;
    if (user == null) return 'You must be signed in.';
    state = true;
    final repository = _ref.read(eventRepositoryProvider);
    final result = await repository.cancelRegistration(eventId: eventId, userId: user.id);
    state = false;
    if (result.isSuccess) {
      _ref.invalidate(eventDetailProvider(eventId));
      _ref.invalidate(eventsListProvider);
      _ref.invalidate(eventHistoryProvider);
    }
    return result.when(success: (_) => null, failure: (f) => f.message);
  }

  Future<String?> createEvent({
    required String title,
    required String description,
    required EventCategory category,
    required DateTime startAt,
    required DateTime endAt,
    String? venueName,
    required bool isOnline,
    String? onlineUrl,
  }) async {
    state = true;
    final user = _ref.read(currentUserProvider).valueOrNull;
    if (user == null) {
      state = false;
      return 'You must be signed in.';
    }
    final result = await _ref.read(eventRepositoryProvider).createEvent(
          title: title,
          description: description,
          category: category,
          startAt: startAt,
          endAt: endAt,
          venueName: venueName,
          isOnline: isOnline,
          onlineUrl: onlineUrl,
          createdBy: user.id,
        );
    state = false;
    if (result.isSuccess) _ref.invalidate(eventsListProvider);
    return result.when(success: (_) => null, failure: (f) => f.message);
  }

  Future<String?> updateEvent({
    required String id,
    required String title,
    required String description,
    required EventCategory category,
    required DateTime startAt,
    required DateTime endAt,
    String? venueName,
    required bool isOnline,
    String? onlineUrl,
    required EventStatus status,
  }) async {
    state = true;
    final result = await _ref.read(eventRepositoryProvider).updateEvent(
          id: id,
          title: title,
          description: description,
          category: category,
          startAt: startAt,
          endAt: endAt,
          venueName: venueName,
          isOnline: isOnline,
          onlineUrl: onlineUrl,
          status: status,
        );
    state = false;
    if (result.isSuccess) {
      _ref.invalidate(eventsListProvider);
      _ref.invalidate(eventDetailProvider(id));
    }
    return result.when(success: (_) => null, failure: (f) => f.message);
  }

  Future<String?> deleteEvent(String id) async {
    state = true;
    final result = await _ref.read(eventRepositoryProvider).deleteEvent(id);
    state = false;
    if (result.isSuccess) {
      _ref.invalidate(eventsListProvider);
      _ref.invalidate(eventDetailProvider(id));
    }
    return result.when(success: (_) => null, failure: (f) => f.message);
  }
}

final eventActionsControllerProvider =
    StateNotifierProvider<EventActionsController, bool>((ref) => EventActionsController(ref));
