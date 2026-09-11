import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../core/platform_storage.dart';

/// How far a download has got.
class DownloadProgress {
  const DownloadProgress({
    required this.received,
    required this.total,
    this.resuming = false,
  });

  /// Bytes on disk, including anything a resumed download found there.
  final int received;

  /// The whole file's size, as the server states it — or the catalogue's
  /// estimate until the server has answered. Null is not an error: a
  /// mirror behind a redirect sometimes gives no length at all.
  final int? total;

  /// Whether the transfer has stopped and is waiting to be picked up
  /// again.
  ///
  /// Said out loud because the wait is up to a minute, and a progress bar
  /// that simply stops moving for a minute reads as a hung app rather
  /// than as a mirror having a bad moment.
  final bool resuming;

  double? get fraction {
    final size = total;
    if (size == null || size <= 0) return null;
    return (received / size).clamp(0.0, 1.0);
  }
}

/// A download that stopped without finishing.
class DownloadException implements Exception {
  const DownloadException(this.message, {this.retryable = false});

  final String message;

  /// Whether trying again from where it stopped could work.
  ///
  /// A dropped connection can; "the server answered 404" cannot, and
  /// retrying it would only hammer a mirror that has already given its
  /// answer.
  final bool retryable;

  @override
  String toString() => 'DownloadException: $message';
}

/// Streams a large archive to a file, resuming where a previous attempt
/// stopped.
///
/// Written for files that are measured in gigabytes and take hours: the
/// bytes go straight to disk and are never held in memory, and a partial
/// download survives the app being closed — on a phone that is not an edge
/// case but the normal course of events.
class ArchiveDownloader {
  ArchiveDownloader({
    http.Client? httpClient,
    Duration? reportEvery,
    List<Duration>? retryDelays,
  }) : _httpClient = httpClient ?? http.Client(),
       _reportEvery = reportEvery ?? const Duration(milliseconds: 250),
       _retryDelays = retryDelays ?? defaultRetryDelays;

  final http.Client _httpClient;

  /// How long to wait before each retry, and — by its length — how many
  /// times in a row to bother.
  ///
  /// Rising, because a mirror that just dropped the connection is often
  /// busy rather than broken, and asking again immediately is what made
  /// it drop. Six is enough to ride out a lost minute without turning a
  /// mirror that is genuinely gone into a quarter of an hour of waiting.
  final List<Duration> _retryDelays;

  static const defaultRetryDelays = [
    Duration(seconds: 1),
    Duration(seconds: 3),
    Duration(seconds: 8),
    Duration(seconds: 20),
    Duration(seconds: 45),
    Duration(seconds: 60),
  ];

  /// Progress is reported on a timer rather than per chunk: a fast
  /// connection delivers thousands of chunks a second, and rebuilding the
  /// UI for each one costs more than the download does.
  final Duration _reportEvery;

  /// The half-finished file sits beside the target under this suffix, so
  /// nothing ever points a reader at an archive that is still growing.
  static const partialSuffix = '.part';

  /// Fetches [url] into [targetPath], appending to an existing partial
  /// file if there is one.
  ///
  /// [estimatedLength] is only ever shown, never checked. Kiwix's
  /// catalogue rounds its figures up — it offered 6,941,696 bytes for a
  /// file of 6,940,898 — so treating it as the size would reject every
  /// download it describes. What the file has to match is the length the
  /// server itself states.
  ///
  /// The stream ends when the file is complete and in place. Cancelling
  /// the subscription stops the transfer and leaves the partial file for
  /// a later attempt.
  ///
  /// A connection that drops part-way is resumed here rather than
  /// reported. These files take hours — 11 GB from a public mirror is a
  /// normal ask — and over that span a mirror closing the socket is an
  /// ordinary event, not a failure of the download. What used to happen
  /// was that the banner showed the mirror's own words ("Connection
  /// closed while receiving data") and the user had to press download
  /// again, which resumed from the partial file and then usually stopped
  /// somewhere else.
  ///
  /// Every attempt after the first picks up from what is on disk, so no
  /// byte is fetched twice. The budget resets whenever an attempt brings
  /// new bytes in: a download that is making progress may drop as often
  /// as the mirror likes, while one that cannot get a single byte gives
  /// up after [_retryDelays] tries.
  Stream<DownloadProgress> download({
    required Uri url,
    required String targetPath,
    int? estimatedLength,
  }) async* {
    final partial = File('$targetPath$partialSuffix');
    var failures = 0;
    DownloadProgress? last;

    while (true) {
      var before = await partial.exists() ? await partial.length() : 0;

      try {
        // `await for` rather than `yield*`: an error out of a yielded
        // stream goes straight to whoever is listening and never touches
        // the try around it, so with `yield*` the retry below would never
        // run once.
        await for (final progress in _fetch(
          url: url,
          targetPath: targetPath,
          estimatedLength: estimatedLength,
        )) {
          last = progress;
          yield progress;
        }
        return;
      } on Object catch (error) {
        if (!_worthRetrying(error)) rethrow;

        final after = await partial.exists() ? await partial.length() : 0;
        // Bytes arrived, so the mirror is working and this was a hiccup.
        if (after > before) failures = 0;
        before = after;

        if (failures >= _retryDelays.length) rethrow;

        yield DownloadProgress(
          received: after,
          total: last?.total,
          resuming: true,
        );
        await Future<void>.delayed(_retryDelays[failures]);
        failures++;
      }
    }
  }

