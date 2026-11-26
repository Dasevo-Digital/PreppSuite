import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
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

  /// The area the archive is about: what the offline points are fetched
  /// for, what the readiness overview counts places against and where the
  /// offline search says "outside".
  ///
  /// Usually the header's own box. Every map built in the app up to 3.0.3
  /// states the whole world there, because the world base under the rings
  /// went into the box (#389). For an archive that states the world, the
  /// box is taken from its metadata's `bounds` where that names a region,
  /// and otherwise from the tiles themselves ([_boundsOfTiles]). A real
  /// map of the world comes out as the world either way.
  late final PmTilesBounds bounds;

  /// Leaf directories read or being read, keyed by their offset, the
  /// most recently used last.
  ///
  /// An archive of any size is two levels deep, and panning revisits the
  /// same leaves constantly — without this every tile would cost a second
  /// read and a second gunzip.
  ///
  /// The reads themselves are kept, not only their results (#13). The
  /// renderer asks for a screenful of tiles at once, and on a part of the
  /// map not seen yet they all need the same leaf: with only finished
  /// leaves cached, every one of them missed and read and unpacked that
  /// leaf itself, one after another through the file's single queue.
  final _leafCache = <int, Future<_Directory>>{};

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
      final archive = PmTilesArchive._(source, header, root);
      archive.bounds = await archive._coveredBounds();
      return archive;
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
    } on ArgumentError {
      // A RangeError included: a number in the file that no check above
      // has thought of yet still costs this tile and not the walk (#327).
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

  Future<PmTilesBounds> _coveredBounds() async {
    final stated = PmTilesBounds(
      west: header.minLongitude,
      south: header.minLatitude,
      east: header.maxLongitude,
      north: header.maxLatitude,
    );
    if (!stated.isWholeWorld) return stated;
    try {
      final named = PmTilesBounds.parse((await metadata())['bounds']);
      if (named != null && !named.isWholeWorld) return named;
      return await _boundsOfTiles() ?? stated;
    } on Object {
      // Damage here costs the narrower box, not the map: it still draws,
      // and the world is what the archive said.
      return stated;
    }
  }

  /// The deepest level the walk below goes to once it has found the
  /// outermost ring. A tile there is about 0.09 degrees wide, which is
  /// all a box for points around a place needs, and the levels below it
  /// are where almost all of an archive's entries are.
  static const _boundsDeepestLevel = 12;

  /// The most directory entries the walk reads before it settles for what
  /// it has. A map built in the app comes to a few thousand up to level
  /// 12; a whole planet would be millions.
  static const _boundsEntryLimit = 50000;

  /// A level held for the whole world this deep is not a base under a
  /// region, it is a map of the world. The app's base ends at 4.
  static const _worldBaseDeepest = 5;

  /// The outermost ring's box, read from which tiles the archive holds.
  ///
  /// An archive the app built is a world base, levels 0 to 4 everywhere,
  /// and then rings that nest: the country coarse from level 5, the state
  /// deeper, the place deepest. So the walk passes over the levels that
  /// are held whole, takes the first that is not, and follows it down for
  /// as long as each level holds the same box at twice the resolution --
  /// each edge where the level above puts it, or half a tile inside.
  /// Where an edge jumps further in, the next ring has begun, and the
  /// level before is the outermost ring at its finest. The box is the
  /// tiles' own edges, so it holds the ring and at most a tile more.
  ///
  /// Null where no level is anything but whole: a world map.
  Future<PmTilesBounds?> _boundsOfTiles() async {
    final budget = _WalkBudget(_boundsEntryLimit);
    _TileRange? ring;
    // Ids run out of 64 bits past zoom 31.
    final deepest = math.min(header.maxZoom, 31);
    for (var z = header.minZoom; z <= deepest; z++) {
      if (ring != null && z > _boundsDeepestLevel) break;
      final level = _TileRange(z);
      try {
        await _collect(_rootDirectory, level, budget, depth: 0);
      } on _WalkTooLong {
        break;
      }
      if (level.isEmpty) {
        if (ring != null) break;
        continue;
      }
      if (ring == null) {
        if (level.coversWholeLevel) {
          if (z >= _worldBaseDeepest) return null;
          continue;
        }
        ring = level;
      } else if (level.continues(ring)) {
        ring = level;
      } else {
        break;
      }
    }
    return ring?.bounds;
  }

  /// Every tile of [level]'s zoom held under [directory], into [level].
  ///
  /// Ids are ordered by zoom level first, so the level is one stretch of
  /// ids and only the leaves that overlap it are read.
  Future<void> _collect(
    _Directory directory,
    _TileRange level,
    _WalkBudget budget, {
    required int depth,
  }) async {
    final first = _firstIdAt(level.z);
    final end = _firstIdAt(level.z + 1);
    final entries = directory.entries;
    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      if (entry.tileId >= end) return;
      if (entry.runLength == 0) {
        // A leaf holds the ids from its own up to the next entry's.
        if (i + 1 < entries.length && entries[i + 1].tileId <= first) {
          continue;
        }
        if (depth >= 2) {
          throw const PmTilesException('leaf directories nested too deep');
        }
        await _collect(await _leaf(entry), level, budget, depth: depth + 1);
        continue;
      }
      final from = math.max(entry.tileId, first);
      final to = math.min(entry.tileId + entry.runLength, end);
      for (var id = from; id < to; id++) {
        budget.take();
        final (x, y) = _hilbertPosition(level.z, id - first);
        level.add(x, y);
      }
    }
  }

  Future<_Directory> _leaf(_Entry entry) {
    final offset = header.leafDirectoryOffset + entry.offset;
    final cached = _leafCache.remove(offset);
    if (cached != null) return _leafCache[offset] = cached;

    if (_leafCache.length >= _leafCacheLimit) {
      _leafCache.remove(_leafCache.keys.first);
    }
    final reading = _readLeaf(offset, entry.length);
    // A read that failed is not a leaf: the next tile asks again.
    reading.then<void>(
      (_) {},
      onError: (Object _) {
        if (identical(_leafCache[offset], reading)) _leafCache.remove(offset);
      },
    );
    return _leafCache[offset] = reading;
  }

  Future<_Directory> _readLeaf(int offset, int length) async =>
      _Directory.parse(
        _decompress(
          await _readBounded(_source, offset, length),
          header.internalCompression,
        ),
      );

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

