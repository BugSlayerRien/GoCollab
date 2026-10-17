import 'package:flutter_test/flutter_test.dart';
import 'package:gocollab/features/gdg_events/data/gdg_community_api.dart';
import 'package:gocollab/features/gdg_events/data/gdg_events_repository.dart';
import 'package:gocollab/features/gdg_events/domain/entities/gdg_event.dart';

Map<String, dynamic> _event({
  int id = 1,
  String title = 'DevFest Manila',
  String start = '2026-11-07T09:00:00+08:00',
  String end = '2026-11-07T17:00:00+08:00',
  bool hidden = false,
  bool test = false,
}) =>
    {
      'id': id,
      'title': title,
      'start_date': start,
      'end_date': end,
      'url': 'https://gdg.community.dev/events/details/x-$id/',
      'is_hidden': hidden,
      'is_test': test,
      'chapter': {'id': 605, 'title': 'GDG Manila', 'city': 'Manila', 'country': 'PH'},
    };

void main() {
  group('GdgCommunityApi.parseList', () {
    test('parses a normal list response', () {
      final events = GdgCommunityApi.parseList({
        'results': [_event(id: 1), _event(id: 2, title: 'Build with AI')],
      });
      expect(events.map((e) => e.id), [1, 2]);
      expect(events.first.chapterName, 'GDG Manila');
      expect(events.first.country, 'PH');
      expect(events.first.startAt.isUtc, isFalse);
    });

    test('skips hidden and test events', () {
      final events = GdgCommunityApi.parseList({
        'results': [_event(id: 1, hidden: true), _event(id: 2, test: true), _event(id: 3)],
      });
      expect(events.map((e) => e.id), [3]);
    });

    test('skips malformed events instead of throwing', () {
      final events = GdgCommunityApi.parseList({
        'results': [
          {'id': 'oops'},
          {'title': 'no id'},
          _event(id: 9)..['start_date'] = 'not-a-date',
          _event(id: 4),
        ],
      });
      expect(events.map((e) => e.id), [4]);
    });

    test('returns empty for an unexpected response shape', () {
      expect(GdgCommunityApi.parseList({'detail': 'You do not have permission'}), isEmpty);
      expect(GdgCommunityApi.parseList({'results': 'nope'}), isEmpty);
    });
  });

  // The API only embeds `chapter` on events from the GLOBAL list. A
  // `?chapter=<id>` query (what the app sends) returns events without it.
  // Real response shape, captured from gdg.community.dev:
  Map<String, dynamic> chapterFilteredEvent({int id = 130732}) => {
        'id': id,
        'title': 'DevFest Manila 2026 Vibe Lounge',
        'start_date': '2026-10-17T13:00:00+08:00',
        'end_date': '2026-10-17T18:00:00+08:00',
        'url': 'https://gdg.community.dev/events/details/google-gdg-manila-p/',
        'status': 'Published',
        'is_hidden': false,
        'is_test': false,
        'allows_cohosting': false,
        'cohost_registration_url': 'https://gdg.community.dev/events/details/google-gdg-manila-p/',
        'title_translated': null,
      };

  group('chapter-filtered responses (no embedded chapter)', () {
    const manila = GdgChapter(id: 605, name: 'GDG Manila', country: 'PH');

    test('REGRESSION: events parse using the requested chapter', () {
      final events = GdgCommunityApi.parseList({
        'results': [chapterFilteredEvent(), chapterFilteredEvent(id: 2)],
      }, chapter: manila);
      expect(events, hasLength(2));
      expect(events.first.chapterId, 605);
      expect(events.first.chapterName, 'GDG Manila');
      expect(events.first.country, 'PH');
    });

    test('without a chapter to fall back on they are skipped', () {
      expect(GdgCommunityApi.parseList({'results': [chapterFilteredEvent()]}), isEmpty);
    });

    test('rawResultCount distinguishes "no events" from "unreadable events"', () {
      expect(GdgCommunityApi.rawResultCount({'results': []}), 0);
      expect(GdgCommunityApi.rawResultCount({'results': [chapterFilteredEvent()]}), 1);
      expect(GdgCommunityApi.rawResultCount({'detail': 'nope'}), 0);
    });

    test('an embedded chapter still wins over the fallback', () {
      final events = GdgCommunityApi.parseList({
        'results': [_event(id: 1)],
      }, chapter: const GdgChapter(id: 999, name: 'Other', country: 'US'));
      expect(events.single.chapterId, 605);
      expect(events.single.chapterName, 'GDG Manila');
    });
  });

  group('GdgCommunityApi.parseEvent (detail)', () {
    test('reads venue, coordinates and description', () {
      final e = GdgCommunityApi.parseEvent({
        ..._event(id: 7),
        'description': '<p>Hello</p>',
        'venue_name': 'NU Baliwag',
        'venue_address': 'Doña Remedios Trinidad Hwy',
        'venue_latitude': '14.9553',
        'venue_longitude': 121.2625,
        'is_virtual_event': false,
        'total_capacity': 150,
      })!;
      expect(e.descriptionHtml, '<p>Hello</p>');
      expect(e.venueName, 'NU Baliwag');
      expect(e.latitude, closeTo(14.9553, 1e-6));
      expect(e.longitude, closeTo(121.2625, 1e-6));
      expect(e.hasLocation, isTrue);
      expect(e.capacity, 150);
    });

    test('treats blank strings as missing', () {
      final e = GdgCommunityApi.parseEvent({..._event(id: 8), 'venue_name': '   ', 'description': ''})!;
      expect(e.venueName, isNull);
      expect(e.descriptionHtml, isNull);
      expect(e.hasLocation, isFalse);
    });
  });

  group('GdgEventsRepository.mergeUpcoming', () {
    GdgEvent ev(int id, String start, String end) => GdgCommunityApi.parseEvent(
          _event(id: id, start: start, end: end),
        )!;

    test('drops past events, dedupes by id and sorts by start', () {
      final now = DateTime.parse('2026-10-20T00:00:00Z');
      final merged = GdgEventsRepository.mergeUpcoming([
        ev(1, '2026-12-01T09:00:00Z', '2026-12-01T12:00:00Z'),
        ev(2, '2026-10-01T09:00:00Z', '2026-10-01T12:00:00Z'), // past
        ev(3, '2026-11-01T09:00:00Z', '2026-11-01T12:00:00Z'),
        ev(3, '2026-11-01T09:00:00Z', '2026-11-01T12:00:00Z'), // duplicate
      ], now: now);
      expect(merged.map((e) => e.id), [3, 1]);
    });

    test('keeps an event that started but has not ended', () {
      final now = DateTime.parse('2026-11-01T10:00:00Z');
      final merged = GdgEventsRepository.mergeUpcoming([
        ev(5, '2026-11-01T09:00:00Z', '2026-11-01T17:00:00Z'),
      ], now: now);
      expect(merged.map((e) => e.id), [5]);
    });
  });
}
