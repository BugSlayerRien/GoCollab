import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/entities/gdg_event.dart';

class GdgApiException implements Exception {
  const GdgApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Reads the public event API that gdg.community.dev's own site uses.
///
/// It is unofficial and undocumented, so everything here is defensive: a
/// malformed event is skipped rather than failing the whole list, and the
/// repository above falls back to cached data when the site is unreachable.
/// Only per-chapter queries are made — the global list is ~70k events.
class GdgCommunityApi {
  GdgCommunityApi({http.Client? client}) : _http = client ?? http.Client();

  final http.Client _http;

  static const _host = 'gdg.community.dev';

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    try {
      final response = await _http.get(uri, headers: const {'Accept': 'application/json'}).timeout(
            const Duration(seconds: 15),
          );
      if (response.statusCode != 200) {
        throw GdgApiException('GDG community site returned ${response.statusCode}.');
      }
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) throw const GdgApiException('Unexpected response from GDG site.');
      return decoded;
    } on TimeoutException {
      throw const GdgApiException('The GDG community site took too long to respond.');
    } on FormatException {
      throw const GdgApiException('Unexpected response from GDG site.');
    } on http.ClientException {
      throw const GdgApiException('Could not reach the GDG community site.');
    }
  }

  /// Upcoming-first list for one chapter (the API returns newest start first).
  Future<Map<String, dynamic>> fetchChapterJson(int chapterId) {
    return _getJson(Uri.https(_host, '/api/event/', {
      'chapter': '$chapterId',
      'status': 'Published',
    }));
  }

  Future<List<GdgEvent>> fetchChapterEvents(GdgChapter chapter) async =>
      parseList(await fetchChapterJson(chapter.id), chapter: chapter);

  Future<GdgEvent> fetchDetail(int eventId) async {
    final json = await _getJson(Uri.https(_host, '/api/event/$eventId/'));
    final event = parseEvent(json);
    if (event == null) throw const GdgApiException('Could not read this event.');
    return event;
  }

  // ---- Pure parsing (unit-tested against saved responses) -----------------

  /// Number of entries in `results`, parseable or not. Lets callers tell
  /// "the chapter has no events" apart from "the response shape changed".
  static int rawResultCount(Map<String, dynamic> json) {
    final results = json['results'];
    return results is List ? results.length : 0;
  }

  /// [chapter] is the chapter that was requested. The API only embeds a
  /// `chapter` object on events from the global list; a `?chapter=<id>`
  /// query omits it, so the requested chapter fills in.
  static List<GdgEvent> parseList(Map<String, dynamic> json, {GdgChapter? chapter}) {
    final results = json['results'];
    if (results is! List) return const [];
    return results
        .whereType<Map<String, dynamic>>()
        .map((e) => parseEvent(e, chapter: chapter))
        .whereType<GdgEvent>()
        .toList();
  }

  /// Returns null for hidden/test/unparseable events instead of throwing.
  static GdgEvent? parseEvent(Map<String, dynamic> map, {GdgChapter? chapter}) {
    try {
      if (map['is_hidden'] == true || map['is_test'] == true) return null;
      final embedded = map['chapter'];
      final chapterMap = embedded is Map<String, dynamic> ? embedded : null;
      final id = map['id'];
      final title = map['title'];
      final start = map['start_date'];
      final end = map['end_date'];
      final url = map['url'];
      if (id is! num || title is! String || start is! String || url is! String) return null;
      final embeddedId = chapterMap?['id'];
      final chapterId = embeddedId is num ? embeddedId.toInt() : chapter?.id;
      if (chapterId == null) return null;

      double? number(dynamic v) => v is num ? v.toDouble() : double.tryParse('${v ?? ''}');
      String? text(dynamic v) => (v is String && v.trim().isNotEmpty) ? v.trim() : null;

      final startAt = DateTime.parse(start).toLocal();
      return GdgEvent(
        id: id.toInt(),
        title: title.trim(),
        startAt: startAt,
        endAt: end is String ? DateTime.parse(end).toLocal() : startAt,
        url: url,
        chapterId: chapterId,
        chapterName: text(chapterMap?['title']) ?? chapter?.name ?? 'GDG chapter',
        city: text(chapterMap?['city']),
        country: text(chapterMap?['country']) ?? chapter?.country,
        descriptionHtml: text(map['description']),
        venueName: text(map['venue_name']),
        venueAddress: text(map['venue_address']),
        latitude: number(map['venue_latitude']),
        longitude: number(map['venue_longitude']),
        isVirtual: map['is_virtual_event'] == true,
        capacity: (map['total_capacity'] as num?)?.toInt(),
        bannerUrl: text(map['cropped_banner_url']),
      );
    } catch (_) {
      return null;
    }
  }
}
