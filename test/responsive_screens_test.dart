import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gocollab/core/theme/app_theme.dart';
import 'package:gocollab/features/admin/presentation/providers/admin_providers.dart';
import 'package:gocollab/features/admin/presentation/screens/admin_chapters_screen.dart';
import 'package:gocollab/features/admin/presentation/screens/admin_members_screen.dart';
import 'package:gocollab/features/admin/presentation/screens/audit_log_screen.dart';
import 'package:gocollab/features/auth/domain/entities/app_user.dart';
import 'package:gocollab/features/auth/domain/entities/user_role.dart';
import 'package:gocollab/features/auth/domain/entities/verification_status.dart';
import 'package:gocollab/features/auth/presentation/providers/auth_providers.dart';
import 'package:gocollab/features/auth/presentation/providers/chapter_providers.dart';
import 'package:gocollab/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:gocollab/features/auth/presentation/screens/login_screen.dart';
import 'package:gocollab/features/auth/presentation/screens/register_screen.dart';
import 'package:gocollab/features/events/domain/entities/event.dart';
import 'package:gocollab/features/events/domain/entities/event_attendee.dart';
import 'package:gocollab/features/events/presentation/providers/event_providers.dart';
import 'package:gocollab/features/events/presentation/screens/event_attendees_screen.dart';
import 'package:gocollab/features/events/presentation/screens/event_detail_screen.dart';
import 'package:gocollab/features/gdg_events/domain/entities/gdg_event.dart';
import 'package:gocollab/features/gdg_events/presentation/providers/gdg_providers.dart';
import 'package:gocollab/features/gdg_events/presentation/screens/gdg_chapters_screen.dart';
import 'package:gocollab/features/gdg_events/presentation/screens/gdg_event_detail_screen.dart';
import 'package:gocollab/features/notifications/domain/entities/app_notification.dart';
import 'package:gocollab/features/notifications/presentation/providers/notification_providers.dart';
import 'package:gocollab/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:gocollab/features/opportunities/domain/entities/opportunity.dart';
import 'package:gocollab/features/opportunities/presentation/providers/opportunity_providers.dart';
import 'package:gocollab/features/opportunities/presentation/screens/opportunity_detail_screen.dart';
import 'package:gocollab/features/partnerships/domain/entities/partner.dart';
import 'package:gocollab/features/partnerships/presentation/providers/partnership_providers.dart';
import 'package:gocollab/features/partnerships/presentation/screens/partner_detail_screen.dart';
import 'package:gocollab/features/profile/presentation/providers/profile_providers.dart';
import 'package:gocollab/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:gocollab/features/profile/presentation/screens/profile_screen.dart';
import 'package:gocollab/features/settings/presentation/screens/settings_screen.dart';
import 'package:gocollab/features/verification/presentation/providers/verification_providers.dart';
import 'package:gocollab/features/verification/presentation/screens/verification_screen.dart';

AppUser _user(UserRole role, {VerificationStatus status = VerificationStatus.verified}) => AppUser(
      id: 'u1',
      email: 'someone.with.a.fairly.long.address@students.nu-baliwag.edu.ph',
      fullName: 'Google Developer Groups on Campus National University Baliwag Officer',
      role: role,
      chapterId: role == UserRole.member ? null : 'c1',
      points: 32,
      bio: 'NU Baliwag Branch with a longer biography line to test wrapping across narrow screens',
      skills: const ['Flutter', 'Dart', 'Supabase', 'Cloud Computing', 'Machine Learning'],
      verificationStatus: status,
    );

final _now = DateTime.now();

Event _event() => Event(
      id: 'e1',
      title: 'A deliberately long event title to test wrapping behaviour',
      description: 'A long description. ' * 20,
      category: EventCategory.workshop,
      startAt: _now.add(const Duration(days: 3)),
      endAt: _now.add(const Duration(days: 3, hours: 3)),
      status: EventStatus.upcoming,
      venueName: 'National University Baliwag Main Campus Auditorium',
      venueAddress: 'Doña Remedios Trinidad Highway, Baliwag, Bulacan',
      latitude: 14.95,
      longitude: 121.26,
      capacity: 100,
      registeredCount: 12,
      creatorName: 'Google Developer Groups on Campus',
      isRegistered: true,
      myQrCode: 'qr123',
      createdBy: 'u1',
      partnerId: 'p1',
      partnerName: 'A Partner Organisation With A Long Name',
      gdgEventUrl: 'https://gdg.community.dev/events/details/x/',
      feedbackFormUrl: 'https://forms.gle/x',
    );

