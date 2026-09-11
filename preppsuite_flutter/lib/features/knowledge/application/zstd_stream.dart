import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:zstandard_native/zstandard_native_bindings.dart';

import 'zim_archive.dart' show ZimException;

/// Decompresses a zstd frame without being told how big it will be.
///
/// The plugin's own `decompress` asks the frame header for the final size
/// and, where the header does not say, allocates twenty times the
/// compressed length and hopes. No ZIM archive says: every cluster in all
/// eight archives measured here was written with streaming compression,
/// which leaves the size out. So the guess is all there ever is — and for
/// iFixit it is wrong for 688 of 718 clusters, the worst expanding 114
/// times. The plugin then returns null, the reader turns that into "a
/// cluster could not be decompressed", and the article view shows
/// "the archive answered with 500" for almost every page. Wikipedia
/// escaped it by a hair: its largest cluster expands 18.9 times.
///
/// Streaming needs no guess. The frame is pushed through a decompression
/// context in fixed-size pieces and the output is collected as it comes,
/// which is what `ZSTD_decompressStream` is for.
///
/// [limit] bounds the result the same way the caller's own limit does: an
/// archive is not trusted content, and a frame that claims to expand
/// without end must not be allowed to.
Uint8List zstdDecompress(Uint8List body, {required int limit}) {
  final bindings = _bindings;
  final context = bindings.ZSTD_createDCtx();
  if (context == nullptr) {
    throw const ZimException('no zstd context');
  }

  final outSize = bindings.ZSTD_DStreamOutSize();
  final source = calloc<Uint8>(body.length);
  final sink = calloc<Uint8>(outSize);
  final input = calloc<ZSTD_inBuffer>();
  final output = calloc<ZSTD_outBuffer>();

  try {
    source.asTypedList(body.length).setAll(0, body);
    bindings.ZSTD_initDStream(context.cast());

    input.ref
      ..src = source.cast()
      ..size = body.length
      ..pos = 0;

    final collected = BytesBuilder(copy: false);
    // Zero means the frame ended cleanly. Anything else is how much the
    // decoder would like to see next, and is only a hint.
    var remaining = 1;

    while (input.ref.pos < body.length || remaining != 0) {
      output.ref
        ..dst = sink.cast()
        ..size = outSize
        ..pos = 0;

      final before = input.ref.pos;
      remaining = bindings.ZSTD_decompressStream(
        context.cast(),
        output,
        input,
      );
      if (bindings.ZSTD_isError(remaining) != 0) {
        throw const ZimException('a cluster could not be decompressed');
      }

      if (output.ref.pos > 0) {
        collected.add(Uint8List.fromList(sink.asTypedList(output.ref.pos)));
      }
      if (collected.length > limit) {
        throw const ZimException(
          'decoded cluster exceeds the 64 MiB memory limit',
        );
      }

      // Neither side moved and the frame is not finished: the decoder
      // cannot make progress, and looping would mean looping forever.
      if (input.ref.pos == before && output.ref.pos == 0 && remaining != 0) {
        throw const ZimException('truncated Zstandard frame');
      }
    }

    return collected.takeBytes();
  } finally {
    calloc.free(output);
    calloc.free(input);
    calloc.free(sink);
    calloc.free(source);
    bindings.ZSTD_freeDCtx(context);
  }
}

/// The plugin's own native library, opened directly.
///
/// Same file the plugin uses, named the same way it names it — this is
/// not a second copy of zstd, only a second door to the one already in
/// the app. Opened lazily, so a plain `flutter test` (which has no engine
/// and therefore no plugin) only fails if it actually decompresses
/// something; those tests inject a decompressor of their own.
final ZstandardNativeBindings _bindings = ZstandardNativeBindings(
  _openLibrary(),
);

DynamicLibrary _openLibrary() {
  if (Platform.isMacOS) {
    return DynamicLibrary.open('zstandard_macos.framework/zstandard_macos');
  }
  if (Platform.isIOS) {
    return DynamicLibrary.open('zstandard_ios.framework/zstandard_ios');
  }
  if (Platform.isLinux) return DynamicLibrary.open('libzstandard_linux.so');
  if (Platform.isAndroid) return DynamicLibrary.open('libzstandard_android.so');
  if (Platform.isWindows) return DynamicLibrary.open('zstandard_windows.dll');
  throw UnsupportedError('no zstd for ${Platform.operatingSystem}');
}
