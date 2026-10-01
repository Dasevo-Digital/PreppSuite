import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../../../core/bounded_gzip.dart';

/// Reads a PMTiles v3 archive from local storage.
///
/// Written by hand rather than taken from pub: the `pmtiles` package moved
/// to protobuf 6, `vector_tile_renderer` is still on protobuf 3, and the
/// two cannot be in one app. The format is small enough that reading it
/// directly is the lesser cost — a header, a directory of varints, and a
/// Hilbert curve.
///
/// Everything is read on demand through a [ByteRangeSource]. A country
/// extract is several gigabytes; nothing here ever holds more than one
/// directory and one tile, and the file is never copied.
class PmTilesArchive {
  PmTilesArchive._(this._source, this.header, this._rootDirectory);

  final ByteRangeSource _source;
  final PmTilesHeader header;
  final _Directory _rootDirectory;

  /// Leaf directories already read, keyed by their offset.
  ///
  /// An archive of any size is two levels deep, and panning revisits the
  /// same leaves constantly — without this every tile would cost a second
  /// read and a second gunzip.
  final _leafCache = <int, _Directory>{};

  /// How many leaves to keep. Each is tens of kilobytes at most, and a
  /// screenful of tiles rarely spans more than a handful.
  static const _leafCacheLimit = 16;

  static Future<PmTilesArchive> open(ByteRangeSource source) async {
    try {
      final header = PmTilesHeader.parse(
        await source.read(0, PmTilesHeader.byteLength),
      );
      final root = _Directory.parse(
        _decompress(
          await _readBounded(source, header.rootOffset, header.rootLength),
          header.internalCompression,
        ),
      );
      return PmTilesArchive._(source, header, root);
    } on Object {
      await source.close();
      rethrow;
    }
  }

  /// The tile at [z]/[x]/[y], decompressed, or null if the archive does
  /// not hold it.
  ///
  /// A miss is ordinary, not an error: an extract covers a region, and the
  /// map will ask for tiles outside it as soon as the user pans.
  Future<Uint8List?> tile(int z, int x, int y) async {
    if (z < header.minZoom || z > header.maxZoom) return null;

    final id = tileIdFor(z, x, y);
    var directory = _rootDirectory;

    // Two levels is what the specification allows; the loop guards against
    // a malformed archive pointing a leaf at another leaf forever.
    for (var depth = 0; depth < 3; depth++) {
      final entry = directory.find(id);
      if (entry == null) return null;

      if (entry.runLength > 0) {
        final bytes = await _readBounded(
          _source,
          header.tileDataOffset + entry.offset,
          entry.length,
        );
        return _decompress(bytes, header.tileCompression);
      }

      directory = await _leaf(entry);
    }
    return null;
  }

  /// [tile], with a damaged or oversized entry treated as absent.
  ///
  /// For callers that walk many tiles — the nearby search, the coverage
  /// count — where one bad entry should cost that tile and not the run.
  Future<Uint8List?> tileOrNull(int z, int x, int y) async {
    try {
      return await tile(z, x, y);
    } on PmTilesException {
      return null;
    } on FormatException {
      // A gzip stream that is not one.
      return null;
    }
  }

  /// The archive's own description of what is in it — under `vector_layers`
  /// for a vector archive, which is how the schema is recognized.
  Future<Map<String, Object?>> metadata() async {
    if (header.metadataLength == 0) return const {};

    final raw = _decompress(
      await _readBounded(
        _source,
        header.metadataOffset,
        header.metadataLength,
      ),
      header.internalCompression,
    );
    final decoded = jsonDecode(utf8.decode(raw));
    return decoded is Map<String, Object?> ? decoded : const {};
  }

  Future<void> close() => _source.close();

  Future<_Directory> _leaf(_Entry entry) async {
    final offset = header.leafDirectoryOffset + entry.offset;
    final cached = _leafCache[offset];
    if (cached != null) return cached;

    final leaf = _Directory.parse(
      _decompress(
        await _readBounded(_source, offset, entry.length),
        header.internalCompression,
      ),
    );

    if (_leafCache.length >= _leafCacheLimit) {
      _leafCache.remove(_leafCache.keys.first);
    }
    return _leafCache[offset] = leaf;
  }

  /// The most one read or one decompression may come to.
  ///
  /// A map archive is somebody else's file as often as not — handed over
  /// on a stick, downloaded from a forum — and every length in it is a
  /// number that file states about itself. Read and unpacked as stated, a
  /// directory entry claiming four gigabytes, or a tile of a few kilobytes
  /// that gunzips to several, ended the app the moment the map was panned
  /// onto it. A real vector tile is well under a megabyte unpacked and a
  /// leaf directory a few hundred kilobytes, so this is generous by two
  /// orders of magnitude and still small enough for any phone.
  static const maxBytes = 32 * 1024 * 1024;