final _opp = Opportunity(
  id: 'o1',
  title: 'GDGoC Philippines Nationwide Hackathon and Innovation Challenge',
  organization: 'Google Developer Groups on Campus Philippines',
  type: OpportunityType.hackathon,
  description: 'Description ' * 30,
  requirements: 'Requirement one, requirement two, requirement three and more',
  location: 'Multiple campuses across the Philippines',
  applicationUrl: 'https://example.com/apply',
  deadline: _now.add(const Duration(days: 9)),
);

const _partner = Partner(
  id: 'p1',
  name: 'A Partner Organisation With A Rather Long Company Name Inc.',
  category: PartnerCategory.industry,
  collaborationStatus: CollaborationStatus.active,
  contactPerson: 'A Contact Person With A Long Name',
  contactEmail: 'a.very.long.contact.email.address@partner-organisation.example.com',
  contactPhone: '+63 912 345 6789',
  address: 'Unit 1204, Some Very Long Building Name, Some Long Street Name, Makati City',
  website: 'https://www.partner-organisation.example.com/about/us',
);

final _gdg = GdgEvent(
  id: 1,
  title: 'DevFest Manila 2026 Vibe Lounge with a very long descriptive title',
  startAt: _now.add(const Duration(days: 4)),
  endAt: _now.add(const Duration(days: 4, hours: 4)),
  url: 'https://gdg.community.dev/events/details/x/',
  chapterId: 605,
  chapterName: 'GDG on Campus Polytechnic University of the Philippines',
  city: 'Manila',
  country: 'PH',
  venueName: 'Polytechnic University of the Philippines Main Campus',
  venueAddress: 'Anonas Street, Sta. Mesa, Manila',
  latitude: 14.59,
  longitude: 121.01,
  descriptionHtml: '<p>${'Some description text. ' * 20}</p>',
);

List<Override> _overrides(UserRole role, {VerificationStatus status = VerificationStatus.verified}) => [
      currentUserProvider.overrideWith((ref) => Stream.value(_user(role, status: status))),
      eventDetailProvider.overrideWith((ref, id) async => _event()),
      eventAttendeesProvider.overrideWith((ref, id) async => [
            const EventAttendee(userId: 'a', name: 'An Attendee With A Quite Long Full Name Indeed', studentNumber: '2023-123456'),
            EventAttendee(userId: 'b', name: 'Present Person', checkedInAt: DateTime.now(), method: 'qr'),
            const EventAttendee(userId: 'c', name: 'No Show', status: 'no-show'),
          ]),
      opportunityDetailProvider.overrideWith((ref, id) async => _opp),
      partnerDetailProvider.overrideWith((ref, id) async => _partner),
      sponsorshipsProvider.overrideWith((ref, id) async => []),
      meetingsProvider.overrideWith((ref, id) async => []),
      communicationsProvider.overrideWith((ref, id) async => []),
      gdgEventDetailProvider.overrideWith((ref, id) async => _gdg),
      gdgChaptersProvider.overrideWith((ref) async => const [
            GdgChapter(id: 605, name: 'GDG on Campus Polytechnic University of the Philippines', ownerChapterId: 'c1', isOwn: true),
            GdgChapter(id: 484, name: 'GDG Cloud Manila', ownerChapterId: 'other'),
          ]),
      notificationsProvider.overrideWith((ref) => Stream.value([
            AppNotification(
              id: 'n1',
              title: 'Application claim approved (+10 points)',
              body: 'Thanks for applying. Your points were added to your account.',
              type: NotificationType.fromKey('general'),
              isRead: false,
              createdAt: _now,
            ),
          ])),
      eventHistoryProvider.overrideWith((ref) async => []),
      communityPointsProvider.overrideWith((ref) async => 32),
      chapterOptionsProvider.overrideWith((ref) async => const [
            ChapterOption(id: 'c1', name: 'GDGoC NU Baliwag', campus: 'National University - Baliwag'),
            ChapterOption(id: 'c2', name: 'GDGoC Cebu', campus: 'University of Cebu', isActive: false),
          ]),
      adminMembersProvider.overrideWith((ref) async => const [
            AdminMember(id: 'm1', fullName: 'A Member With A Long Full Name', email: 'long.email.address@students.example.edu.ph', roleId: 1),
            AdminMember(id: 'm2', fullName: 'An Officer', email: 'officer@example.com', roleId: 2, chapterId: 'c1'),
          ]),
      auditLogProvider.overrideWith((ref) async => [
            AuditEntry(
              id: 'a1',
              action: 'claim.bulk_approved',
              createdAt: _now,
              actorName: 'Google Developer Groups Officer',
              detail: const {'count': 12, 'reason': 'Looks good to me, all proofs are valid and readable'},
            ),
          ]),
      myVerificationRequestProvider.overrideWith((ref) async => null),
    ];

