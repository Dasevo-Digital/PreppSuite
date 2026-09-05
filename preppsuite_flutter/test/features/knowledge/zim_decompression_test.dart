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
