import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/knowledge/application/zim_archive.dart';
import 'package:preppsuite_flutter/features/knowledge/application/zim_decompression.dart';
import 'package:preppsuite_flutter/features/maps/application/pmtiles_archive.dart'
    show FileByteRangeSource;

import 'zim_fixture.dart';

void main() {
  test('zlib expansion is bounded before retaining excessive output', () async {
    final compressed = Uint8List.fromList(
      zlib.encode(Uint8List(65 * 1024 * 1024)),
    );
    await expectLater(
      decompressCluster(ZimCompression.zlib, compressed),
      throwsA(isA<ZimException>()),
    );
  });

  test('Zstandard preflight accepts a small raw frame', () {
    // Single segment, three bytes, one final raw block.
    validateZstdMemoryBudget(
      Uint8List.fromList([
        0x28,
        0xb5,
        0x2f,
        0xfd,
        0x20,
        3,
        25,
        0,
        0,
        65,
        66,
        67,
      ]),
    );
  });

  test(
    'Zstandard preflight rejects large windows and declared sizes before native allocation',
    () {
      for (final header in [
        [0, 136], // 128 MiB window, unknown content size.
        [0xa0, 1, 0, 0, 4], // Single segment, 64 MiB + 1.
        [0xe0, 0, 0, 0, 0, 1, 0, 0, 0], // 64-bit size > 4 GiB.
        [0x20, 3, 25, 0, 0, 65], // Truncated raw block.
      ]) {
        expect(
          () => validateZstdMemoryBudget(
            Uint8List.fromList([0x28, 0xb5, 0x2f, 0xfd, ...header]),
          ),
          throwsA(isA<ZimException>()),
        );
      }
    },
  );

  group('cluster compression', () {
    test('an uncompressed cluster is handed through unchanged', () async {
      final body = Uint8List.fromList([1, 2, 3]);

      expect(await decompressCluster(ZimCompression.none, body), body);
    });

    test(
      'a compression the format allows but nobody writes is refused',
      () async {
        // bzip2 was dropped from the format years ago. Saying so beats
        // handing the reader bytes it will misread.
        await expectLater(
          decompressCluster(ZimCompression.bzip2, Uint8List(4)),
          throwsA(isA<ZimException>()),
        );
      },
    );
  });

  group('the reader and the codec', () {
    late Directory workspace;

    setUp(() {
      workspace = Directory.systemTemp.createTempSync('preppsuite-zim-codec');
    });

    tearDown(() => workspace.deleteSync(recursive: true));

    for (final size in [0, 33 * 1024 * 1024, 65 * 1024 * 1024]) {
      test(
        'cluster cache respects byte budget and explicit clearing ($size)',
        () async {
          final path = writeZim(
            workspace,
            ZimFixture(
              compression: ZimCompression.zstd,
              entries: [
                const ZimFixtureEntry(namespace: 'C', url: 'a', content: [65]),
              ],
            ),
          );
          var decodes = 0;
          final archive = await ZimArchive.open(
            await FileByteRangeSource.open(File(path)),
            decompress: (_, body) async {
              decodes++;
              return size == 0 ? body : (Uint8List(size)..setAll(0, body));
            },
          );
          addTearDown(archive.close);
          final entry = (await archive.findByUrl('C', 'a'))!;
          if (size > 64 * 1024 * 1024) {
            await expectLater(
              archive.readBlob(entry),
              throwsA(isA<ZimException>()),
            );
          } else {
            expect(await archive.readBlob(entry), [65]);
            expect(await archive.readBlob(entry), [65]);
            expect(decodes, size == 0 ? 1 : 2);
            archive.clearClusterCache();
            await archive.readBlob(entry);
            expect(decodes, size == 0 ? 2 : 3);
          }
        },
      );
    }

    test('the cluster type byte decides which codec is asked', () async {
      // zstd is what Kiwix has written since 2020, and it is a platform
      // plugin no unit test can reach. What can be checked here is that
      // the reader reads the type, hands over the body without its first
      // byte, and uses whatever comes back.
      final path = writeZim(
        workspace,
        ZimFixture(
          compression: ZimCompression.zstd,
          entries: [
            ZimFixtureEntry(
              namespace: 'C',
              url: 'Trinkwasser',
              title: 'Trinkwasser',
              content: utf8.encode('<h1>Trinkwasser</h1>'),
            ),
          ],
        ),
      );

      var askedFor = -1;
      final archive = await ZimArchive.open(
        await FileByteRangeSource.open(File(path)),
        decompress: (type, body) async {
          askedFor = type;
          // The fixture stores the bytes as they are; a real zstd frame
          // would come back as this same content.
          return body;
        },
      );
      addTearDown(archive.close);

      final entry = await archive.findByUrl('C', 'Trinkwasser');
      expect(
        utf8.decode(await archive.readBlob(entry!)),
        '<h1>Trinkwasser</h1>',
      );
      expect(askedFor, ZimCompression.zstd);
    });
  });
}