  static Future<Uint8List> _readBounded(
    ByteRangeSource source,
    int offset,
    int length,
  ) {
    if (offset < 0 || length < 0 || length > maxBytes) {
      throw PmTilesException('entry of $length bytes exceeds the limit');
    }
    return source.read(offset, length);
  }

  static Uint8List _gunzip(Uint8List bytes) {
    try {
      return gunzipBounded(bytes, limit: maxBytes);
    } on DecompressionLimitException {
      throw const PmTilesException('decompressed entry exceeds the limit');
    }
  }

  static Uint8List _decompress(
    Uint8List bytes,
    PmTilesCompression compression,
  ) {
    return switch (compression) {
      PmTilesCompression.none => bytes,
      PmTilesCompression.gzip => _gunzip(bytes),
      // Brotli and zstd are legal in the format and not implemented here.
      // Saying so beats handing the renderer bytes it cannot parse.
      _ => throw PmTilesException(
        'unsupported compression: ${compression.name}',
      ),
    };
  }
}

/// Random access to a file, wherever it happens to live.
///
/// An interface rather than a [File] because Android has no path to give:
/// a document picked there is a `content://` URI that `dart:io` cannot
/// open at all, and the alternative — letting the picker copy a
/// multi-gigabyte archive into the app's cache — is not one.
abstract class ByteRangeSource {
  /// [length] bytes starting at [offset].
  Future<Uint8List> read(int offset, int length);

  Future<void> close();
}

/// A [ByteRangeSource] over an ordinary file. Everywhere but Android.
class FileByteRangeSource implements ByteRangeSource {
  FileByteRangeSource._(this._handle);

  final RandomAccessFile _handle;

  /// The read in flight, if any.
  ///
  /// Reads have to be taken one at a time. `dart:io` refuses a second
  /// asynchronous operation on a handle while one is pending, and a seek
  /// followed by a read is two of them — so without this queue every
  /// caller but the first gets `FileSystemException: An async operation
  /// is currently pending`. That is not a rare collision: the map
  /// renderer asks for a dozen tiles at once, and an article pulls its
  /// HTML, its stylesheet and its images together. One would arrive and
  /// the rest would fail.
  ///
  /// The two native sources do the same thing on their side of the
  /// channel — a single-threaded executor on Android, a serial queue on
  /// iOS — which is why this only ever went wrong on the desktop.
  Future<void> _pending = Future.value();

  static Future<FileByteRangeSource> open(File file) async =>
      FileByteRangeSource._(await file.open());

  @override
  Future<Uint8List> read(int offset, int length) {
    final result = _pending.then((_) async {
      await _handle.setPosition(offset);
      return _handle.read(length);
    });
    // The queue swallows what it hands on, or one failed read would fail
    // every read waiting behind it.
    _pending = result.then((_) {}, onError: (_) {});
    return result;
  }

  /// Closes once the reads already queued have finished — closing under
  /// them would turn a tidy shutdown into a handful of exceptions.
  @override
  Future<void> close() => _pending.then((_) => _handle.close());
}

class PmTilesException implements Exception {
  const PmTilesException(this.message);

  final String message;

  @override
  String toString() => 'PmTilesException: $message';
}

enum PmTilesCompression { unknown, none, gzip, brotli, zstd }

enum PmTilesType { unknown, mvt, png, jpeg, webp, avif }

/// The fixed 127-byte header at the start of every v3 archive.
class PmTilesHeader {
  const PmTilesHeader({
    required this.rootOffset,
    required this.rootLength,
    required this.metadataOffset,
    required this.metadataLength,
    required this.leafDirectoryOffset,
    required this.tileDataOffset,
    required this.internalCompression,
    required this.tileCompression,
    required this.tileType,
    required this.minZoom,
    required this.maxZoom,
    required this.minLongitude,
    required this.minLatitude,
    required this.maxLongitude,
    required this.maxLatitude,
  });

  static const byteLength = 127;
  static const _magic = 'PMTiles';

  final int rootOffset;
  final int rootLength;
  final int metadataOffset;
  final int metadataLength;
  final int leafDirectoryOffset;
  final int tileDataOffset;

  /// Applies to the directories and the metadata, not to the tiles.
  final PmTilesCompression internalCompression;
  final PmTilesCompression tileCompression;
  final PmTilesType tileType;

  final int minZoom;
  final int maxZoom;

  final double minLongitude;
  final double minLatitude;
  final double maxLongitude;
  final double maxLatitude;

