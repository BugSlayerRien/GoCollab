import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Draws a certificate of attendance. Pure function of its inputs so it can
/// run anywhere (and be tested) without touching the network.
Future<Uint8List> buildCertificatePdf({
  required String memberName,
  required String eventTitle,
  required DateTime eventDate,
  required String certificateNumber,
}) async {
  const months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  final date = '${months[eventDate.month - 1]} ${eventDate.day}, ${eventDate.year}';

  final doc = pw.Document(title: 'Certificate of Attendance', author: 'GoCollab');
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(32),
      build: (context) => pw.Container(
        decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.blue700, width: 3)),
        padding: const pw.EdgeInsets.all(28),
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Text('GoCollab', style: pw.TextStyle(fontSize: 18, color: PdfColors.blue700, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.Text('Google Developer Groups on Campus Philippines',
                style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
            pw.SizedBox(height: 28),
            pw.Text('CERTIFICATE OF ATTENDANCE',
                style: pw.TextStyle(fontSize: 30, fontWeight: pw.FontWeight.bold, letterSpacing: 2)),
            pw.SizedBox(height: 26),
            pw.Text('This certifies that', style: const pw.TextStyle(fontSize: 13)),
            pw.SizedBox(height: 10),
            pw.Text(memberName, style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
            pw.SizedBox(height: 10),
            pw.Text('attended', style: const pw.TextStyle(fontSize: 13)),
            pw.SizedBox(height: 10),
            pw.Text(eventTitle,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Text('on $date', style: const pw.TextStyle(fontSize: 13)),
            pw.SizedBox(height: 34),
            pw.Text('Certificate no. $certificateNumber',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          ],
        ),
      ),
    ),
  );
  return doc.save();
}
