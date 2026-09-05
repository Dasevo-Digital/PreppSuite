import 'dart:io' show zlib;
import 'dart:typed_data';

import 'package:archive/archive.dart' show XZDecoder;
import 'package:zstandard/zstandard.dart';

import 'zim_archive.dart' show ZimException;

/// Turns a cluster's stored bytes into its contents.
///
/// Injectable so the reader can be tested without a Flutter plugin
/// binding: zstd is a platform plugin, and a unit test has no engine to
/// answer it.
typedef ClusterDecompressor =
    Future<Uint8List> Function(int compressionType, Uint8List body);

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
  switch (type) {
    case ZimCompression.none:
      return body;

    case ZimCompression.zstd:
      // Native on every platform the app ships to. Returns null rather
      // than throwing when the frame is not readable.
      final decoded = await Zstandard().decompress(body);
      if (decoded == null) {
        throw const ZimException('a cluster could not be decompressed');
      }
      return decoded;

    case ZimCompression.xz:
      return Uint8List.fromList(XZDecoder().decodeBytes(body));

    case ZimCompression.zlib:
      return Uint8List.fromList(zlibCodec.decode(body));

    default:
      // bzip2 among them: legal in the format, absent from anything made
      // this decade, and worth saying rather than mis-reading.
      throw ZimException('unsupported cluster compression: $type');
  }
}

const zlibCodec = zlib;