  static PmTilesHeader parse(Uint8List bytes) {
    if (bytes.length < byteLength) {
      throw const PmTilesException('file is too short to be a PMTiles archive');
    }
    if (String.fromCharCodes(bytes.sublist(0, 7)) != _magic) {
      throw const PmTilesException('not a PMTiles archive');
    }
    if (bytes[7] != 3) {
      throw PmTilesException('unsupported PMTiles version ${bytes[7]}');
    }

    final data = ByteData.sublistView(bytes);
    int u64(int at) => data.getUint64(at, Endian.little);
    // Coordinates are stored as degrees times ten million.
    double coordinate(int at) => data.getInt32(at, Endian.little) / 1e7;

    return PmTilesHeader(
      rootOffset: u64(8),
      rootLength: u64(16),
      metadataOffset: u64(24),
      metadataLength: u64(32),
      leafDirectoryOffset: u64(40),
      tileDataOffset: u64(56),
      internalCompression: _compression(bytes[97]),
      tileCompression: _compression(bytes[98]),
      tileType: bytes[99] < PmTilesType.values.length
          ? PmTilesType.values[bytes[99]]
          : PmTilesType.unknown,
      minZoom: bytes[100],
      maxZoom: bytes[101],
      minLongitude: coordinate(102),
      minLatitude: coordinate(106),
      maxLongitude: coordinate(110),
      maxLatitude: coordinate(114),
    );
  }

  static PmTilesCompression _compression(int value) =>
      value < PmTilesCompression.values.length
      ? PmTilesCompression.values[value]
      : PmTilesCompression.unknown;
}

/// The tile's position on the Hilbert curve, which is how PMTiles orders
/// its entries.
///
/// A Hilbert curve rather than row-by-row because it keeps tiles that are
/// near each other on the map near each other in the file — which is what
/// makes a single read serve a whole screenful.
int tileIdFor(int z, int x, int y) {
  // Every zoom level below this one, in full: (4^z - 1) / 3.
  var id = ((1 << (z * 2)) - 1) ~/ 3;

  var rx = 0;
  var ry = 0;
  var tx = x;
  var ty = y;

  // Half the grid width, and zero at zoom 0 — where there is one tile,
  // no quadrant to descend into, and shifting by z - 1 would be an error.
  for (var side = (1 << z) >> 1; side > 0; side >>= 1) {
    rx = (tx & side) > 0 ? 1 : 0;
    ry = (ty & side) > 0 ? 1 : 0;
    id += side * side * ((3 * rx) ^ ry);

    // Rotate the quadrant so the curve stays continuous.
    if (ry == 0) {
      if (rx == 1) {
        tx = side - 1 - tx;
        ty = side - 1 - ty;
      }
      final swap = tx;
      tx = ty;
      ty = swap;
    }
  }
  return id;
}

class _Entry {
  const _Entry({
    required this.tileId,
    required this.offset,
    required this.length,
    required this.runLength,
  });

  final int tileId;
  final int offset;
  final int length;

  /// How many consecutive tile ids share this entry. Zero means the entry
  /// points at a leaf directory instead of at a tile.
  final int runLength;
}

class _Directory {
  const _Directory(this.entries);

  final List<_Entry> entries;

  /// The entry covering [tileId], or null.
  ///
  /// Binary search for the last entry at or before the id, then check that
  /// the id actually falls inside its run — a directory is sparse, so
  /// "the entry before" is frequently not the entry for this tile.
  _Entry? find(int tileId) {
    var low = 0;
    var high = entries.length - 1;
    _Entry? candidate;

    while (low <= high) {
      final middle = (low + high) >> 1;
      final entry = entries[middle];
      if (entry.tileId <= tileId) {
        candidate = entry;
        low = middle + 1;
      } else {
        high = middle - 1;
      }
    }

    if (candidate == null) return null;
    if (candidate.runLength == 0) return candidate;
    return tileId < candidate.tileId + candidate.runLength ? candidate : null;
  }

  /// The serialization is column-wise: all tile ids, then all run lengths,
  /// then all lengths, then all offsets — each as varints, ids as deltas.
  static _Directory parse(Uint8List bytes) {
    final reader = _VarintReader(bytes);
    final count = reader.read();

    final tileIds = List<int>.filled(count, 0);
    var previous = 0;
    for (var i = 0; i < count; i++) {
      previous += reader.read();
      tileIds[i] = previous;
    }

    final runLengths = List<int>.generate(count, (_) => reader.read());
    final lengths = List<int>.generate(count, (_) => reader.read());

    final offsets = List<int>.filled(count, 0);
    for (var i = 0; i < count; i++) {
      final value = reader.read();
      // Zero is shorthand for "directly after the previous entry", which
      // is how a clustered archive avoids storing most offsets at all.
      offsets[i] = value == 0 ? offsets[i - 1] + lengths[i - 1] : value - 1;
    }

    return _Directory([
      for (var i = 0; i < count; i++)
        _Entry(
          tileId: tileIds[i],
          offset: offsets[i],
          length: lengths[i],
          runLength: runLengths[i],
        ),
    ]);
  }
}

class _VarintReader {
  _VarintReader(this._bytes);

  final Uint8List _bytes;
  int _position = 0;

  int read() {
    var result = 0;
    var shift = 0;
    while (true) {
      if (_position >= _bytes.length) {
        throw const PmTilesException('directory ended mid-number');
      }
      final byte = _bytes[_position++];
      result |= (byte & 0x7f) << shift;
      if (byte & 0x80 == 0) return result;
      shift += 7;
    }
  }
}
