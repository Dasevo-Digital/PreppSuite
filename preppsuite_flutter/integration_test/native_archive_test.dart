import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:zstandard/zstandard.dart';
import 'package:preppsuite_flutter/features/knowledge/application/zim_decompression.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
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
