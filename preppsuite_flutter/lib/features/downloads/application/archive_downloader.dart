import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../core/platform_storage.dart';

/// How far a download has got.
class DownloadProgress {
  const DownloadProgress({required this.received, required this.total});

  /// Bytes on disk, including anything a resumed download found there.
  final int received;

  /// The whole file's size, as the server states it — or the catalogue's
  /// estimate until the server has answered. Null is not an error: a
  /// mirror behind a redirect sometimes gives no length at all.
  final int? total;

  double? get fraction {
    final size = total;
    if (size == null || size <= 0) return null;
    return (received / size).clamp(0.0, 1.0);
  }
}

/// A download that stopped without finishing.
class DownloadException implements Exception {
  const DownloadException(this.message);

  final String message;

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
  ArchiveDownloader({http.Client? httpClient, Duration? reportEvery})
    : _httpClient = httpClient ?? http.Client(),
      _reportEvery = reportEvery ?? const Duration(milliseconds: 250);

  final http.Client _httpClient;

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
  Stream<DownloadProgress> download({
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
      throw DownloadException('got $onDisk bytes of an expected $stated');
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
