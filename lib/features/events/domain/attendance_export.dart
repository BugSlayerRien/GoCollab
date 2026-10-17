import 'package:intl/intl.dart';
import 'entities/event_attendee.dart';

/// Tab-separated table of an attendance list. Pasting TSV into Google Sheets
/// (or Excel) fills cells directly, so there is nothing to upload or convert.
String buildAttendanceTsv(List<EventAttendee> attendees) {
  final time = DateFormat('yyyy-MM-dd HH:mm');

  // Tabs and line breaks inside a value would shift columns or rows.
  String cell(String? value) => (value ?? '').replaceAll(RegExp(r'[\t\r\n]+'), ' ').trim();

  final rows = <List<String>>[
    ['Name', 'Student number', 'Status', 'Checked in at', 'Method'],
    for (final a in attendees)
      [
        cell(a.name),
        cell(a.studentNumber),
        a.isCheckedIn ? 'Present' : 'Registered',
        a.checkedInAt != null ? time.format(a.checkedInAt!.toLocal()) : '',
        a.method == null ? '' : (a.method == 'qr' ? 'QR scan' : 'Manual'),
      ],
  ];
  return rows.map((r) => r.join('\t')).join('\n');
}
