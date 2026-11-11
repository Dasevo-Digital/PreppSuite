import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:preppsuite_flutter/features/downloads/application/archive_downloader.dart';

/// One version of the file behind the address, as one mirror serves it.
class _Version {
  const _Version(this.bytes, {this.lastModified, this.etag});

  final List<int> bytes;
  final String? lastModified;
  final String? etag;

  Map<String, String> get headers => {
    'last-modified': ?lastModified,
    'etag': ?etag,
  };
}

/// Serves [versions] in turn, one per request: the first request is cut
/// off halfway, as a dropped connection would. [startAt] lets a server
/// send a range other than the one asked for.
class _Server extends http.BaseClient {
  _Server(this.versions, {this.startAt});

  final List<_Version> versions;
  final int? startAt;
  final ranges = <String?>[];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final version = versions[ranges.length.clamp(0, versions.length - 1)];
    final file = version.bytes;
    final range = request.headers['range'];
    final first = ranges.isEmpty;
    ranges.add(range);
    if (range == null) {
      return http.StreamedResponse(
        Stream.value(first ? file.sublist(0, file.length ~/ 2) : file),
        200,
        contentLength: file.length,
        headers: version.headers,
      );
    }
    final asked = int.parse(range.substring(6, range.length - 1));
    final start = startAt ?? asked;
    return http.StreamedResponse(
      Stream.value(file.sublist(start)),
      206,
      headers: {
        ...version.headers,
        'content-range': 'bytes $start-${file.length - 1}/${file.length}',
      },
    );
  }
}

/// A download picked up again must go on with the same file (#372). It
/// used to append whatever the address now served: the end of a replaced
/// file onto the start of the old one, counted as finished.
void main() {
  late Directory dir;
  late String target;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('resume-identity');
    target = '${dir.path}/archive.zim';
  });
  tearDown(() => dir.delete(recursive: true));

  final old = List<int>.filled(1000, 0x41);
  final replaced = List<int>.filled(1200, 0x42);

  Future<List<int>> fetch(_Server server) async {
    await ArchiveDownloader(
          httpClient: server,
          reportEvery: Duration.zero,
          retryDelays: const [Duration.zero, Duration.zero, Duration.zero],
        )
        .download(
          url: Uri.parse('https://example.invalid/a.zim'),
          targetPath: target,
        )
        .drain<void>();
    return File(target).readAsBytes();
  }

  test('a file replaced since the download began starts over', () async {
    final server = _Server([
      _Version(old, lastModified: 'Mon, 02 Nov 2026 10:00:00 GMT'),
      _Version(replaced, lastModified: 'Tue, 10 Nov 2026 10:00:00 GMT'),
    ]);

    final bytes = await fetch(server);

    expect(bytes, replaced, reason: 'the new file whole, nothing of the old');
    expect(server.ranges, [null, 'bytes=500-', null]);
    expect(
      File('$target${ArchiveDownloader.identitySuffix}').existsSync(),
      isFalse,
    );
  });

  test('the same file from another mirror goes on where it stopped', () async {
    // Same date, another ETag: what two Kiwix mirrors say of one file.
    final server = _Server([
      _Version(
        old,
        lastModified: 'Mon, 02 Nov 2026 10:00:00 GMT',
        etag: '"a-1"',
      ),
      _Version(
        old,
        lastModified: 'Mon, 02 Nov 2026 10:00:00 GMT',
        etag: '"b-2"',
      ),
    ]);

    final bytes = await fetch(server);

    expect(bytes, old);
    expect(server.ranges, [null, 'bytes=500-']);
  });

  test('a strong ETag counts where there is no date', () async {
    final server = _Server([
      _Version(old, etag: '"v1"'),
      _Version(replaced, etag: '"v2"'),
    ]);

    expect(await fetch(server), replaced);
  });

  test('a range from somewhere else starts over', () async {
    final server = _Server([
      _Version(old, lastModified: 'Mon, 02 Nov 2026 10:00:00 GMT'),
    ], startAt: 0);

    final bytes = await fetch(server);

    expect(bytes, old);
    expect(server.ranges.first, isNull);
    expect(server.ranges, contains(null), reason: 'begun again from zero');
  });
}
