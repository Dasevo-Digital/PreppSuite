import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:preppsuite_flutter/features/knowledge/application/zim_archive.dart';
import 'package:preppsuite_flutter/features/knowledge/application/zim_http_server.dart';
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

      // Opening it was never the hard part. The article view asks the
      // archive's own loopback server for a page and every one of its
      // stylesheets and images, and each of those is a cluster that has
      // to come back out. iFixit answered 500 for almost all of them.
      final server = await ZimHttpServer.start(archive);
      addTearDown(server.close);
      final client = HttpClient();
      addTearDown(client.close);

      Future<int> status(String path) async {
        final response =
            await (await client.getUrl(
              Uri.parse('http://127.0.0.1:${server.port}$path'),
            )).close();
        await response.drain<void>();
        return response.statusCode;
      }

      final main = await archive.mainPage();
      expect(main, isNotNull);
      final base = Uri.parse(
        'http://127.0.0.1:${server.port}/${main!.namespace}/${main.url}',
      );
      expect(await status(base.path), 200, reason: 'the start page');

      // Everything the start page pulls in, resolved the way the engine
      // resolves it -- '..' and all.
      final html = String.fromCharCodes(await archive.readBlob(main));
      final targets = <String>{};
      for (final match
          in RegExp('(?:href|src)="([^"]+)"').allMatches(html)) {
        final raw = match.group(1)!;
        if (raw.startsWith('#') ||
            raw.startsWith('data:') ||
            raw.contains('://')) {
          continue;
        }
        targets.add(
          base.resolve(raw).replace(fragment: '', query: '').path,
        );
      }
      // A count, not just "not empty": a start page whose links stopped
      // being found would make this pass without asking for anything.
      expect(
        targets.length,
        greaterThan(10),
        reason: 'the start page links somewhere',
      );

      final refused = <String>[];
      for (final target in targets) {
        if (await status(target) == 500) refused.add(target);
      }
      expect(
        refused,
        isEmpty,
        reason: 'the archive could not decompress these',
      );
    },
    timeout: const Timeout(Duration(minutes: 10)),
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

  testWidgets('a frame that does not declare its size still decompresses', (
    tester,
  ) async {
    // What every ZIM cluster looks like. Kiwix writes them with streaming
    // compression, which leaves the final size out of the frame header,
    // and the plugin's own `decompress` then allocates twenty times the
    // compressed length and fails when that is not enough. This fixture
    // expands 6835 times; iFixit's worst cluster expands 114 times, and
    // 688 of its 718 clusters expand past twenty.
    // Inline, because an integration test runs from the app's own working
    // directory and not the project's. 206 bytes.
    final frame = base64Decode(
        'KLUv/QRojAIAAsUQE5DPAVA/JyneJGuyK4wEQHU3CAGlshajQDHC+52X784d'
        'SS/H95nlfpTf1Vv85XiaeE4WFzIFjgLejCpApDwNcWU9AgIALf3fQi6Dd5IB'
        'VAAAAAEA/f/b/7kGAkQAAAABAP3/OQACRAAAAAEA/f85AAJEAAAAAQD9/zkA'
        'AkQAAAABAP3/OQACRAAAAAEA/f85AAJEAAAAAQD9/zkAAkQAAAABAP3/OQAC'
        'RAAAAAEA/f85AAJFAAAAAQD9ezkAAqvm6YE=',
    );

    final expected = Uint8List.fromList(
      utf8.encode(
        '<div class="guide"><p>Schritt fuer Schritt zerlegen und wieder '
                'zusammensetzen.</p></div>' *
            40,
      ),
    );

    final decoded = await decompressCluster(ZimCompression.zstd, frame);
    expect(decoded.length, 1408000);
    expect(
      Uint8List.sublistView(decoded, 0, expected.length),
      expected,
      reason: 'the bytes have to be the ones that went in',
    );

    // And the reason this does not go through the plugin: it cannot.
    expect(
      await Zstandard().decompress(frame),
      isNull,
      reason: "the plugin's twenty-times guess is what this works around",
    );
  });
}
