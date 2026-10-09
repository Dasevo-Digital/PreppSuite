import 'package:flutter/foundation.dart';

import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:preppsuite_flutter/features/knowledge/application/personal_document_index.dart';
import 'package:preppsuite_flutter/features/knowledge/application/personal_document_store.dart';

void main() {
  late PersonalDocumentIndex index;
  late Directory workspace;

  setUp(() {
    index = PersonalDocumentIndex.forTesting(NativeDatabase.memory());
    workspace = Directory.systemTemp.createTempSync('preppsuite-document');
  });

  tearDown(() async {
    await index.close();
    await workspace.delete(recursive: true);
  });

  test('finds body text and returns a document excerpt', () async {
    await index.replace(
      id: 'manual',
      label: 'Notfallhandbuch.pdf',
      text: 'Trinkwasser wird kühl und dunkel gelagert.',
    );

    final matches = await index.search('trinkw');

    expect(matches, hasLength(1));
    expect(matches.single.id, 'manual');
    expect(matches.single.label, 'Notfallhandbuch.pdf');
    expect(matches.single.excerpt, contains('Trinkwasser'));
  });

  test(
    'removing an index row leaves the original document untouched',
    () async {
      await index.replace(id: 'manual', label: 'Handbuch.md', text: 'Wasser');

      await index.remove('manual');

      expect(await index.search('Wasser'), isEmpty);
    },
  );

  test(
    'indexes Markdown, EPUB chapters and embedded PDF text offline',
    () async {
      final markdown = File('${workspace.path}/hinweise.md')
        ..writeAsStringSync('Kerzen immer außerhalb der Reichweite lagern.');
      final epub = File('${workspace.path}/notizen.epub');
      final archive = Archive()
        ..addFile(
          ArchiveFile.string(
            'OPS/chapter.xhtml',
            '<html><body><h1>Funk</h1><p>PMR446 ist für kurze Wege gedacht.</p></body></html>',
          ),
        );
      epub.writeAsBytesSync(ZipEncoder().encodeBytes(archive));
      final pdf = File('${workspace.path}/handbuch.pdf');
      final report = pw.Document()
        ..addPage(
          pw.Page(build: (_) => pw.Text('Trinkwasser kühl und dunkel lagern.')),
        );
      await pdf.writeAsBytes(await report.save());

      final indexer = PersonalDocumentIndexer(index: index);
      for (final document in [
        PersonalDocument(
          id: 'markdown',
          location: markdown.path,
          label: 'hinweise.md',
          addedAt: DateTime.now(),
        ),
        PersonalDocument(
          id: 'epub',
          location: epub.path,
          label: 'notizen.epub',
          addedAt: DateTime.now(),
        ),
        PersonalDocument(
          id: 'pdf',
          location: pdf.path,
          label: 'handbuch.pdf',
          addedAt: DateTime.now(),
        ),
      ]) {
        expect(
          (await indexer.index(document)).status,
          PersonalDocumentIndexStatus.ready,
        );
      }

      expect((await index.search('Kerzen')).single.id, 'markdown');
      expect((await index.search('PMR446')).single.id, 'epub');
      expect((await index.search('Trinkwasser')).single.id, 'pdf');
    },
  );

  test(
    'the local reader obtains Markdown and EPUB content without an app',
    () async {
      final markdown = File('${workspace.path}/hinweise.md')
        ..writeAsStringSync(
          '# Funk\n\nPMR446 bleibt für kurze Wege sinnvoll.\n\n'
          'Ein zweiter Absatz,\nüber zwei Zeilen.',
        );
      final epub = File('${workspace.path}/notizen.epub');
      final archive = Archive()
        ..addFile(
          ArchiveFile.string(
            'OPS/chapter.xhtml',
            '<html><body><h1>Wasser</h1><p>Kanister dunkel lagern.</p>'
                '<p>Alle sechs Monate tauschen.</p></body></html>',
          ),
        );
      epub.writeAsBytesSync(ZipEncoder().encodeBytes(archive));

      final markdownText = await PersonalDocumentTextJob.start(
        PersonalDocument(
          id: 'markdown-reader',
          location: markdown.path,
          label: 'hinweise.md',
          addedAt: DateTime.now(),
        ),
      ).result;
      final epubText = await PersonalDocumentTextJob.start(
        PersonalDocument(
          id: 'epub-reader',
          location: epub.path,
          label: 'notizen.epub',
          addedAt: DateTime.now(),
        ),
      ).result;

      // Paragraphs stay paragraphs: the reader lays them out one at a
      // time, which is what keeps a long document from freezing it.
      expect(markdownText.paragraphs, [
        '# Funk',
        'PMR446 bleibt für kurze Wege sinnvoll.',
        'Ein zweiter Absatz, über zwei Zeilen.',
      ]);
      expect(epubText.paragraphs, [
        'Wasser',
        'Kanister dunkel lagern.',
        'Alle sechs Monate tauschen.',
      ]);
      expect(epubText.truncated, isFalse);
    },
  );

  test('the reading says how far it has got', () async {
    final archive = Archive();
    for (var chapter = 0; chapter < 3; chapter++) {
      archive.addFile(
        ArchiveFile.string('OPS/c$chapter.xhtml', '<p>Kapitel $chapter</p>'),
      );
    }
    final epub = File('${workspace.path}/kapitel.epub')
      ..writeAsBytesSync(ZipEncoder().encodeBytes(archive));

    final job = PersonalDocumentTextJob.start(
      PersonalDocument(
        id: 'progress',
        location: epub.path,
        label: 'kapitel.epub',
        addedAt: DateTime.now(),
      ),
    );
    final seen = <PersonalDocumentProgress>[];
    job.progress.listen(seen.add);
    await job.result;
    await Future<void>.delayed(Duration.zero);

    final read = seen.whereType<PersonalDocumentReading>().last;
    expect(read.received, epub.lengthSync());
    expect(read.total, epub.lengthSync());
    final extracted = seen.whereType<PersonalDocumentExtracting>().last;
    expect((extracted.done, extracted.total), (3, 3));
  });

  test('a file too large says how large, and what the limit is', () async {
    final file = File('${workspace.path}/gross.md')
      ..writeAsStringSync('x' * 4096);

    await expectLater(
      PersonalDocumentTextJob.start(
        PersonalDocument(
          id: 'gross',
          location: file.path,
          label: 'gross.md',
          addedAt: DateTime.now(),
        ),
        maxBytes: 1000,
      ).result,
      throwsA(
        isA<PersonalDocumentTooLarge>()
            .having((e) => e.bytes, 'bytes', 4096)
            .having((e) => e.limit, 'limit', 1000),
      ),
    );
  });

  test('cancelling stops the reading', () async {
    final file = File('${workspace.path}/lang.md')
      ..writeAsStringSync('Absatz\n\n' * 200000);

    final job = PersonalDocumentTextJob.start(
      PersonalDocument(
        id: 'lang',
        location: file.path,
        label: 'lang.md',
        addedAt: DateTime.now(),
      ),
    )..cancel();

    await expectLater(job.result, throwsA(isA<PersonalDocumentCancelled>()));
  });

  test('text past the limit is cut, and says so', () {
    final text = extractPersonalDocumentText(
      'md',
      Uint8List.fromList(
        utf8.encode(
          List.filled(
            personalDocumentMaxCharacters ~/ 1000 + 10,
            'y' * 999,
          ).join('\n\n'),
        ),
      ),
    );

    expect(text.truncated, isTrue);
    expect(
      text.paragraphs.fold<int>(0, (sum, p) => sum + p.length),
      lessThanOrEqualTo(personalDocumentMaxCharacters),
    );
  });

  test('refuses EPUBs with an excessive number of entries', () async {
    final archive = Archive();
    for (var number = 0; number < 4097; number++) {
      archive.addFile(
        ArchiveFile.string('OPS/chapter-$number.xhtml', '<p>Kapitel</p>'),
      );
    }
    final epub = File('${workspace.path}/too-many.epub')
      ..writeAsBytesSync(ZipEncoder().encodeBytes(archive));

    final result = await PersonalDocumentIndexer(index: index).index(
      PersonalDocument(
        id: 'many',
        location: epub.path,
        label: 'too-many.epub',
        addedAt: DateTime.now(),
      ),
    );

    expect(result.status, PersonalDocumentIndexStatus.tooLarge);
    expect(await index.search('Kapitel'), isEmpty);
  });

  test('a file over the bound is refused, and one under it is read', () async {
    // The bound is checked against the file length before a byte is read,
    // which is the only reason a limit of a few hundred megabytes is
    // survivable at all: an oversized document costs a stat, not an
    // allocation.
    final file = File('${workspace.path}/gross.md')
      ..writeAsStringSync('x' * 4096);

    expect(
      readPersonalDocumentBytes(file.path, maxBytes: 1024),
      throwsA(isA<PersonalDocumentTooLarge>()),
    );
    expect(
      (await readPersonalDocumentBytes(file.path, maxBytes: 8192)).length,
      4096,
    );
  });

  test('what the reader refuses, the index refuses too', () async {
    // One job reads for both, so one limit applies to both: a document
    // that could be read and never found, or found and never read, was
    // the gap this closes.
    final file = File('${workspace.path}/grenze.md')
      ..writeAsStringSync('Wasser ' * 1000);
    final document = PersonalDocument(
      id: 'grenze',
      location: file.path,
      label: 'grenze.md',
      addedAt: DateTime.now(),
    );

    final result = await PersonalDocumentIndexer(
      index: index,
      maxBytes: 1000,
    ).index(document);

    expect(result.status, PersonalDocumentIndexStatus.tooLarge);
    await expectLater(
      PersonalDocumentTextJob.start(document, maxBytes: 1000).result,
      throwsA(isA<PersonalDocumentTooLarge>()),
    );
  });

  test('a phone or tablet reads less than a computer', () {
    // The file is read whole, so the limit is also the peak allocation.
    expect(personalDocumentByteLimit(TargetPlatform.android), 128000000);
    expect(personalDocumentByteLimit(TargetPlatform.iOS), 128000000);
    for (final platform in [
      TargetPlatform.macOS,
      TargetPlatform.windows,
      TargetPlatform.linux,
    ]) {
      expect(personalDocumentByteLimit(platform), 256000000);
    }
  });
}
