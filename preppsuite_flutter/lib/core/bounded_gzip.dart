import 'dart:io' show gzip;
import 'dart:typed_data';

/// Thrown when a gzip stream would unpack past the limit it was given.
class DecompressionLimitException implements Exception {
  const DecompressionLimitException(this.limit);

  final int limit;

  @override
  String toString() =>
      'DecompressionLimitException: output exceeds $limit bytes';
}

/// Gunzips [bytes], stopping at [limit] bytes of output rather than at the
/// end of memory.
///
/// `gzip.decode` and the archive package's `GZipDecoder` have no limit of
/// their own, and a gzip stream expands by up to a factor of a thousand:
/// a few kilobytes from a map file, a QR code or a server can ask for
/// gigabytes. Bounding the input is not enough for that reason — every
/// decompression of bytes this app did not write goes through here.
///
/// Throws [DecompressionLimitException] past the limit and
/// [FormatException] for a stream that is not gzip.
Uint8List gunzipBounded(List<int> bytes, {required int limit}) {
  final output = _BoundedSink(limit);
  final input = gzip.decoder.startChunkedConversion(output);
  const chunk = 16384;
  try {
    for (var offset = 0; offset < bytes.length; offset += chunk) {
      final end = (offset + chunk).clamp(0, bytes.length);
      input.add(bytes.sublist(offset, end));
    }
    input.close();
  } catch (_) {
    // Closing a failed converter may throw again; keep the first cause.
    try {
      input.close();
    } catch (_) {}
    rethrow;
  }
  return output.bytes.takeBytes();
}

class _BoundedSink implements Sink<List<int>> {
  _BoundedSink(this.limit);

  final int limit;
  final bytes = BytesBuilder(copy: false);

  @override
  void add(List<int> data) {
    if (bytes.length + data.length > limit) {
      throw DecompressionLimitException(limit);
    }
    bytes.add(data);
  }

  @override
  void close() {}
}
