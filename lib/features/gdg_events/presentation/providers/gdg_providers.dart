import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/supabase_providers.dart';
import '../../../../core/errors/exception_mapper.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/gdg_community_api.dart';
import '../../data/gdg_events_repository.dart';
import '../../domain/entities/gdg_event.dart';

/// Events tab source: false = GoCollab events, true = GDG Community feed.
final gdgModeProvider = StateProvider<bool>((ref) => false);

final gdgRepositoryProvider = Provider<GdgEventsRepository>((ref) => GdgEventsRepository(GdgCommunityApi()));

/// Chapters configured in `gdg_chapters` (officer-managed).
final gdgChaptersProvider = FutureProvider.autoDispose<List<GdgChapter>>((ref) async {
  final rows = await ref.watch(supabaseClientProvider).from('gdg_chapters').select().order('name');
  return (rows as List)
      .map((r) => GdgChapter(
            id: (r['chapter_id'] as num).toInt(),
            name: r['name'] as String,
            country: (r['country'] as String?) ?? 'PH',
            isOwn: r['is_own'] as bool? ?? false,
            ownerChapterId: r['owner_chapter_id'] as String?,
          ))
      .toList();
});

/// Upcoming events from every configured chapter: the member-facing feed.
final gdgUpcomingEventsProvider = FutureProvider.autoDispose<List<GdgEvent>>((ref) async {
  final chapters = await ref.watch(gdgChaptersProvider.future);
  return ref.watch(gdgRepositoryProvider).upcoming(chapters);
});

/// Upcoming events from our own chapter(s), for officers to import.
final gdgOwnUpcomingEventsProvider = FutureProvider.autoDispose<List<GdgEvent>>((ref) async {
  final myChapterId = ref.watch(currentUserProvider).valueOrNull?.chapterId;
  final chapters = (await ref.watch(gdgChaptersProvider.future))
      .where((c) => c.isOwn && c.ownerChapterId == myChapterId)
      .toList();
  return ref.watch(gdgRepositoryProvider).upcoming(chapters);
});

final gdgEventDetailProvider = FutureProvider.autoDispose.family<GdgEvent, int>((ref, id) {
  return ref.watch(gdgRepositoryProvider).detail(id);
});

/// Pull-to-refresh: drop the cache so the next load hits the network.
Future<void> refreshGdgEvents(WidgetRef ref) async {
  await ref.read(gdgRepositoryProvider).clearCache();
  ref.invalidate(gdgUpcomingEventsProvider);
  ref.invalidate(gdgOwnUpcomingEventsProvider);
}

class GdgChapterActions extends StateNotifier<bool> {
  GdgChapterActions(this._ref) : super(false);
  final Ref _ref;

  void _refresh() {
    _ref.invalidate(gdgChaptersProvider);
    _ref.invalidate(gdgUpcomingEventsProvider);
    _ref.invalidate(gdgOwnUpcomingEventsProvider);
  }

  /// Adds a chapter by its gdg.community.dev id. When [name] is empty it is
  /// read from that chapter's events, which also proves the id is real.
  Future<String?> add({required int chapterId, String name = '', bool isOwn = false}) async {
    state = true;
    try {
      var resolved = name.trim();
      if (resolved.isEmpty) {
        final found = await _ref.read(gdgRepositoryProvider).resolveChapterName(chapterId);
        if (found == null) {
          return 'No events found for chapter $chapterId. Type its name to add it anyway.';
        }
        resolved = found;
      }
      final client = _ref.read(supabaseClientProvider);
      final me = _ref.read(currentUserProvider).valueOrNull;
      final existing =
          await client.from('gdg_chapters').select('owner_chapter_id').eq('chapter_id', chapterId).maybeSingle();
      if (existing == null) {
        await client.from('gdg_chapters').insert({
          'chapter_id': chapterId,
          'name': resolved,
          'is_own': isOwn,
          'added_by': me?.id,
        });
      } else if (existing['owner_chapter_id'] == me?.chapterId) {
        // Already ours: rename only, never silently flip "our chapter".
        await client.from('gdg_chapters').update({'name': resolved}).eq('chapter_id', chapterId);
      } else {
        return 'That GDG chapter is already managed by another GoCollab chapter.';
      }
      _refresh();
      return null;
    } on GdgApiException catch (e) {
      return e.message;
    } catch (e) {
      return mapExceptionToFailure(e).message;
    } finally {
      state = false;
    }
  }

  Future<String?> remove(int chapterId) async {
    state = true;
    try {
      await _ref.read(supabaseClientProvider).from('gdg_chapters').delete().eq('chapter_id', chapterId);
      _refresh();
      return null;
    } catch (e) {
      return mapExceptionToFailure(e).message;
    } finally {
      state = false;
    }
  }

  Future<String?> setOwn(int chapterId, bool isOwn) async {
    try {
      await _ref.read(supabaseClientProvider).from('gdg_chapters').update({'is_own': isOwn}).eq('chapter_id', chapterId);
      _refresh();
      return null;
    } catch (e) {
      return mapExceptionToFailure(e).message;
    }
  }
}

final gdgChapterActionsProvider =
    StateNotifierProvider<GdgChapterActions, bool>((ref) => GdgChapterActions(ref));
