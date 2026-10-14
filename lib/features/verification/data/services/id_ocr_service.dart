import 'package:image_picker/image_picker.dart';
import 'id_ocr_stub.dart' if (dart.library.io) 'id_ocr_mobile.dart' as impl;

/// How well the text read off a school ID matches the account.
enum OcrResult {
  notRun,
  matched,
  partial,
  mismatch;

  String get key => switch (this) {
        OcrResult.notRun => 'not_run',
        OcrResult.matched => 'matched',
        OcrResult.partial => 'partial',
        OcrResult.mismatch => 'mismatch',
      };

  static OcrResult fromKey(String? key) => OcrResult.values.firstWhere(
        (r) => r.key == key,
        orElse: () => OcrResult.notRun,
      );

  String get label => switch (this) {
        OcrResult.notRun => 'OCR not run',
        OcrResult.matched => 'OCR matched name & number',
        OcrResult.partial => 'OCR partial match',
        OcrResult.mismatch => 'OCR found no match',
      };
}

/// Reads the ID photo on-device (ML Kit on Android/iOS) and compares it with
/// what the member typed. The result is only a hint for the officer — it is
/// produced on the member's own device, so it can never verify an account on
/// its own. On web, where ML Kit isn't available, it reports [OcrResult.notRun].
class IdOcrService {
  const IdOcrService();

  Future<OcrResult> check({
    required XFile image,
    required String studentNumber,
    required String fullName,
  }) async {
    final text = await impl.readText(image);
    if (text == null) return OcrResult.notRun;
    return compare(text, studentNumber: studentNumber, fullName: fullName);
  }

  /// Pure matching logic, separate from the OCR engine so it is testable.
  static OcrResult compare(String ocrText, {required String studentNumber, required String fullName}) {
    String digits(String s) => s.replaceAll(RegExp(r'[^0-9A-Za-z]'), '').toUpperCase();

    final haystack = digits(ocrText);
    final number = digits(studentNumber);
    final numberFound = number.length >= 4 && haystack.contains(number);

    final upper = ocrText.toUpperCase();
    final nameTokens = fullName
        .toUpperCase()
        .split(RegExp(r'[^A-Z]+'))
        .where((t) => t.length >= 3)
        .toList();
    final nameHits = nameTokens.where(upper.contains).length;
    final nameFound = nameTokens.isNotEmpty && nameHits >= (nameTokens.length >= 2 ? 2 : 1);

    if (numberFound && nameFound) return OcrResult.matched;
    if (numberFound || nameHits > 0) return OcrResult.partial;
    return OcrResult.mismatch;
  }
}
