import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gocollab/core/theme/app_theme.dart';
import 'package:gocollab/features/analytics/domain/entities/analytics_snapshot.dart';
import 'package:gocollab/features/analytics/presentation/providers/analytics_providers.dart';
import 'package:gocollab/features/announcements/domain/entities/announcement.dart';
import 'package:gocollab/features/announcements/presentation/providers/announcement_providers.dart';
import 'package:gocollab/features/application_claims/presentation/providers/claim_providers.dart';
import 'package:gocollab/features/auth/domain/entities/app_user.dart';
import 'package:gocollab/features/auth/domain/entities/user_role.dart';
import 'package:gocollab/features/auth/domain/entities/verification_status.dart';
import 'package:gocollab/features/auth/presentation/providers/auth_providers.dart';
import 'package:gocollab/features/dashboard/domain/entities/community_stats.dart';
import 'package:gocollab/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:gocollab/features/events/domain/entities/event.dart';
import 'package:gocollab/features/events/presentation/providers/event_providers.dart';
import 'package:gocollab/features/gdg_events/domain/entities/gdg_event.dart';
import 'package:gocollab/features/gdg_events/presentation/providers/gdg_providers.dart';
import 'package:gocollab/features/notifications/presentation/providers/notification_providers.dart';
import 'package:gocollab/features/opportunities/domain/entities/opportunity.dart';
import 'package:gocollab/features/opportunities/presentation/providers/opportunity_providers.dart';
import 'package:gocollab/features/partnerships/domain/entities/partner.dart';
import 'package:gocollab/features/partnerships/presentation/providers/partnership_providers.dart';
import 'package:gocollab/features/profile/domain/entities/event_history_item.dart';
import 'package:gocollab/features/profile/presentation/providers/profile_providers.dart';
import 'package:gocollab/features/shell/presentation/providers/shell_providers.dart';
import 'package:gocollab/features/shell/presentation/screens/app_shell_screen.dart';
import 'package:gocollab/features/verification/presentation/providers/verification_providers.dart';

AppUser _user(UserRole role) => AppUser(
      id: 'u1',
      email: 'someone.with.a.fairly.long.address@students.nu-baliwag.edu.ph',
      fullName: 'Google Developer Groups on Campus National University Baliwag Officer',
      role: role,
      chapterId: 'c1',
      points: 32,
      bio: 'NU Baliwag Branch',
      verificationStatus: VerificationStatus.verified,
    );

final _now = DateTime.now();

List<Event> _events() => [
      for (var i = 0; i < 4; i++)
        Event(
          id: 'e$i',
          title: 'A deliberately long event title to test wrapping behaviour number $i',
          description: 'Description',
          category: EventCategory.workshop,
          startAt: _now.add(Duration(days: 3 + i)),
          endAt: _now.add(Duration(days: 3 + i, hours: 3)),
          status: EventStatus.upcoming,
          venueName: 'National University Baliwag Main Campus Auditorium',
          creatorName: 'Google Developer Groups on Campus',
          isRegistered: i.isEven,
          myQrCode: i.isEven ? 'qr$i' : null,
          createdBy: 'u1',
        ),
    ];

List<Opportunity> _opps() => [
      for (var i = 0; i < 3; i++)
        Opportunity(
          id: 'o$i',
          title: 'GDGoC Philippines Nationwide Hackathon and Innovation Challenge $i',
          organization: 'Google Developer Groups on Campus Philippines',
          type: OpportunityType.hackathon,
          description: 'Desc',
          location: 'Multiple campuses across the Philippines',
          deadline: _now.add(const Duration(days: 9)),
          isSaved: i == 0,
        ),
    ];

GdgEvent _gdg(int i) => GdgEvent(
      id: i,
      title: 'DevFest Manila 2026 Vibe Lounge with a very long descriptive title',
      startAt: _now.add(Duration(days: 4 + i)),
      endAt: _now.add(Duration(days: 4 + i, hours: 4)),
      url: 'https://gdg.community.dev/events/details/x/',
      chapterId: 605,
      chapterName: 'GDG on Campus Polytechnic University of the Philippines',
      city: 'Manila',
      country: 'PH',
    );

