import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:preppsuite_flutter/features/knowledge/application/article_document.dart';

/// Runs the reader over real articles rather than over markup written to
/// suit it.
///
/// Skipped unless `PREPPSUITE_TEST_NETWORK` is set. The HTML comes from
/// Wikipedia's own REST interface, which is the same Parsoid output a
/// Kiwix archive is built from — the structure a ZIM article has, with
/// the sections, the infoboxes, the reference markers and the wrapped
/// source lines that a hand-written fixture never has enough of.
void main() {
  final reason = Platform.environment['PREPPSUITE_TEST_NETWORK'] == null
      ? 'set PREPPSUITE_TEST_NETWORK=1 to read real articles'
      : null;

  const articles = ['Trinkwasser', 'Notvorrat', 'Feuer', 'Deutschland'];

  test(
    'real articles come out as something worth reading',
    () async {
      final client = http.Client();
      addTearDown(client.close);

      for (final name in articles) {
        final response = await client.get(
          Uri.https('de.wikipedia.org', '/api/rest_v1/page/html/$name'),
          headers: const {'User-Agent': 'PreppSuite/1.0 (offline reader)'},
        );
        if (response.statusCode != 200) continue;

        final started = DateTime.now();
        final document = parseArticle(
          response.body,
          baseUrl: Uri.parse('http://127.0.0.1:8080/A/$name'),
        );
        final took = DateTime.now().difference(started);

        final headings = document.blocks.whereType<ArticleHeading>().length;
        final paragraphs = document.blocks.whereType<ArticleParagraph>().length;
        final entries = document.blocks.whereType<ArticleListEntry>().length;
        final images = document.blocks.whereType<ArticleImage>().length;
        final tables = document.blocks.whereType<ArticleTable>().length;

        stdout.writeln(
          '$name: ${response.body.length ~/ 1024} kB in '
          '${took.inMilliseconds} ms -> ${document.blocks.length} Blöcke '
          '($headings Überschriften, $paragraphs Absätze, $entries Listenzeilen, '
          '$images Bilder, $tables Tabellen)',
        );

        // Deliberately modest: "Notvorrat" is a short article with ten
        // paragraphs, and a threshold only a long one clears would be a
        // test of Wikipedia rather than of this code.
        expect(headings, greaterThan(3), reason: '$name has no outline');
        expect(paragraphs, greaterThan(5), reason: '$name has no text');

        // Nothing that is markup may reach the reader as words. This is the
        // check that would catch a tag the parser walked straight past.
        final text = [
          for (final block in document.blocks)
            switch (block) {
              ArticleParagraph(:final text) => text.plain,
              ArticleHeading(:final text) => text.plain,
              ArticleListEntry(:final text) => text.plain,
              ArticleQuote(:final text) => text.plain,
              _ => '',
            },
        ].join('\n');

        expect(text, isNot(contains('<script')));
        expect(text, isNot(contains('</p>')));
        expect(text, isNot(contains('&lt;')));
        // Entities are decoded by the parser, not left as they were typed.
        expect(text, isNot(contains('&nbsp;')));
        expect(text, isNot(contains('&amp;')));

        // Every link has been resolved: nothing relative survives, because
        // a relative link would open nothing. What it resolves *to* is
        // either the loopback server in front of the archive or an ordinary
        // address on the internet — an article legitimately links to both.
        final links = [
          for (final block in document.blocks)
            if (block is ArticleParagraph)
              for (final span in block.text.spans) ?span.link,
        ];
        expect(links, isNotEmpty, reason: '$name has no links');
        for (final link in links) {
          expect(
            Uri.parse(link).hasScheme,
            isTrue,
            reason: 'unresolved link in $name: $link',
          );
        }
        expect(
          links.where((l) => l.startsWith('http://127.0.0.1:8080/')),
          isNotEmpty,
          reason: '$name links nowhere inside the archive',
        );

        // Reading has to be instant: this runs on the interface's own
        // isolate when an article is opened.
        expect(took.inMilliseconds, lessThan(2000), reason: '$name was slow');
      }
    },
    skip: reason,
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
