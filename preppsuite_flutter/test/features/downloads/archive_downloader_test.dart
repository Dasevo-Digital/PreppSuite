import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:preppsuite_flutter/features/downloads/application/archive_downloader.dart';

/// Serves [body] with byte ranges, the way a real mirror does.
class _RangeServer extends http.BaseClient {
  _RangeServer(this.body, {this.honourRanges = true, this.chunk = 7});

  final Uint8List body;
  final bool honourRanges;
  final int chunk;

  /// Every range header this client was asked for, so a test can assert
  /// that a resume actually resumed instead of quietly starting over.
  final requestedRanges = <String?>[];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final range = request.headers['range'];
    requestedRanges.add(range);

    var start = 0;
    if (range != null && honourRanges) {
      start = int.parse(range.split('=')[1].split('-')[0]);
      if (start >= body.length) {
        return http.StreamedResponse(
          const Stream.empty(),
          416,
          headers: {'content-range': 'bytes */${body.length}'},
        );
      }
    }

    final slice = body.sublist(start);
    final stream = Stream<List<int>>.fromIterable([
      for (var i = 0; i < slice.length; i += chunk)
        slice.sublist(i, i + chunk > slice.length ? slice.length : i + chunk),
    ]);

    if (start == 0) {
      return http.StreamedResponse(
        stream,
        200,
        contentLength: body.length,
        headers: {'content-length': '${body.length}'},
      );
    }
    return http.StreamedResponse(
      stream,
      206,
      contentLength: slice.length,
      headers: {
        'content-range': 'bytes $start-${body.length - 1}/${body.length}',
      },
    );
  }
}

/// Says the file is longer than what it actually sends.
class _TruncatingServer extends http.BaseClient {
  _TruncatingServer(this.body, {required this.declared});

  final Uint8List body;
  final int declared;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return http.StreamedResponse(
      Stream<List<int>>.value(body),
      200,
      contentLength: declared,
      headers: {'content-length': '$declared'},
    );
  }
}

void main() {
  late Directory dir;
  late String target;
  final body = Uint8List.fromList(List.generate(500, (i) => i % 251));

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('preppsuite_download');
    target = '${dir.path}/archive.zim';
  });

  tearDown(() => dir.delete(recursive: true));

  Future<List<DownloadProgress>> run(
    ArchiveDownloader downloader, {
    int? estimate,
  }) => downloader
      .download(
        url: Uri.parse('https://example.invalid/archive.zim'),
        targetPath: target,
        estimatedLength: estimate,
      )
      .toList();

  test('writes the whole file and reports the end', () async {
    final server = _RangeServer(body);
    final progress = await run(
      ArchiveDownloader(httpClient: server, reportEvery: Duration.zero),
      estimate: body.length,
    );

    expect(await File(target).readAsBytes(), body);
    expect(progress.last.received, body.length);
    expect(progress.last.fraction, 1.0);
    expect(server.requestedRanges, [null]);
  });

  test('resumes a partial file instead of starting over', () async {
    await File(
      '$target${ArchiveDownloader.partialSuffix}',
    ).writeAsBytes(body.sublist(0, 200));

    final server = _RangeServer(body);
    await run(
      ArchiveDownloader(httpClient: server, reportEvery: Duration.zero),
      estimate: body.length,
    );

    expect(server.requestedRanges, ['bytes=200-']);
    expect(await File(target).readAsBytes(), body);
  });

  test('starts over when the server ignores the range', () async {
    await File(
      '$target${ArchiveDownloader.partialSuffix}',
    ).writeAsBytes(body.sublist(0, 200));

    final server = _RangeServer(body, honourRanges: false);
    await run(
      ArchiveDownloader(httpClient: server, reportEvery: Duration.zero),
      estimate: body.length,
    );

    // The bytes it already had were not kept in front of a second full
    // copy, which would have produced a 700-byte "archive".
    expect(await File(target).readAsBytes(), body);
  });

  test('a short answer stays a partial file rather than an archive', () async {
    // Declares more than it sends, the way a connection that drops
    // mid-transfer looks from this side.
    final server = _TruncatingServer(body, declared: body.length + 40);
    await expectLater(
      run(ArchiveDownloader(httpClient: server, reportEvery: Duration.zero)),
      throwsA(isA<DownloadException>()),
    );

    expect(await File(target).exists(), isFalse);
    expect(
      await File('$target${ArchiveDownloader.partialSuffix}').length(),
      body.length,
    );
  });

  // The catalogue's figure cannot decide this: Kiwix rounds it up, so a
  // finished file never equals it. Only the length in the server's own
  // "range not satisfiable" answer can.
  test(
    'a finished partial file is taken when the server confirms it',
    () async {
      await File(
        '$target${ArchiveDownloader.partialSuffix}',
      ).writeAsBytes(body);

      final server = _RangeServer(body);
      await run(
        ArchiveDownloader(httpClient: server, reportEvery: Duration.zero),
        estimate: body.length + 700,
      );

      expect(server.requestedRanges, ['bytes=500-']);
      expect(await File(target).readAsBytes(), body);
    },
  );

  // Kiwix's catalogue offered 6,941,696 bytes for a file of 6,940,898.
  // Checking against that figure rejected every download it described.
  test('a rounded-up catalogue size does not fail the download', () async {
    final server = _RangeServer(body);
    await run(
      ArchiveDownloader(httpClient: server, reportEvery: Duration.zero),
      estimate: body.length + 798,
    );

    expect(await File(target).readAsBytes(), body);
  });

  test('cancelling leaves the partial file for the next attempt', () async {
    final server = _RangeServer(body, chunk: 1);
    final downloader = ArchiveDownloader(
      httpClient: server,
      reportEvery: Duration.zero,
    );

    final subscription = downloader
        .download(
          url: Uri.parse('https://example.invalid/archive.zim'),
          targetPath: target,
          estimatedLength: body.length,
        )
        .listen(null);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await subscription.cancel();

    expect(await File(target).exists(), isFalse);
    final partial = File('$target${ArchiveDownloader.partialSuffix}');
    expect(await partial.exists(), isTrue);
    expect(await partial.length(), lessThan(body.length));
  });
}
