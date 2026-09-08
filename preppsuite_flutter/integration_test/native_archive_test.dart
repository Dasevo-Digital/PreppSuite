import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:preppsuite_flutter/features/knowledge/application/zim_archive.dart';
import 'package:zstandard/zstandard.dart';
import 'package:preppsuite_flutter/features/knowledge/application/zim_decompression.dart';
import 'package:preppsuite_flutter/features/maps/application/pmtiles_archive.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final realArchive = Platform.environment['PREPPSUITE_TEST_ZIM'];

  testWidgets(
    'a current Kiwix archive opens with the native decoder',
    (tester) async {
      final archive = await ZimArchive.open(
        await FileByteRangeSource.open(File(realArchive!)),
      );
      addTearDown(archive.close);
      expect(await archive.metadata('Title'), isNotEmpty);
    },
    skip: realArchive == null,
  );

  testWidgets('bounded archive decoder accepts native Zstandard frames', (
    tester,
  ) async {
    for (final size in [0, 3, 256, 200000]) {
      final source = Uint8List.fromList(
        List.generate(size, (index) => index % 251),
      );
      final compressed = await Zstandard().compress(source, 3);
      expect(compressed, isNotNull);
      expect(await decompressCluster(ZimCompression.zstd, compressed!), source);
    }
  });
}
