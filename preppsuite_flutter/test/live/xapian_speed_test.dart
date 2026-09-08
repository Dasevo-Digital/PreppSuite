import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/knowledge/application/xapian_index.dart';
import 'package:preppsuite_flutter/features/knowledge/application/xapian_search.dart';
import 'package:preppsuite_flutter/features/knowledge/application/zim_archive.dart';
import 'package:preppsuite_flutter/features/maps/application/pmtiles_archive.dart'
    show FileByteRangeSource;

/// What the archive's own index costs, on the archive it was written for.
///
/// The claim this feature rests on is that a full Wikipedia becomes
/// searchable with no indexing run at all. That is a claim about a
/// fifty-gigabyte file, so it is measured on one rather than argued
/// about. Skipped unless PREPPSUITE_TEST_ZIM points at an archive:
///
///   PREPPSUITE_TEST_ZIM=~/Documents/PreppSuite/wikipedia_de_all_maxi.zim \
///     flutter test test/live/xapian_speed_test.dart
void main() {
  final archivePath = Platform.environment['PREPPSUITE_TEST_ZIM'];
  final reason = archivePath == null
      ? 'set PREPPSUITE_TEST_ZIM to a Kiwix archive to run this'
      : !File(archivePath).existsSync()
      ? 'PREPPSUITE_TEST_ZIM names no file'
      : !xapianAvailable
      ? 'run native/zim_xapian/build_macos.sh first'
      : null;

  test(
    'opening and searching the built-in index',
    () async {
      final size = File(archivePath!).lengthSync();
      final archive = await ZimArchive.open(
        await FileByteRangeSource.open(File(archivePath)),
      );
      addTearDown(archive.close);

      final entry = await archive.fullTextIndexEntry();
      expect(entry, isNotNull, reason: 'this archive carries no index');
      final where = (await archive.directAccessInfo(entry!))!;

      final opening = Stopwatch()..start();
      final searcher = await XapianSearcher.open(archivePath, where);
      opening.stop();
      addTearDown(searcher.close);

      stdout.writeln('Archiv       ${size ~/ (1024 * 1024)} MB');
      stdout.writeln(
        'Index        ${where.length ~/ (1024 * 1024)} MB '
        'ab Byte ${where.offset}',
      );
      stdout.writeln('Dokumente    ${searcher.documentCount}');
      stdout.writeln('Sprache      ${searcher.language}');
      stdout.writeln('Oeffnen      ${opening.elapsedMilliseconds} ms');

      for (final query in const [
        'Trinkwasser',
        'Notvorrat',
        'Notvorräte',
        'Stromausfall',
      ]) {
        final watch = Stopwatch()..start();
        final found = await searcher.search(query, limit: 25);
        watch.stop();

        // Resolving each hit to an entry is what the screen does before it
        // can show a title, so it belongs in the number.
        final resolving = Stopwatch()..start();
        final entries = [
          for (final hit in found.hits)
            ?await archive.findByUrl(hit.namespace, hit.url),
        ];
        resolving.stop();

        stdout.writeln(
          '$query: ${found.estimate} Treffer, '
          '${watch.elapsedMilliseconds} ms Suche + '
          '${resolving.elapsedMilliseconds} ms Auflösen, '
          'erster: ${entries.isEmpty ? "-" : entries.first.title}',
        );
        expect(entries.length, found.hits.length);
      }
    },
    skip: reason,
  );
}
