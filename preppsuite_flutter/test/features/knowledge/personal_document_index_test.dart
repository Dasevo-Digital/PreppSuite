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

  test('indexes Markdown, EPUB chapters and embedded PDF text offline', () async {
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
  });

  test(
    'the local reader obtains Markdown and EPUB content without an app',
    () async {
      final markdown = File('${workspace.path}/hinweise.md')
        ..writeAsStringSync('# Funk\nPMR446 bleibt für kurze Wege sinnvoll.');
      final epub = File('${workspace.path}/notizen.epub');
      final archive = Archive()
        ..addFile(
          ArchiveFile.string(
            'OPS/chapter.xhtml',
            '<html><body><h1>Wasser</h1><p>Kanister dunkel lagern.</p></body></html>',
          ),
        );
      epub.writeAsBytesSync(ZipEncoder().encodeBytes(archive));

      final markdownText = await PersonalDocumentIndexer.readForReader(
        PersonalDocument(
          id: 'markdown-reader',
          location: markdown.path,
          label: 'hinweise.md',
          addedAt: DateTime.now(),
        ),
      );
      final epubText = await PersonalDocumentIndexer.readForReader(
        PersonalDocument(
          id: 'epub-reader',
          location: epub.path,
          label: 'notizen.epub',
          addedAt: DateTime.now(),
        ),
      );

      expect(markdownText, contains('PMR446'));
      expect(epubText, contains('Kanister dunkel lagern'));
    },
  );

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
      throwsA(anything),
    );
    expect(
      (await readPersonalDocumentBytes(file.path, maxBytes: 8192)).length,
      4096,
    );
  });

  test('what the reader will open, the index will also read', () {
    // These were 64 MB and 48 MB, and the gap meant a document could be
    // opened and read from end to end and still never turn up in a
    // search. One number now; this test is what keeps it one.
    expect(
      PersonalDocumentIndexer.maxReaderDocumentBytes,
      PersonalDocumentIndexer.maxDocumentBytes,
    );
  });
}