/// The tile [tileIdFor] gave [id] to.
({int z, int x, int y}) tileForId(int id) {
  if (id < 0) throw ArgumentError.value(id, 'id', 'is negative');
  var z = 0;
  while (z < 31 && id >= _firstIdAt(z + 1)) {
    z++;
  }
  final (x, y) = _hilbertPosition(z, id - _firstIdAt(z));
  return (z: z, x: x, y: y);
}

/// The first id at zoom [z]: every tile of every level above it,
/// (4^z - 1) / 3.
int _firstIdAt(int z) => ((1 << (z * 2)) - 1) ~/ 3;

/// Where on the level of zoom [z] the [position]th tile along the Hilbert
/// curve lies: [tileIdFor] backwards, the way the specification's own
/// readers walk it.
(int, int) _hilbertPosition(int z, int position) {
  var x = 0;
  var y = 0;
  var t = position;
  for (var side = 1; side < 1 << z; side <<= 1) {
    final rx = 1 & (t >> 1);
    final ry = 1 & (t ^ rx);
    if (ry == 0) {
      if (rx == 1) {
        x = side - 1 - x;
        y = side - 1 - y;
      }
      final swap = x;
      x = y;
      y = swap;
    }
    x += side * rx;
    y += side * ry;
    t >>= 2;
  }
  return (x, y);
}

/// A box on the map, in degrees.
class PmTilesBounds {
  const PmTilesBounds({
    required this.west,
    required this.south,
    required this.east,
    required this.north,
  });

  final double west;
  final double south;
  final double east;
  final double north;

  /// The whole Web Mercator world, give or take the rounding of a header
  /// that stores degrees in fixed point.
  bool get isWholeWorld =>
      west <= -179.9 && east >= 179.9 && south <= -84.9 && north >= 84.9;