List<Override> _overrides(UserRole role) => [
      currentUserProvider.overrideWith((ref) => Stream.value(_user(role))),
      eventsListProvider.overrideWith((ref) async => _events()),
      eventHistoryProvider.overrideWith((ref) async => <EventHistoryItem>[]),
      opportunitiesListProvider.overrideWith((ref) async => _opps()),
      savedOpportunitiesProvider.overrideWith((ref) async => _opps().take(1).toList()),
      partnersListProvider.overrideWith((ref) async => [
            const Partner(
              id: 'p1',
              name: 'A Partner Organisation With A Rather Long Company Name Inc.',
              category: PartnerCategory.industry,
              collaborationStatus: CollaborationStatus.active,
              contactEmail: 'a.very.long.contact.email.address@partner-organisation.example.com',
            ),
          ]),
      announcementsListProvider.overrideWith((ref) async => [
            Announcement(
              id: 'a1',
              title: 'DevFest 2026 Registration is Now Open for everyone on campus',
              body: 'Registration for GDGoC Philippines DevFest 2026 is now live. Secure your slot before seats run out!',
              category: AnnouncementCategory.event,
              publishedAt: _now,
              isPinned: true,
            ),
          ]),
      analyticsSnapshotProvider.overrideWith((ref) async => AnalyticsSnapshot(
            activeMembers: 3,
            totalMembers: 3,
            totalEvents: 7,
            averageAttendanceRate: 0.4,
            totalEngagementActions: 20,
            growth: [for (var i = 0; i < 6; i++) GrowthPoint(month: DateTime(2026, 5 + i), newMembers: i)],
            eventPerformance: const [EventPerformance(eventTitle: 'Workshop with a very long name', registered: 10, attended: 4)],
          )),
      communityStatsProvider.overrideWith((ref) async =>
          const CommunityStats(totalMembers: 3, upcomingEventsCount: 7, openOpportunitiesCount: 7, userPoints: 32)),
      communityPointsProvider.overrideWith((ref) async => 32),
      gdgUpcomingEventsProvider.overrideWith((ref) async => [_gdg(1), _gdg(2)]),
      pendingVerificationRequestsProvider.overrideWith((ref) async => []),
      pendingClaimSummaryProvider.overrideWith((ref) async => []),
      notificationsProvider.overrideWith((ref) => Stream.value(const [])),
    ];

Future<void> _pump(WidgetTester tester, UserRole role, Size size, double scale) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: _overrides(role),
    child: MaterialApp(
      theme: AppTheme.light,
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        minScaleFactor: scale,
        maxScaleFactor: scale,
        child: child!,
      ),
      home: const AppShellScreen(),
    ),
  ));
  await tester.pump(const Duration(milliseconds: 300));
}

final _seen = <String>{};

void _collect(FlutterErrorDetails d) {
  final deep = d.toDiagnosticsNode().toStringDeep();
  if (!deep.contains('overflowed')) return;
  final file = RegExp(r'lib/[\w/]+\.dart:\d+').allMatches(deep).map((m) => m.group(0)).toSet().join(', ');
  final amount = RegExp(r'overflowed by [\d.]+ pixels on the \w+').firstMatch(deep)?.group(0) ?? 'overflow';
  _seen.add('$amount @ $file');
}

void main() {
  tearDownAll(() {
  });
  const sizes = <String, Size>{
    'phone portrait': Size(360, 740),
    'small phone': Size(320, 568),
    'phone landscape': Size(740, 360),
    'tablet portrait': Size(800, 1280),
  };

  for (final role in [UserRole.member, UserRole.officer, UserRole.admin]) {
    final tabs = switch (role) { UserRole.member => 5, UserRole.officer => 7, UserRole.admin => 2 };
    for (final entry in sizes.entries) {
      for (final scale in [1.0, 1.2]) {
        testWidgets('${role.name} tabs fit on ${entry.key} at text x$scale', (tester) async {
          _seen.clear();
          final original = FlutterError.onError;
          FlutterError.onError = _collect;
          try {
            for (var tab = 0; tab < tabs; tab++) {
              await _pump(tester, role, entry.value, scale);
              final container = ProviderScope.containerOf(tester.element(find.byType(AppShellScreen)));
              container.read(selectedTabIndexProvider.notifier).state = tab;
              await tester.pump(const Duration(milliseconds: 300));
              // tab $tab is the screen shown above
              final marker = tab;
              if (_seen.isNotEmpty) _seen.add('^ first seen on tab $marker');
              if (_seen.isNotEmpty) break;
            }
          } finally {
            FlutterError.onError = original;
          }
          expect(_seen, isEmpty, reason: '${role.name} ${entry.key} x$scale');
        });
      }
    }
  }

  for (final entry in sizes.entries) {
    testWidgets('officer sidebar opens and closes on ${entry.key}', (tester) async {
      _seen.clear();
      final original = FlutterError.onError;
      FlutterError.onError = _collect;
      try {
        await _pump(tester, UserRole.officer, entry.value, 1.2);
        // hidden by default: no destination labels on screen
        expect(find.text('Collapse menu'), findsNothing);
        await tester.tap(find.byTooltip('Menu').first);
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.text('Analytics'), findsWidgets);
        await tester.tap(find.byTooltip('Close menu'));
        await tester.pump(const Duration(milliseconds: 400));
      } finally {
        FlutterError.onError = original;
      }
      expect(_seen, isEmpty, reason: 'sidebar ${entry.key}');
    });
  }
}
