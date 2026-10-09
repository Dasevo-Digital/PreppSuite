import 'dart:io' show zlib;
import 'dart:typed_data';

import 'package:archive/archive.dart'
    show XZDecoder, InputMemoryStream, OutputMemoryStream;

import 'archive_memory_limits.dart';

import 'zim_archive.dart' show ZimException;
import 'zstd_stream.dart';

/// Turns a cluster's stored bytes into its contents.
///
/// Injectable so the reader can be tested without a Flutter plugin
/// binding: zstd is a platform plugin, and a unit test has no engine to
/// answer it.
typedef ClusterDecompressor = Future<Uint8List> Function(
  int compressionType,
  Uint8List body,
);

/// Compression types a cluster's first byte can name.
///
/// zlib and bzip2 were dropped from the format years before this was
/// written and no current archive uses them; xz is what Kiwix wrote until
/// 2020 and zstd is what it writes now.
class ZimCompression {
  ZimCompression._();

  static const none = 1;
  static const zlib = 2;
  static const bzip2 = 3;
  static const xz = 4;
  static const zstd = 5;
}

Future<Uint8List> decompressCluster(int type, Uint8List body) async {
  if (body.length > maxClusterBytes) {
    throw const ZimException(
      'compressed cluster exceeds the 64 MiB memory limit',
    );
  }
  switch (type) {
    case ZimCompression.none:
      return body;

    case ZimCompression.zstd:
      // Streamed rather than handed to the plugin's own `decompress`,
      // which needs to know the final size in advance and guesses twenty
      // times the compressed length when the frame does not say. No ZIM
      // frame says. See zstd_stream.dart for what that cost.
      validateZstdMemoryBudget(body);
      return zstdDecompress(body, limit: maxClusterBytes);

    case ZimCompression.xz:
      final output = _BoundedOutput();
      if (!XZDecoder().decodeStream(
        InputMemoryStream(body),
        output,
        verify: true,
      )) {
        throw const ZimException('invalid XZ cluster');
      }
      return output.getBytes();

    case ZimCompression.zlib:
      final output = _BoundedSink();
      final input = zlibCodec.decoder.startChunkedConversion(output);
      try {
        for (var offset = 0; offset < body.length; offset += 16384) {
          final end = (offset + 16384).clamp(0, body.length);
          input.add(Uint8List.sublistView(body, offset, end));
        }
        input.close();
      } catch (_) {
        // Closing a failed converter may throw again; preserve the cause.
        try {
          input.close();
        } catch (_) {}
        rethrow;
      }
      return output.bytes.takeBytes();

    default:
      // bzip2 among them: legal in the format, absent from anything made
      // this decade, and worth saying rather than mis-reading.
      throw ZimException('unsupported cluster compression: $type');
  }
}

const zlibCodec = zlib;

class _BoundedOutput extends OutputMemoryStream {
  @override
  void writeBytes(List<int> bytes, {int? length}) {
    if (this.length + (length ?? bytes.length) > maxClusterBytes) {
      throw const ZimException(
        'decoded cluster exceeds the 64 MiB memory limit',
      );
    }
    super.writeBytes(bytes, length: length);
  }
}

class _BoundedSink implements Sink<List<int>> {
  final bytes = BytesBuilder(copy: false);
  @override
  void add(List<int> data) {
    if (bytes.length + data.length > maxClusterBytes) {
      throw const ZimException(
        'decoded cluster exceeds the 64 MiB memory limit',
      );
    }
    bytes.add(data);
  }

  @override
  void close() {}
}

/// Preflight frame headers and block bounds before calling the native decoder.
/// RFC 8878: each compressed block expands to at most min(window, 128 KiB).
/// This also bounds frames without a declared content size and concatenations.
/// https://www.rfc-editor.org/rfc/rfc8878.html#section-3.1.1.2
void validateZstdMemoryBudget(Uint8List data) {
  var cursor = 0;
  var totalBound = 0;
  int read(int count) {
    if (cursor + count > data.length) {
      throw const ZimException('truncated Zstandard frame');
    }
    var value = 0;
    for (var i = 0; i < count; i++) {
      final byte = data[cursor++];
      // All permitted lengths fit within 32 bits. Reject before shifting.
      if (i >= 4 && byte != 0) {
        throw const ZimException('Zstandard memory limit exceeded');
      }
      if (i < 4) value |= byte << (8 * i);
    }
    return value;
  }

  var frames = 0;
  while (cursor < data.length) {
    if (++frames > 1024 || read(4) != 0xfd2fb528) {
      throw const ZimException('unsupported Zstandard frame');
    }
    final flags = read(1);
    if (flags & 8 != 0) throw const ZimException('invalid Zstandard frame');
    final single = flags & 32 != 0;
    var window = 0;
    if (!single) {
      final descriptor = read(1);
      final exponent = 10 + (descriptor >> 3);
      if (exponent > 26) {
        throw const ZimException('Zstandard window exceeds memory limit');
      }
      final base = 1 << exponent;
      window = base + (base >> 3) * (descriptor & 7);
    }
    read(const [0, 1, 2, 4][flags & 3]); // Dictionary id.
    final sizeFlag = flags >> 6;
    final sizeBytes = sizeFlag == 0 ? (single ? 1 : 0) : (1 << sizeFlag);
    final declared = sizeBytes == 0
        ? null
        : read(sizeBytes) + (sizeBytes == 2 ? 256 : 0);
    if (single) window = declared!;
    if (window > maxClusterBytes || (declared ?? 0) > maxClusterBytes) {
      throw const ZimException('Zstandard frame exceeds memory limit');
    }
    var frameBound = 0;
    while (true) {
      final header = read(3);
      final kind = (header >> 1) & 3;
      final size = header >> 3;
      if (kind == 3 || size > 128 * 1024) {
        throw const ZimException('invalid Zstandard block');
      }
      frameBound += kind == 2 ? window.clamp(0, 128 * 1024) : size;
      cursor += kind == 1 ? 1 : size;
      if (cursor > data.length || frameBound > maxClusterBytes) {
        throw const ZimException('Zstandard block exceeds memory limit');
      }
      if (header & 1 != 0) break;
    }
    if (flags & 4 != 0) read(4);
    totalBound += frameBound;
    if (totalBound > maxClusterBytes) {
      throw const ZimException('Zstandard output exceeds memory limit');
    }
  }
  if (frames == 0) throw const ZimException('empty Zstandard cluster');
}
