import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/entities/gdg_event.dart';
import 'gdg_community_api.dart';

/// Per-chapter fetching with a 1-hour cache. If the GDG site is down, stale
/// cached data is served instead of an error, so the feed keeps working.
class GdgEventsRepository {
  GdgEventsRepository(this._api);

  final GdgCommunityApi _api;

  static const _ttl = Duration(hours: 1);
  static const _prefix = 'gdg_events_';

  Future<List<GdgEvent>> chapterEvents(GdgChapter chapter, {bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_prefix${chapter.id}';
    final cached = prefs.getString(key);
    final cachedAt = prefs.getInt('${key}_at');
    final isFresh = cached != null &&
        cachedAt != null &&
        DateTime.now().millisecondsSinceEpoch - cachedAt < _ttl.inMilliseconds;

    if (isFresh && !forceRefresh) {
      final fromCache = _parseCached(cached, chapter);
      if (fromCache != null) return fromCache;
    }

    try {
      final json = await _api.fetchChapterJson(chapter.id);
      final events = GdgCommunityApi.parseList(json, chapter: chapter);

      // Data came back but none of it was readable: the site changed its
      // format. Surface that instead of pretending the chapter has no
      // events, and never cache an unreadable payload.
      if (events.isEmpty && GdgCommunityApi.rawResultCount(json) > 0) {
        throw const GdgApiException('The GDG site changed its data format.');
      }

      await prefs.setString(key, jsonEncode(json));
      await prefs.setInt('${key}_at', DateTime.now().millisecondsSinceEpoch);
      return events;
    } catch (_) {
      final stale = cached == null ? null : _parseCached(cached, chapter);
      if (stale != null) return stale;
      rethrow;
    }
  }

  /// Null when the cached payload is unusable, so callers refetch.
  List<GdgEvent>? _parseCached(String raw, GdgChapter chapter) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final events = GdgCommunityApi.parseList(decoded, chapter: chapter);
      if (events.isEmpty && GdgCommunityApi.rawResultCount(decoded) > 0) return null;
      return events;
    } catch (_) {
      return null;
    }
  }

  /// Upcoming events across [chapters], soonest first. One failing chapter
  /// does not hide the others; only a total failure throws.
  Future<List<GdgEvent>> upcoming(List<GdgChapter> chapters) async {
    if (chapters.isEmpty) return const [];
    final results = await Future.wait(chapters.map((c) async {
      try {
        return await chapterEvents(c);
      } catch (_) {
        return null;
      }
    }));
    if (results.every((r) => r == null)) {
      throw const GdgApiException('Could not load GDG events right now.');
    }
    return mergeUpcoming(results.whereType<List<GdgEvent>>().expand((e) => e));
  }

  /// Dedupes, drops past events and sorts by start time.
  static List<GdgEvent> mergeUpcoming(Iterable<GdgEvent> events, {DateTime? now}) {
    final cutoff = now ?? DateTime.now();
    final byId = {for (final e in events) e.id: e};
    final list = byId.values.where((e) => e.endAt.isAfter(cutoff)).toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
    return list;
  }

  Future<GdgEvent> detail(int eventId) => _api.fetchDetail(eventId);

  /// Chapter-filtered lists no longer carry the chapter's name, but each
  /// event's detail does. Returns null when the chapter has no events.
  Future<String?> resolveChapterName(int chapterId) async {
    final json = await _api.fetchChapterJson(chapterId);
    final results = json['results'];
    if (results is! List || results.isEmpty) return null;
    final first = results.first;
    final id = first is Map<String, dynamic> ? first['id'] : null;
    if (id is! num) return null;
    final event = await _api.fetchDetail(id.toInt());
    return event.chapterName;
  }

  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    for (final k in prefs.getKeys().where((k) => k.startsWith(_prefix)).toList()) {
      await prefs.remove(k);
    }
  }
}
