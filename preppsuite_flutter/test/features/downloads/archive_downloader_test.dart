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

/// Drops the connection part-way through, the way a public mirror does
/// on an eleven-gigabyte file, and behaves once it has done so [drops]
/// times.
class _FlakyServer extends http.BaseClient {
  _FlakyServer(this.body, {required this.drops, this.after = 120});

  final Uint8List body;

  /// How many more transfers to cut short.
  int drops;

  /// How many bytes to deliver before cutting one short.
  final int after;

  final requestedRanges = <String?>[];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final range = request.headers['range'];
    requestedRanges.add(range);

    final start = range == null
        ? 0
        : int.parse(range.split('=')[1].split('-')[0]);
    if (start >= body.length) {
      return http.StreamedResponse(
        const Stream.empty(),
        416,
        headers: {'content-range': 'bytes */${body.length}'},
      );
    }

    final slice = body.sublist(start);
    final Stream<List<int>> stream;
    if (drops > 0) {
      drops--;
      final cut = after < slice.length ? after : slice.length ~/ 2;
      stream = Stream<List<int>>.fromIterable([slice.sublist(0, cut)]);
    } else {
      stream = Stream<List<int>>.value(slice);
    }

    return http.StreamedResponse(
      stream,
      start == 0 ? 200 : 206,
      contentLength: slice.length,
      headers: start == 0
          ? {'content-length': '${body.length}'}
          : {'content-range': 'bytes $start-${body.length - 1}/${body.length}'},
    );
  }
}

/// Answers with a status and nothing else.
class _RefusingServer extends http.BaseClient {
  _RefusingServer(this.status);

  final int status;
  var calls = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    calls++;
    return http.StreamedResponse(const Stream.empty(), status);
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
    // mid-transfer looks from this side. No retries here: what is under
    // test is where the bytes end up when the downloader finally gives
    // up, and this server would truncate every attempt equally.
    final server = _TruncatingServer(body, declared: body.length + 40);
    await expectLater(
      run(
        ArchiveDownloader(
          httpClient: server,
          reportEvery: Duration.zero,
          retryDelays: const [],
        ),
      ),
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

  // An eleven-gigabyte download from a public mirror takes hours, and
  // over that span a dropped connection is an ordinary event. It used to
  // end the download and show the mirror's own words in the banner.
  test('a dropped connection is picked up where it stopped', () async {
    final server = _FlakyServer(body, drops: 2, after: 120);
    final progress = await run(
      ArchiveDownloader(
        httpClient: server,
        reportEvery: Duration.zero,
        retryDelays: const [Duration.zero, Duration.zero, Duration.zero],
      ),
      estimate: body.length,
    );

    expect(await File(target).readAsBytes(), body);
    expect(progress.last.received, body.length);
    // Three transfers, each resuming from where the last one stopped —
    // no byte fetched twice.
    expect(server.requestedRanges, [null, 'bytes=120-', 'bytes=240-']);
  });

  test('a download that keeps moving may drop more often than the budget', (
  ) async {
    // Five drops against a budget of two, but every attempt brings bytes
    // in, so the budget keeps being handed back.
    final server = _FlakyServer(body, drops: 5, after: 80);
    await run(
      ArchiveDownloader(
        httpClient: server,
        reportEvery: Duration.zero,
        retryDelays: const [Duration.zero, Duration.zero],
      ),
      estimate: body.length,
    );

    expect(await File(target).readAsBytes(), body);
    expect(server.requestedRanges.length, 6);
  });

  test('a mirror that gives nothing is let go', () async {
    // Drops before a single byte, every time. Nothing is progressing, so
    // the budget runs out instead of resetting.
    final server = _FlakyServer(body, drops: 99, after: 0);
    await expectLater(
      run(
        ArchiveDownloader(
          httpClient: server,
          reportEvery: Duration.zero,
          retryDelays: const [Duration.zero, Duration.zero],
        ),
      ),
      throwsA(isA<DownloadException>()),
    );

    expect(server.requestedRanges.length, 3, reason: 'one try and two more');
  });

  test('a refusal is not asked again', () async {
    // Six more requests for something the mirror has already answered
    // would be rude and could not help.
    final server = _RefusingServer(404);
    await expectLater(
      run(ArchiveDownloader(httpClient: server, reportEvery: Duration.zero)),
      throwsA(isA<DownloadException>()),
    );

    expect(server.calls, 1);
  });
}
