import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/di/supabase_providers.dart';
import '../../../../core/errors/exception_mapper.dart';
import '../../../../core/services/google_calendar_service.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../data/datasources/event_remote_datasource.dart';
import '../../data/ticket_cache.dart';
import '../../data/datasources/gcal_datasource.dart';
import '../../data/repositories/event_repository_impl.dart';
import '../../data/repositories/gcal_repository.dart';
import '../../domain/entities/event.dart';
import '../../domain/entities/event_attendee.dart';
import '../../domain/repositories/event_repository.dart';

final eventRemoteDataSourceProvider = Provider<EventRemoteDataSource>((ref) {
  return EventRemoteDataSource(ref.watch(supabaseClientProvider));
});

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return EventRepositoryImpl(ref.watch(eventRemoteDataSourceProvider));
});

final gcalDataSourceProvider = Provider<GcalDataSource>((ref) {
  return GcalDataSource(ref.watch(supabaseClientProvider));
});

final gcalRepositoryProvider = Provider<GcalRepository>((ref) {
  return GcalRepository(ref.watch(gcalDataSourceProvider));
});

/// Whether the current event is synced to Google Calendar for the current user.
final gcalSyncStatusProvider = FutureProvider.autoDispose.family<bool, String>((ref, eventId) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return false;
  final repo = ref.watch(gcalRepositoryProvider);
  final result = await repo.isSynced(userId: user.id, eventId: eventId);
  return result.dataOrNull ?? false;
});

/// Whether the signed-in user has a Google Calendar token available.
final googleCalendarAccessProvider = FutureProvider.autoDispose<bool>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return false;
  return GoogleCalendarService.hasAccess();
});

class GcalActionsController extends StateNotifier<bool> {
  GcalActionsController(this._ref) : super(false);
  final Ref _ref;

  Future<String?> addToCalendar(Event event) async {
    final user = _ref.read(currentUserProvider).valueOrNull;
    if (user == null) return 'You must be signed in.';
    state = true;
    final repo = _ref.read(gcalRepositoryProvider);
    final result = await repo.addToCalendar(userId: user.id, event: event);
    state = false;
    if (result.isSuccess) _ref.invalidate(gcalSyncStatusProvider(event.id));
    return result.when(success: (_) => null, failure: (f) => f.message);
  }

  Future<String?> updateCalendarEvent(Event event) async {
    final user = _ref.read(currentUserProvider).valueOrNull;
    if (user == null) return 'You must be signed in.';
    state = true;
    final repo = _ref.read(gcalRepositoryProvider);
    final result = await repo.updateCalendarEvent(userId: user.id, event: event);
    state = false;
    if (result.isSuccess) _ref.invalidate(gcalSyncStatusProvider(event.id));
    return result.when(success: (_) => null, failure: (f) => f.message);
  }

  Future<String?> removeFromCalendar(String eventId) async {
    final user = _ref.read(currentUserProvider).valueOrNull;
    if (user == null) return 'You must be signed in.';
    state = true;
    final repo = _ref.read(gcalRepositoryProvider);
    final result = await repo.removeFromCalendar(userId: user.id, eventId: eventId);
    state = false;
    if (result.isSuccess) _ref.invalidate(gcalSyncStatusProvider(eventId));
    return result.when(success: (_) => null, failure: (f) => f.message);
  }

  /// Opens Google OAuth (same tab) to grant calendar scope. Redirects away from
  /// the app briefly; user returns to the current page with tokens saved.
  Future<String?> connectGoogleCalendar() async {
    state = true;
    final useCase = _ref.read(requestGoogleCalendarAccessUseCaseProvider);
    final result = await useCase();
    state = false;
    return result.when(success: (_) => null, failure: (f) => f.message);
  }
}

final gcalActionsControllerProvider =
    StateNotifierProvider<GcalActionsController, bool>((ref) => GcalActionsController(ref));

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
  final event = result.when(success: (data) => data, failure: (f) => throw f);
  // Keep the ticket for offline use; drop it once it can no longer be used.
  if (event.isRegistered && event.myQrCode != null && !event.isPast) {
    await TicketCache.save(eventId: eventId, title: event.title, qrCode: event.myQrCode!);
  } else {
    await TicketCache.clear(eventId);
  }
  return event;
});

