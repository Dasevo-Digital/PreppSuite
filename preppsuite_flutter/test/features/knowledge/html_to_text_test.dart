import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/knowledge/application/html_to_text.dart';

void main() {
  test('tags are dropped and their text kept', () {
    expect(
      htmlToIndexableText('<p>Trinkwasser ist <b>wichtig</b>.</p>'),
      'Trinkwasser ist wichtig .',
    );
  });

  test('a tag boundary separates words', () {
    // Without this "<b>Trink</b>wasser" would index as one term nobody
    // searches for, and two paragraphs would run into each other.
    expect(htmlToIndexableText('<b>Trink</b>wasser'), 'Trink wasser');
    expect(htmlToIndexableText('<p>eins</p><p>zwei</p>'), 'eins zwei');
  });

  test('scripts and styles are dropped whole, not just their tags', () {
    expect(
      htmlToIndexableText(
        '<style>body{color:red}</style><p>Text</p>'
        '<script>var x = "Wasser";</script>',
      ),
      'Text',
    );
  });

  test('entities become the characters they stand for', () {
    expect(
      htmlToIndexableText('<p>Wasser&nbsp;&amp;&nbsp;Brot &#8211; genug</p>'),
      'Wasser & Brot – genug',
    );
  });

  test('whitespace collapses so terms line up', () {
    expect(
      htmlToIndexableText('<p>viel\n\n   Platz\t hier</p>'),
      'viel Platz hier',
    );
  });

  test('an unclosed script does not swallow silently mid-word', () {
    // Damaged input should end the walk rather than loop or throw.
    expect(htmlToIndexableText('<p>Text</p><script>oh'), 'Text');
  });

  test('plain text without any markup comes through', () {
    expect(htmlToIndexableText('Notvorrat'), 'Notvorrat');
  });
}