  bool contains(double latitude, double longitude) =>
      longitude >= west &&
      longitude <= east &&
      latitude >= south &&
      latitude <= north;

  /// A box written as `"west,south,east,north"` -- the MBTiles spelling,
  /// which is what archives that carry one in their metadata use -- or as
  /// a list of the four. Null for anything that is not a box.
  static PmTilesBounds? parse(Object? value) {
    final List<Object?> parts = switch (value) {
      final String text => text.split(','),
      final List<Object?> list => list,
      _ => const [],
    };
    if (parts.length != 4) return null;
    final numbers = <double>[];
    for (final part in parts) {
      final number = switch (part) {
        final num value => value.toDouble(),
        final String text => double.tryParse(text.trim()),
        _ => null,
      };
      if (number == null || !number.isFinite) return null;
      numbers.add(number);
    }
    final [west, south, east, north] = numbers;
    if (west < -180 || east > 180 || south < -90 || north > 90) return null;
    if (west >= east || south >= north) return null;
    return PmTilesBounds(west: west, south: south, east: east, north: north);
  }

  @override
  String toString() => 'PmTilesBounds($west, $south, $east, $north)';
}

/// The tiles held at one zoom level, as the smallest range of columns and
/// rows that holds them.
class _TileRange {
  _TileRange(this.z);

  final int z;
  var minX = 1 << 62;
  var minY = 1 << 62;
  var maxX = -1;
  var maxY = -1;

  bool get isEmpty => maxX < 0;

  void add(int x, int y) {
    if (x < minX) minX = x;
    if (x > maxX) maxX = x;
    if (y < minY) minY = y;
    if (y > maxY) maxY = y;
  }

  bool get coversWholeLevel {
    final last = (1 << z) - 1;
    return minX == 0 && minY == 0 && maxX == last && maxY == last;
  }

  /// Whether this level holds the same box as [coarser], one level up, at
  /// twice the resolution: no edge more than half of one of the coarser
  /// tiles inside where the same box would put it.
  bool continues(_TileRange coarser) =>
      minX <= 2 * coarser.minX + 1 &&
      minY <= 2 * coarser.minY + 1 &&
      maxX >= 2 * coarser.maxX &&
      maxY >= 2 * coarser.maxY;

  PmTilesBounds get bounds {
    final side = 1 << z;
    double longitude(int x) => x / side * 360 - 180;
    double latitude(int y) {
      final n = math.pi * (1 - 2 * y / side);
      return math.atan((math.exp(n) - math.exp(-n)) / 2) * 180 / math.pi;
    }

    return PmTilesBounds(
      west: longitude(minX),
      south: latitude(maxY + 1),
      east: longitude(maxX + 1),
      north: latitude(minY),
    );
  }
}

/// How many more entries a walk may read.
class _WalkBudget {
  _WalkBudget(this._left);

  int _left;

  void take() {
    if (--_left < 0) throw const _WalkTooLong();
  }
}

class _WalkTooLong implements Exception {
  const _WalkTooLong();
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
    // Every entry takes at least one byte in each of the four columns, so
    // a directory cannot hold more entries than a quarter of its bytes.
    // Taken at its word, a count of a few hundred million allocated four
    // lists of gigabytes before the bytes ran out (#327) -- and the map
    // opens its archive at every start.
    if (count < 0 || count > bytes.length ~/ 4) {
      throw PmTilesException(
        'directory of ${bytes.length} bytes claims $count entries',
      );
    }

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
      // The first entry has nothing before it to follow.
      if (value == 0 && i == 0) {
        throw const PmTilesException('first entry has no offset');
      }
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
      // Ten bytes hold 64 bits; a longer number is not one.
      if (shift > 63) {
        throw const PmTilesException('number in directory is too long');
      }
      final byte = _bytes[_position++];
      result |= (byte & 0x7f) << shift;
      if (byte & 0x80 == 0) return result;
      shift += 7;
    }
  }
}
