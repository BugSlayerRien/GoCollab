import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

/// Flattens an HTML snippet (e.g. a GDG event description) to readable plain
/// text, keeping paragraph and line breaks. Tags and scripts are dropped.
String htmlToPlainText(String html) {
  final withBreaks = html.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
  final doc = html_parser.parse(withBreaks);
  for (final el in doc.querySelectorAll('script,style')) {
    el.remove();
  }
  for (final el in doc.querySelectorAll('p,h1,h2,h3,h4,h5,h6')) {
    el.append(dom.Text('\n\n'));
  }
  for (final el in doc.querySelectorAll('li,div,tr')) {
    el.append(dom.Text('\n'));
  }
  final text = doc.body?.text ?? '';
  return text
      .replaceAll(' ', ' ')
      .replaceAll(RegExp(r'[ \t]+\n'), '\n')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
}
