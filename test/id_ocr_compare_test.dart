import 'package:flutter_test/flutter_test.dart';
import 'package:gocollab/features/verification/data/services/id_ocr_service.dart';

void main() {
  proofTests();

  const idText = 'NATIONAL UNIVERSITY BALIWAG\nSTUDENT ID\nDELA CRUZ, JUAN M.\n2023-161615\nBS COMPUTER SCIENCE';

  test('matches when number and name both appear', () {
    expect(
      IdOcrService.compare(idText, studentNumber: '2023-161615', fullName: 'Juan Dela Cruz'),
      OcrResult.matched,
    );
  });

  test('partial when only the number appears', () {
    expect(
      IdOcrService.compare(idText, studentNumber: '2023161615', fullName: 'Someone Else'),
      OcrResult.partial,
    );
  });

  test('mismatch when nothing lines up', () {
    expect(
      IdOcrService.compare(idText, studentNumber: '999999', fullName: 'Maria Santos'),
      OcrResult.mismatch,
    );
  });
}

void proofTests() {
  group('compareProof', () {
    const shot = 'Application received\nGoogle STEP Internship\nThank you for applying to Google';

    test('matched when organization and title both appear', () {
      expect(
        IdOcrService.compareProof(shot, organization: 'Google', title: 'STEP Internship'),
        OcrResult.matched,
      );
    });

    test('mismatch for an unrelated screenshot', () {
      expect(
        IdOcrService.compareProof('Meme of a cat', organization: 'Google', title: 'STEP Internship'),
        OcrResult.mismatch,
      );
    });
  });
}