final _seen = <String>{};

void _collect(FlutterErrorDetails d) {
  final deep = d.toDiagnosticsNode().toStringDeep();
  if (!deep.contains('overflowed')) return;
  final file = RegExp(r'lib/[\w/]+\.dart:\d+').allMatches(deep).map((m) => m.group(0)).toSet().join(', ');
  final amount = RegExp(r'overflowed by [\d.]+ pixels on the \w+').firstMatch(deep)?.group(0) ?? 'overflow';
  _seen.add('$amount @ $file');
}

typedef _Screen = ({String name, Widget widget, UserRole role, VerificationStatus status});

void main() {
  final screens = <_Screen>[
    (name: 'event detail', widget: const EventDetailScreen(eventId: 'e1'), role: UserRole.member, status: VerificationStatus.verified),
    (name: 'event detail (officer)', widget: const EventDetailScreen(eventId: 'e1'), role: UserRole.officer, status: VerificationStatus.verified),
    (name: 'attendees', widget: const EventAttendeesScreen(eventId: 'e1'), role: UserRole.officer, status: VerificationStatus.verified),
    (name: 'opportunity detail', widget: const OpportunityDetailScreen(opportunityId: 'o1'), role: UserRole.member, status: VerificationStatus.verified),
    (name: 'partner detail', widget: const PartnerDetailScreen(partnerId: 'p1'), role: UserRole.officer, status: VerificationStatus.verified),
    (name: 'gdg event detail', widget: const GdgEventDetailScreen(eventId: 1), role: UserRole.member, status: VerificationStatus.verified),
    (name: 'gdg chapters', widget: const GdgChaptersScreen(), role: UserRole.officer, status: VerificationStatus.verified),
    (name: 'notifications', widget: const NotificationsScreen(), role: UserRole.member, status: VerificationStatus.verified),
    (name: 'profile', widget: const ProfileScreen(), role: UserRole.member, status: VerificationStatus.verified),
    (name: 'edit profile', widget: const EditProfileScreen(), role: UserRole.member, status: VerificationStatus.verified),
    (name: 'settings', widget: const SettingsScreen(), role: UserRole.member, status: VerificationStatus.verified),
    (name: 'verification (unverified)', widget: const VerificationScreen(), role: UserRole.member, status: VerificationStatus.unverified),
    (name: 'admin chapters', widget: const AdminChaptersScreen(), role: UserRole.admin, status: VerificationStatus.verified),
    (name: 'admin members', widget: const AdminMembersScreen(), role: UserRole.admin, status: VerificationStatus.verified),
    (name: 'audit log', widget: const AuditLogScreen(), role: UserRole.admin, status: VerificationStatus.verified),
    (name: 'login', widget: const LoginScreen(), role: UserRole.member, status: VerificationStatus.verified),
    (name: 'register', widget: const RegisterScreen(), role: UserRole.member, status: VerificationStatus.verified),
    (name: 'forgot password', widget: const ForgotPasswordScreen(), role: UserRole.member, status: VerificationStatus.verified),
  ];

  const sizes = <String, Size>{
    'phone portrait': Size(360, 740),
    'small phone': Size(320, 568),
    'phone landscape': Size(740, 360),
    'tablet portrait': Size(800, 1280),
  };

  for (final screen in screens) {
    for (final entry in sizes.entries) {
      testWidgets('${screen.name} fits on ${entry.key} at text x1.2', (tester) async {
        _seen.clear();
        final original = FlutterError.onError;
        FlutterError.onError = _collect;
        try {
          tester.view.physicalSize = entry.value;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(ProviderScope(
            overrides: _overrides(screen.role, status: screen.status),
            child: MaterialApp(
              theme: AppTheme.light,
              builder: (context, child) => MediaQuery.withClampedTextScaling(
                minScaleFactor: 1.2,
                maxScaleFactor: 1.2,
                child: child!,
              ),
              home: screen.widget,
            ),
          ));
          await tester.pump(const Duration(milliseconds: 400));
          await tester.pump(const Duration(milliseconds: 400));
        } finally {
          FlutterError.onError = original;
        }
        tester.takeException();
        expect(_seen, isEmpty, reason: '${screen.name} ${entry.key}');
      });
    }
  }
}
