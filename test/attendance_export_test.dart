import 'package:flutter_test/flutter_test.dart';
import 'package:gocollab/features/events/domain/attendance_export.dart';
import 'package:gocollab/features/events/domain/entities/event_attendee.dart';

void main() {
  test('builds a header plus one row per attendee', () {
    final tsv = buildAttendanceTsv([
      EventAttendee(
        userId: '1',
        name: 'Juan Dela Cruz',
        studentNumber: '2023-161615',
        checkedInAt: DateTime(2026, 11, 7, 9, 5),
        method: 'qr',
      ),
      const EventAttendee(userId: '2', name: 'Maria Santos'),
    ]);
    final lines = tsv.split('\n');
    expect(lines.first, 'Name\tStudent number\tStatus\tChecked in at\tMethod');
    expect(lines[1], 'Juan Dela Cruz\t2023-161615\tPresent\t2026-11-07 09:05\tQR scan');
    expect(lines[2], 'Maria Santos\t\tRegistered\t\t');
    expect(lines.length, 3);
  });

  test('tabs and newlines in names cannot break the columns', () {
    final tsv = buildAttendanceTsv([
      const EventAttendee(userId: '1', name: 'Juan\tDela\nCruz'),
    ]);
    final row = tsv.split('\n')[1].split('\t');
    expect(row.length, 5);
    expect(row.first, 'Juan Dela Cruz');
  });

  test('empty list still returns the header', () {
    expect(buildAttendanceTsv(const []).split('\n'), hasLength(1));
  });
}
