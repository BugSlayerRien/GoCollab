import 'package:flutter_test/flutter_test.dart';
import 'package:gocollab/features/auth/domain/entities/user_role.dart';
import 'package:gocollab/features/events/domain/entities/event_attendee.dart';
import 'package:gocollab/features/gdg_events/domain/entities/gdg_event.dart';
import 'package:gocollab/features/profile/domain/certificate_pdf.dart';

void main() {
  group('UserRole', () {
    test('maps the three role ids', () {
      expect(UserRole.fromId(1), UserRole.member);
      expect(UserRole.fromId(2), UserRole.officer);
      expect(UserRole.fromId(3), UserRole.admin);
    });

    test('unknown ids fall back to member, never to a higher role', () {
      expect(UserRole.fromId(0), UserRole.member);
      expect(UserRole.fromId(99), UserRole.member);
    });

    test('only an officer counts as officer', () {
      expect(UserRole.admin.isOfficer, isFalse);
      expect(UserRole.officer.isOfficer, isTrue);
      expect(UserRole.admin.isAdmin, isTrue);
    });
  });

  group('GdgChapter ownership', () {
    test('owner chapter is part of equality', () {
      const a = GdgChapter(id: 1, name: 'x', ownerChapterId: 'c1');
      const b = GdgChapter(id: 1, name: 'x', ownerChapterId: 'c2');
      expect(a == b, isFalse);
    });
  });

  group('EventAttendee', () {
    test('no-show is detected from the registration status', () {
      const a = EventAttendee(userId: 'u', name: 'n', status: 'no-show');
      expect(a.isNoShow, isTrue);
      expect(a.isCheckedIn, isFalse);
    });
  });

  test('certificate PDF is generated', () async {
    final bytes = await buildCertificatePdf(
      memberName: 'Juan Dela Cruz',
      eventTitle: 'DevFest Baliwag',
      eventDate: DateTime(2026, 11, 7),
      certificateNumber: 'GC-2026-ABCD1234',
    );
    expect(bytes.length, greaterThan(500));
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });
}
