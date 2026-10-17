import 'package:flutter_test/flutter_test.dart';
import 'package:gocollab/core/utils/html_text.dart';

void main() {
  test('keeps paragraph breaks and strips tags', () {
    expect(
      htmlToPlainText('<h1><strong>DevFest</strong></h1><p>Join us<br>at NU</p><p>Free entry</p>'),
      'DevFest\n\nJoin us\nat NU\n\nFree entry',
    );
  });

  test('drops scripts and styles', () {
    expect(htmlToPlainText('<p>Hi</p><script>alert(1)</script><style>p{}</style>'), 'Hi');
  });

  test('handles empty and plain input', () {
    expect(htmlToPlainText(''), '');
    expect(htmlToPlainText('just text'), 'just text');
  });
}
