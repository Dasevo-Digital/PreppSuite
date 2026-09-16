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
}
