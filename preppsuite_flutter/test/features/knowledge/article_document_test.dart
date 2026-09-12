import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/knowledge/application/article_document.dart';

void main() {
  final base = Uri.parse('http://127.0.0.1:8080/A/Trinkwasser');

  ArticleDocument parse(String body) =>
      parseArticle('<html><body>$body</body></html>', baseUrl: base);

  test('a paragraph becomes a paragraph', () {
    final document = parse('<p>Trinkwasser ist Wasser.</p>');

    expect(document.blocks, hasLength(1));
    expect(
      (document.blocks.single as ArticleParagraph).text.plain,
      'Trinkwasser ist Wasser.',
    );
  });

  test('the indentation of the source does not reach the sentence', () {
    // Markup is wrapped for whoever reads it as a file. A browser
    // collapses that; so must this, or every article is full of line
    // breaks in the middle of sentences.
    final document = parse('<p>Trinkwasser\n     ist\n     Wasser.</p>');

    expect(
      (document.blocks.single as ArticleParagraph).text.plain,
      'Trinkwasser ist Wasser.',
    );
  });

  test('the space between two runs is kept, the one at the edge is not', () {
    final document = parse('<p>  das <b>beste</b> Wasser  </p>');
    final text = (document.blocks.single as ArticleParagraph).text;

    expect(text.plain, 'das beste Wasser');
    expect(text.spans.firstWhere((s) => s.bold).text, 'beste');
  });

  test('headings keep their level', () {
    final document = parse('<h2>Gewinnung</h2><h3>Aus Grundwasser</h3>');

    expect((document.blocks[0] as ArticleHeading).level, 2);
    expect((document.blocks[0] as ArticleHeading).text.plain, 'Gewinnung');
    expect((document.blocks[1] as ArticleHeading).level, 3);
  });

  test('a link is resolved against the article it stands in', () {
    final document = parse(
      '<p>siehe <a href="Grundwasser">Grundwasser</a></p>',
    );
    final span = (document.blocks.single as ArticleParagraph).text.spans
        .firstWhere((s) => s.link != null);

    expect(span.text, 'Grundwasser');
    expect(span.link, 'http://127.0.0.1:8080/A/Grundwasser');
  });

  test('a list is numbered or bulleted while parsing, not while drawing', () {
    final document = parse(
      '<ol><li>eins</li><li>zwei</li></ol><ul><li>drei</li></ul>',
    );
    final entries = document.blocks.cast<ArticleListEntry>();

    expect(entries.map((e) => e.marker), ['1.', '2.', '•']);
    expect(entries.map((e) => e.text.plain), ['eins', 'zwei', 'drei']);
  });

  test('a list inside a list keeps its depth', () {
    final document = parse(
      '<ul><li>oben<ul><li>unten</li></ul></li></ul>',
    );
    final entries = document.blocks.cast<ArticleListEntry>();

    // The outer item comes first and keeps its bullet: the text before a
    // nested list used to fall out as an ordinary paragraph, which loses
    // the outline of the article.
    expect(entries.map((e) => e.text.plain), ['oben', 'unten']);
    expect(entries[0].depth, 0);
    expect(entries[1].depth, 1);
  });

  test('an image is resolved the same way a link is', () {
    final document = parse('<img src="../I/quelle.png" alt="Eine Quelle">');
    final image = document.blocks.single as ArticleImage;

    expect(image.source, 'http://127.0.0.1:8080/I/quelle.png');
    expect(image.alt, 'Eine Quelle');
  });

  test('a figure carries its caption', () {
    final document = parse(
      '<figure><img src="../I/quelle.png"><figcaption>Eine Quelle im Harz</figcaption></figure>',
    );
    final image = document.blocks.single as ArticleImage;

    expect(image.caption, 'Eine Quelle im Harz');
  });

  test('a caption without a picture is kept as text', () {
    // Which is what a no-picture archive is full of: the sentence
    // explaining what is not there is worth more than nothing.
    final document = parse(
      '<figure><figcaption>Eine Quelle im Harz</figcaption></figure>',
    );

    expect(
      (document.blocks.single as ArticleParagraph).text.plain,
      'Eine Quelle im Harz',
    );
  });

  test('a table comes through as rows, with its heading row counted', () {
    final document = parse('''
      <table>
        <tr><th>Stoff</th><th>Grenzwert</th></tr>
        <tr><td>Blei</td><td>0,010 mg/l</td></tr>
      </table>
    ''');
    final table = document.blocks.single as ArticleTable;

    expect(table.headerRows, 1);
    expect(table.rows, hasLength(2));
    expect(table.rows[1].map((c) => c.plain), ['Blei', '0,010 mg/l']);
  });

  test('formatting survives being nested', () {
    final document = parse('<p><b>sehr <i>gutes</i></b> Wasser</p>');
    final spans = (document.blocks.single as ArticleParagraph).text.spans;

    final both = spans.firstWhere((s) => s.text.contains('gutes'));
    expect(both.bold, isTrue);
    expect(both.italic, isTrue);
  });

  test(
    'a reference marker stays a superscript rather than a number in the text',
    () {
      final document = parse('<p>Wasser<sup>[1]</sup> ist nass.</p>');
      final spans = (document.blocks.single as ArticleParagraph).text.spans;

      expect(spans.firstWhere((s) => s.superscript).text, '[1]');
      expect(spans.where((s) => s.superscript), hasLength(1));
    },
  );

  test('scripts and styles are not the article', () {
    final document = parse(
      '<style>p{color:red}</style><p>Text</p><script>alert(1)</script>',
    );

    expect(document.blocks, hasLength(1));
    expect((document.blocks.single as ArticleParagraph).text.plain, 'Text');
  });

  test("MediaWiki's own furniture is left out", () {
    // The edit pencil beside every heading, the navigation boxes at the
    // foot. None of it means anything without the site around it.
    final document = parse(
      '<h2>Gewinnung<span class="mw-editsection">[bearbeiten]</span></h2>'
      '<div class="navbox">Wasser-Themen</div>'
      '<p>Text</p>',
    );

    expect((document.blocks[0] as ArticleHeading).text.plain, 'Gewinnung');
    expect(document.blocks, hasLength(2));
  });

  test('a table without any rows is not an empty table', () {
    expect(parse('<table></table>').blocks, isEmpty);
  });

  test('an empty article is empty rather than a crash', () {
    expect(parse('').isEmpty, isTrue);
    expect(parseArticle('').isEmpty, isTrue);
    expect(parseArticle('not html at all').blocks, hasLength(1));
  });

  test('unclosed tags do not derail it', () {
    // Real markup is full of them, which is the whole reason the parsing
    // is the Dart team's and not ours.
    // The parser closes the first paragraph and puts the rest in the
    // second, which is what a browser does with it too.
    final document = parse('<p>eins<p>zwei<b>drei');

    expect(
      document.blocks.map((b) => (b as ArticleParagraph).text.plain),
      ['eins', 'zweidrei'],
    );
  });

  test('the title is taken from the head where there is one', () {
    final document = parseArticle(
      '<html><head><title>Trinkwasser</title></head><body><p>x</p></body></html>',
    );

    expect(document.title, 'Trinkwasser');
  });

  test('without a base address a link is left as it was written', () {
    final document = parseArticle(
      '<html><body><a href="Grundwasser">G</a></body></html>',
    );
    final span = (document.blocks.single as ArticleParagraph).text.spans.single;

    expect(span.link, 'Grundwasser');
  });

  test('a horizontal rule is a block of its own', () {
    expect(parse('<p>a</p><hr><p>b</p>').blocks[1], isA<ArticleRule>());
  });

  test('preformatted text keeps its shape', () {
    final document = parse('<pre>eins\n  zwei</pre>');

    expect((document.blocks.single as ArticleCode).text, 'eins\n  zwei');
  });
}
