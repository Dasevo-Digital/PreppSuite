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

  test('script and style are recognised in any case', () {
    expect(
      htmlToIndexableText(
        '<STYLE>p{}</STYLE><p>Text</p><Script type="x">Wasser</sCRIPT>',
      ),
      'Text',
    );
  });

  test('a long article is read in one pass, not once per tag', () {
    // Until #198 every tag lower-cased the whole document, so the time
    // grew with the square of the length: this one took over a minute.
    // The limit is generous on purpose; the old reading misses it by far.
    final html = StringBuffer();
    for (var i = 0; i < 20000; i++) {
      html.write('<p class="absatz">Wort$i <b>fett</b></p>');
    }
    final watch = Stopwatch()..start();
    final text = htmlToIndexableText(html.toString());
    expect(watch.elapsed, lessThan(const Duration(seconds: 5)));
    expect(text, startsWith('Wort0 fett Wort1 fett'));
    expect(text, endsWith('Wort19999 fett'));
  });
}
