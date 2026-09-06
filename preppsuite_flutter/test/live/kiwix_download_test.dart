import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/downloads/application/archive_downloader.dart';
import 'package:preppsuite_flutter/features/downloads/application/byte_size.dart';
import 'package:preppsuite_flutter/features/knowledge/application/kiwix_catalogue.dart';
import 'package:preppsuite_flutter/features/knowledge/application/zim_archive.dart';
import 'package:preppsuite_flutter/features/maps/application/pmtiles_archive.dart';

/// Reaches the real Kiwix library and downloads the smallest German
/// archive it offers, end to end.
///
/// Skipped unless `PREPPSUITE_TEST_NETWORK` is set, the same way the
/// Xapian test waits for a real archive: it needs a connection and takes
/// as long as the download does.
///
/// Worth running after touching the catalogue client or the downloader.
/// It is what caught Kiwix stating its file sizes rounded up, which no
/// fixture would ever have shown.
void main() {
  final reason = Platform.environment['PREPPSUITE_TEST_NETWORK'] == null
      ? 'set PREPPSUITE_TEST_NETWORK=1 to download from the real library'
      : null;

  test(
    'the catalogue leads to an archive that opens',
    () async {
      final page = await KiwixCatalogue().entries(language: 'deu', count: 60);
      expect(page.total, greaterThan(0));

      final entry =
          (page.entries.where((e) => e.size > 0).toList()
                ..sort((a, b) => a.size.compareTo(b.size)))
              .first;
      stdout.writeln(
        'smallest of ${page.total}: ${entry.name} '
        '(${formatByteSize(entry.size)}) at ${entry.downloadUrl}',
      );

      final directory = await Directory.systemTemp.createTemp('kiwix_live');
      addTearDown(() => directory.delete(recursive: true));
      final target = '${directory.path}/${entry.fileName}';

      await ArchiveDownloader()
          .download(
            url: entry.downloadUrl,
            targetPath: target,
            estimatedLength: entry.size,
          )
          .drain<void>();

      final onDisk = await File(target).length();
      stdout.writeln('on disk: ${formatByteSize(onDisk)} ($onDisk bytes)');

      // The catalogue's figure is rounded up, so the file is allowed to
      // be a little shorter than advertised but never longer.
      expect(onDisk, lessThanOrEqualTo(entry.size));
      expect(onDisk, greaterThan(entry.size - 4096));

      // Opening it proves the bytes are an archive and not an error page.
      // Reading an article would need zstd, whose native library exists
      // only inside a built app — that part is covered on a device.
      final archive = await ZimArchive.open(
        await FileByteRangeSource.open(File(target)),
      );
      addTearDown(archive.close);
      stdout.writeln(
        'entries: ${archive.header.entryCount}, '
        'clusters: ${archive.header.clusterCount}',
      );
      expect(archive.header.entryCount, greaterThan(0));
      expect(archive.header.clusterCount, greaterThan(0));
    },
    timeout: const Timeout(Duration(minutes: 10)),
    skip: reason,
  );
}