  /// Whether [error] is the kind a second attempt can get past.
  ///
  /// Everything the network does to a long transfer is; everything a
  /// server says on purpose is not. Asking a mirror six more times for
  /// something it has already answered 404 to is rude and pointless.
  static bool _worthRetrying(Object error) {
    if (error is DownloadException) return error.retryable;
    return error is http.ClientException ||
        error is SocketException ||
        error is HandshakeException ||
        error is TimeoutException;
  }

  /// One attempt, from wherever the partial file currently ends.
  Stream<DownloadProgress> _fetch({
    required Uri url,
    required String targetPath,
    int? estimatedLength,
  }) async* {
    final target = File(targetPath);
    final partial = File('$targetPath$partialSuffix');

    await target.parent.create(recursive: true);

    var received = await partial.exists() ? await partial.length() : 0;
    // Marked before a byte is written, so an interrupted download is not
    // backed up either — those are the large ones that sit around longest.
    await excludeFromBackup(partial.path);

    final request = http.Request('GET', url);
    if (received > 0) request.headers['range'] = 'bytes=$received-';

    final response = await _httpClient.send(request);

    var append = true;

    /// What the server says the whole file is. Null means it did not say.
    int? stated;

    switch (response.statusCode) {
      case 206:
        stated = _totalFromContentRange(response.headers['content-range']);
      case 200:
        // The server ignored the range and is sending the whole file
        // again. Starting over is the only correct reading of that.
        append = false;
        received = 0;
        stated = response.contentLength;
      case 416:
        // "Range not satisfiable": the partial file is at least as long
        // as the whole one. Servers state the real length here as
        // `bytes */N`, which is the only way to tell a finished download
        // from a corrupted one.
        final whole = _totalFromContentRange(response.headers['content-range']);
        if (whole != null && await partial.length() == whole) {
          await partial.rename(targetPath);
          yield DownloadProgress(received: whole, total: whole);
          return;
        }
        await partial.delete();
        throw const DownloadException('the partial file does not match');
      default:
        throw DownloadException('the server answered ${response.statusCode}');
    }

    final total = stated ?? estimatedLength;

    final sink = partial.openWrite(
      mode: append ? FileMode.append : FileMode.write,
    );

    var reported = DateTime.now();
    try {
      yield DownloadProgress(received: received, total: total);

      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;

        final now = DateTime.now();
        if (now.difference(reported) >= _reportEvery) {
          reported = now;
          // Flushing on the same beat as reporting keeps a fast link from
          // filling memory while a slow disk catches up.
          await sink.flush();
          yield DownloadProgress(received: received, total: total);
        }
      }
      await sink.flush();
    } finally {
      await sink.close();
    }

    final onDisk = await partial.length();
    if (stated != null && onDisk != stated) {
      // Handing over a truncated archive would look like a corrupt file
      // rather than an interrupted download, so it stays a partial file
      // and the next attempt resumes it.
      throw DownloadException(
        'got $onDisk bytes of an expected $stated',
        // The usual cause is the connection being dropped mid-transfer,
        // which on an 11 GB file over a public mirror is an ordinary
        // event rather than a failure of the download.
        retryable: true,
      );
    }

    await partial.rename(targetPath);
    // Again under the final name. The flag is an extended attribute and
    // survives a rename on the same volume, but this is the state that
    // has to be right, and it costs one call.
    await excludeFromBackup(targetPath);
    yield DownloadProgress(received: onDisk, total: onDisk);
  }

  /// `bytes 200-1023/1024` — the part after the slash.
  static int? _totalFromContentRange(String? header) {
    if (header == null) return null;
    final slash = header.lastIndexOf('/');
    if (slash < 0) return null;
    return int.tryParse(header.substring(slash + 1).trim());
  }
}
