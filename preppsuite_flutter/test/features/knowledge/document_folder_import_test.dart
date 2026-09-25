import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/knowledge/application/document_folder_import.dart';
import 'package:preppsuite_flutter/features/knowledge/application/personal_document_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Taking in a folder.
///
/// The claim is narrow and the tests keep it narrow: what lies **in** the
/// folder, of the kinds the reader can open, and no more of them than the
/// brake allows.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory folder;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    folder = await Directory.systemTemp.createTemp('preppsuite-docs');
  });

  tearDown(() => folder.delete(recursive: true));

  File write(String name) =>
      File('${folder.path}/$name')..writeAsStringSync('x');

  test('takes the kinds the reader can open and leaves the rest', () async {
    write('handbuch.pdf');
    write('roman.epub');
    write('notizen.md');
    write('liste.markdown');
    write('tabelle.csv');
    write('bild.jpg');

    final contents = await listFolderDocuments(folder.path);

    expect(contents.found, 4);
    expect(contents.documents.map((item) => item.label), [
      'handbuch.pdf',
      'liste.markdown',
      'notizen.md',
      'roman.epub',
    ]);
    expect(contents.isTruncated, isFalse);
  });

  test('does not walk into subfolders', () async {
    write('oben.pdf');
    final below = Directory('${folder.path}/unterordner')..createSync();
    File('${below.path}/unten.pdf').writeAsStringSync('x');

    final contents = await listFolderDocuments(folder.path);

    // A document archive is often deep, and one tap must not become
    // thousands of entries nobody asked for.
    expect(contents.documents.map((item) => item.label), ['oben.pdf']);
  });

  test('leaves dotfiles alone', () async {
    write('.versteckt.pdf');
    write('sichtbar.pdf');

    final contents = await listFolderDocuments(folder.path);

    expect(contents.documents.map((item) => item.label), ['sichtbar.pdf']);
  });

  test('the brake says how much it held back', () async {
    for (var index = 0; index < maxDocumentsPerFolder + 5; index++) {
      write('datei-${index.toString().padLeft(4, '0')}.pdf');
    }

    final contents = await listFolderDocuments(folder.path);

    expect(contents.found, maxDocumentsPerFolder + 5);
    expect(contents.documents, hasLength(maxDocumentsPerFolder));
    expect(contents.isTruncated, isTrue);
    // Sorted before the brake, so the same files are taken every run.
    expect(contents.documents.first.label, 'datei-0000.pdf');
  });

  test('a folder that cannot be read is not an empty folder', () async {
    await expectLater(
      listFolderDocuments('${folder.path}/gibtesnicht'),
      throwsA(isA<DocumentFolderUnreadable>()),
    );
  });

  group('adding them to the library', () {
    test('writes once and reports only what was new', () async {
      const store = PersonalDocumentStore();
      await store.add(location: '/a/handbuch.pdf', label: 'handbuch.pdf');

      final result = await store.addAll([
        (location: '/a/handbuch.pdf', label: 'handbuch.pdf'),
        (location: '/a/roman.epub', label: 'roman.epub'),
        (location: '/a/notizen.md', label: 'notizen.md'),
      ]);

      // The one already there is not added twice and not indexed again.
      expect(result.added.map((item) => item.label), [
        'roman.epub',
        'notizen.md',
      ]);
      expect(result.all, hasLength(3));
      expect(await store.load(), hasLength(3));
    });

    test('a folder of nothing new leaves the library untouched', () async {
      const store = PersonalDocumentStore();
      await store.add(location: '/a/handbuch.pdf', label: 'handbuch.pdf');

      final result = await store.addAll([
        (location: '/a/handbuch.pdf', label: 'handbuch.pdf'),
      ]);

      expect(result.added, isEmpty);
      expect(result.all, hasLength(1));
    });

    test(
      'two files of the same name in different folders both count',
      () async {
        const store = PersonalDocumentStore();

        final result = await store.addAll([
          (location: '/a/handbuch.pdf', label: 'handbuch.pdf'),
          (location: '/b/handbuch.pdf', label: 'handbuch.pdf'),
        ]);

        // The location is what makes a document, not its name.
        expect(result.added, hasLength(2));
      },
    );
  });
}
