import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/knowledge/application/download_suggestions.dart';
import 'package:preppsuite_flutter/features/knowledge/application/personal_document_store.dart';

/// What the Downloads folder offers the library (#33).
void main() {
  late Directory downloads;

  setUp(() async {
    downloads = await Directory.systemTemp.createTemp('downloads');
  });
  tearDown(() => downloads.delete(recursive: true));

  Future<File> file(String name, {required DateTime modified}) async {
    final created = File('${downloads.path}/$name');
    await created.writeAsString('x');
    await created.setLastModified(modified);
    return created;
  }

  PersonalDocument known(String location, String label) => PersonalDocument(
    id: label,
    location: location,
    label: label,
    addedAt: DateTime.utc(2026),
  );

  test('offers readable documents, newest first', () async {
    await file('alt.pdf', modified: DateTime(2026, 1, 1));
    await file('neu.epub', modified: DateTime(2026, 10, 1));
    await file('notizen.md', modified: DateTime(2026, 5, 1));
    await file('foto.jpg', modified: DateTime(2026, 10, 2));
    await file('.versteckt.pdf', modified: DateTime(2026, 10, 3));
    await Directory('${downloads.path}/PreppSuite').create();

    final offered = await downloadSuggestions(
      downloads: downloads,
      known: const [],
      dismissed: const {},
    );

    expect(offered.map((s) => s.name), ['neu.epub', 'notizen.md', 'alt.pdf']);
  });

  test('leaves out what the library has and what was turned down', () async {
    final pdf = await file('broschuere.pdf', modified: DateTime(2026, 9, 1));
    await file('handbuch.pdf', modified: DateTime(2026, 9, 2));
    await file('liste.md', modified: DateTime(2026, 9, 3));

    final offered = await downloadSuggestions(
      downloads: downloads,
      known: [
        known(pdf.path, 'broschuere.pdf'),
        // A bookmark names no file; its label does.
        known('bookmark://ABC', 'Handbuch.pdf'),
      ],
      dismissed: {'${downloads.path}/liste.md'},
    );

    expect(offered, isEmpty);
  });

  test('a missing folder offers nothing', () async {
    expect(
      await downloadSuggestions(
        downloads: Directory('${downloads.path}/gibt-es-nicht'),
        known: const [],
        dismissed: const {},
      ),
      isEmpty,
    );
    expect(
      await downloadSuggestions(
        downloads: null,
        known: const [],
        dismissed: const {},
      ),
      isEmpty,
    );
  });

  test('offers no more than a screenful', () async {
    for (var i = 0; i < maxDownloadSuggestions + 5; i++) {
      await file('dok$i.pdf', modified: DateTime(2026, 1, i + 1));
    }

    final offered = await downloadSuggestions(
      downloads: downloads,
      known: const [],
      dismissed: const {},
    );

    expect(offered, hasLength(maxDownloadSuggestions));
  });
}