/// Officer attendee list for one event.
final eventAttendeesProvider = FutureProvider.autoDispose.family<List<EventAttendee>, String>((ref, eventId) async {
  final result = await ref.watch(eventRepositoryProvider).getAttendees(eventId);
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
      _ref.invalidate(communityPointsProvider);
      _ref.invalidate(notificationsProvider);
    }
    return result.when(success: (_) => null, failure: (f) => f.message);
  }

  /// Officer manual check-in. Returns an error message, or null on success.
  Future<String?> checkInMember(String eventId, String userId) async {
    state = true;
    final result = await _ref.read(eventRepositoryProvider).checkInMember(eventId: eventId, userId: userId);
    state = false;
    if (result.isSuccess) {
      _ref.invalidate(eventAttendeesProvider(eventId));
      _ref.invalidate(eventDetailProvider(eventId));
    }
    return result.when(success: (_) => null, failure: (f) => f.message);
  }

  /// Officer: reverse a wrong check-in (also takes back the attendance points).
  Future<String?> undoCheckIn(String eventId, String userId) async {
    state = true;
    try {
      await _ref
          .read(supabaseClientProvider)
          .rpc('undo_check_in', params: {'p_event_id': eventId, 'p_user_id': userId});
      _ref.invalidate(eventAttendeesProvider(eventId));
      _ref.invalidate(eventDetailProvider(eventId));
      return null;
    } catch (e) {
      return mapExceptionToFailure(e).message;
    } finally {
      state = false;
    }
  }

  /// Officer, after the event: everyone still just registered becomes a
  /// no-show. Returns how many were marked, or an error message.
  Future<(int, String?)> markNoShows(String eventId) async {
    state = true;
    try {
      final count = await _ref.read(supabaseClientProvider).rpc('mark_no_shows', params: {'p_event_id': eventId});
      _ref.invalidate(eventAttendeesProvider(eventId));
      return ((count as num?)?.toInt() ?? 0, null);
    } catch (e) {
      return (0, mapExceptionToFailure(e).message);
    } finally {
      state = false;
    }
  }

  /// Officer, after the event: certificates for everyone who was checked in.
  Future<(int, String?)> issueCertificates(String eventId) async {
    state = true;
    try {
      final count = await _ref.read(supabaseClientProvider).rpc('issue_certificates', params: {'p_event_id': eventId});
      return ((count as num?)?.toInt() ?? 0, null);
    } catch (e) {
      return (0, mapExceptionToFailure(e).message);
    } finally {
      state = false;
    }
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
    String? venueAddress,
    double? latitude,
    double? longitude,
    required bool isOnline,
    String? onlineUrl,
    int? capacity,
    DateTime? registrationDeadline,
    XFile? bannerFile,
    String? partnerId,
    String? gdgEventUrl,
    String? feedbackFormUrl,
  }) async {
    state = true;
    final user = _ref.read(currentUserProvider).valueOrNull;
    if (user == null) {
      state = false;
      return 'You must be signed in.';
    }

    String? bannerUrl;
    String? bannerWarning;
    if (bannerFile != null) {
      try {
        bannerUrl = await _ref.read(storageServiceProvider).uploadEventBanner(file: bannerFile);
      } catch (_) {
        bannerWarning =
            'Event created, but the banner could not be uploaded. Apply the event-banners storage migration in Supabase.';
      }
    }

    final result = await _ref.read(eventRepositoryProvider).createEvent(
          title: title,
          description: description,
          category: category,
          startAt: startAt,
          endAt: endAt,
          venueName: venueName,
          venueAddress: venueAddress,
          latitude: latitude,
          longitude: longitude,
          isOnline: isOnline,
          onlineUrl: onlineUrl,
          capacity: capacity,
          registrationDeadline: registrationDeadline,
          bannerUrl: bannerUrl,
          createdBy: user.id,
          partnerId: partnerId,
          gdgEventUrl: gdgEventUrl,
          feedbackFormUrl: feedbackFormUrl,
        );
    state = false;
    if (result.isSuccess) {
      _ref.invalidate(eventsListProvider);
      if (bannerWarning != null) return '__saved__$bannerWarning';
      return null;
    }
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
    String? venueAddress,
    double? latitude,
    double? longitude,
    required bool isOnline,
    String? onlineUrl,
    int? capacity,
    DateTime? registrationDeadline,
    required EventStatus status,
    String? existingBannerUrl,
    XFile? bannerFile,
    bool removeBanner = false,
    String? partnerId,
    String? gdgEventUrl,
    String? feedbackFormUrl,
  }) async {
    state = true;

    String? bannerUrl = removeBanner ? null : existingBannerUrl;
    String? bannerWarning;
    if (bannerFile != null) {
      try {
        bannerUrl = await _ref.read(storageServiceProvider).uploadEventBanner(file: bannerFile, eventId: id);
      } catch (_) {
        bannerUrl = removeBanner ? null : existingBannerUrl;
        bannerWarning =
            'Event saved, but the banner could not be uploaded. Apply the event-banners storage migration in Supabase.';
      }
    }

    final result = await _ref.read(eventRepositoryProvider).updateEvent(
          id: id,
          title: title,
          description: description,
          category: category,
          startAt: startAt,
          endAt: endAt,
          venueName: venueName,
          venueAddress: venueAddress,
          latitude: latitude,
          longitude: longitude,
          isOnline: isOnline,
          onlineUrl: onlineUrl,
          capacity: capacity,
          registrationDeadline: registrationDeadline,
          bannerUrl: bannerUrl,
          status: status,
          partnerId: partnerId,
          gdgEventUrl: gdgEventUrl,
          feedbackFormUrl: feedbackFormUrl,
        );
    state = false;
    if (result.isSuccess) {
      _ref.invalidate(eventsListProvider);
      _ref.invalidate(eventDetailProvider(id));
      if (bannerWarning != null) return '__saved__$bannerWarning';
      return null;
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
