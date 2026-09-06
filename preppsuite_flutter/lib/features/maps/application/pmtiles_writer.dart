import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'pmtiles_archive.dart';

/// Writes a PMTiles v3 archive.
///
/// The counterpart to [PmTilesArchive], and hand-written for the same
/// reason: the `pmtiles` package needs a protobuf version
/// `vector_tile_renderer` cannot have. What it produces is read back by
/// that reader, which is the only definition of correct that matters
/// here.
///
/// Tiles are appended to a scratch file as they arrive and the archive is
/// assembled at the end, because none of the offsets in the header can be
/// known before the last tile is in. The bytes are never all in memory:
/// an extract of a city at street level is hundreds of megabytes.
///
/// Beside the scratch file lies a journal naming where each tile went.
/// It is what makes a download of tens of thousands of tiles survive the
/// app being closed: a country takes longer than anyone leaves an app
/// open, so losing the work on exit would mean the feature only ever
/// worked for towns.
class PmTilesWriter {
  PmTilesWriter._(this._scratch, this._scratchFile, this._journalFile);

  final RandomAccessFile _scratch;
  final File _scratchFile;
  final File _journalFile;

  IOSink? _journal;

  /// One per distinct tile id, sorted only at the end.
  final _entries = <_WriteEntry>[];

  /// Content hash to where those exact bytes already are, so the empty
  /// ocean is stored once rather than ten thousand times.
  final _byContent = <String, _Placement>{};

  int _scratchLength = 0;
  int _addressedTiles = 0;

  /// Writes are chained rather than run as they come.
  ///
  /// The area downloader fetches several tiles at once, and a
  /// [RandomAccessFile] refuses a second write while one is pending —
  /// besides which the offset bookkeeping is only correct if one tile is
  /// placed at a time.
  Future<void> _queue = Future<void>.value();

  static const _scratchName = 'tiles.scratch';
  static const _journalName = 'tiles.journal';

  static File scratchFileIn(Directory directory) =>
      File('${directory.path}${Platform.pathSeparator}$_scratchName');

  static File journalFileIn(Directory directory) =>
      File('${directory.path}${Platform.pathSeparator}$_journalName');

  /// A writer with nothing in it, discarding any half-finished download
  /// that was there.
  static Future<PmTilesWriter> create(Directory workingDirectory) async {
    final scratch = scratchFileIn(workingDirectory);
    final journal = journalFileIn(workingDirectory);
    if (await scratch.exists()) await scratch.delete();
    if (await journal.exists()) await journal.delete();

    final writer = PmTilesWriter._(
      await scratch.open(mode: FileMode.write),
      scratch,
      journal,
    );
    writer._openJournal();
    return writer;
  }

  /// Picks up where a previous run stopped, or starts fresh when there is
  /// nothing to pick up.
  ///
  /// The journal is written after the bytes are flushed, so a run that
  /// died mid-tile leaves the scratch file longer than the journal
  /// accounts for. Truncating to what the journal knows is what makes the
  /// two agree again.
  ///
  /// One thing is not carried over: which tiles had identical content.
  /// Rebuilding that would mean re-reading everything already stored, and
  /// the cost of not doing it is a few duplicated tiles, not a wrong map.
  static Future<PmTilesWriter> resume(Directory workingDirectory) async {
    final scratch = scratchFileIn(workingDirectory);
    final journal = journalFileIn(workingDirectory);

    if (!await scratch.exists() || !await journal.exists()) {
      return create(workingDirectory);
    }

    final entries = <_WriteEntry>[];
    var end = 0;
    for (final line in await journal.readAsLines()) {
      final parts = line.split(' ');
      if (parts.length != 3) continue;
      final id = int.tryParse(parts[0]);
      final offset = int.tryParse(parts[1]);
      final length = int.tryParse(parts[2]);
      // A line cut in half by the process ending is the last one and is
      // simply not there; the tile it described gets fetched again.
      if (id == null || offset == null || length == null) continue;
      entries.add(_WriteEntry(tileId: id, offset: offset, length: length));
      if (offset + length > end) end = offset + length;
    }

    final handle = await scratch.open(mode: FileMode.append);
    if (await scratch.length() != end) {
      await handle.truncate(end);
      await handle.setPosition(end);
    }

    final writer = PmTilesWriter._(handle, scratch, journal)
      .._scratchLength = end
      .._addressedTiles = entries.length;
    writer._entries.addAll(entries);
    writer._openJournal();
    return writer;
  }

  void _openJournal() =>
      _journal = _journalFile.openWrite(mode: FileMode.append);

  /// The tiles already stored, so a resumed download can skip them.
  Set<int> get storedTileIds => {
    for (final entry in _entries) entry.tileId,
  };

  /// How many distinct tiles have been stored.
  int get tileCount => _entries.length;

  /// How many bytes of tile data are on disk so far.
  int get dataLength => _scratchLength;

  /// Adds one tile. [bytes] is the tile as the server gave it.
  ///
  /// Safe to call from several places at once; the writes are serialized
  /// internally.
  Future<void> add(int z, int x, int y, Uint8List bytes) {
    final result = _queue.then((_) => _add(z, x, y, bytes));
    // The chain has to survive a failure, or every later tile would fail
    // with the first one's error.
    _queue = result.then((_) {}, onError: (Object _) {});
    return result;
  }

  Future<void> _add(int z, int x, int y, Uint8List bytes) async {
    final compressed = _gzipped(bytes);
    final key = _contentKey(compressed);

    _addressedTiles++;

    final id = tileIdFor(z, x, y);

    final existing = _byContent[key];
    if (existing != null) {
      _entries.add(
        _WriteEntry(
          tileId: id,
          offset: existing.offset,
          length: existing.length,
        ),
      );
      _record(id, existing.offset, existing.length);
      return;
    }

    await _scratch.writeFrom(compressed);
    // Flushed before the journal names it, so a journal line never
    // describes bytes that are not on disk. The other way round is
    // recoverable; this way round is a corrupt archive.
    await _scratch.flush();

    final placement = _Placement(_scratchLength, compressed.length);
    _scratchLength += compressed.length;
    _byContent[key] = placement;

    _entries.add(
      _WriteEntry(
        tileId: id,
        offset: placement.offset,
        length: placement.length,
      ),
    );
    _record(id, placement.offset, placement.length);
  }

  void _record(int tileId, int offset, int length) =>
      _journal?.writeln('$tileId $offset $length');

  /// Assembles the archive at [path] and discards the working files.
  Future<void> finish({
    required String path,
    required int minZoom,
    required int maxZoom,
    required double minLongitude,
    required double minLatitude,
    required double maxLongitude,
    required double maxLatitude,
    required Map<String, Object?> metadata,
  }) async {
    // Whatever is still queued has to land before the offsets are read.
    await _queue;
    await _scratch.flush();
    await _scratch.close();
    await _closeJournal();

    _entries.sort((a, b) => a.tileId.compareTo(b.tileId));

    // The same tile twice would put two entries under one id, and the
    // directory's binary search assumes each id appears once.
    final unique = <_WriteEntry>[];
    for (final entry in _entries) {
      if (unique.isNotEmpty && unique.last.tileId == entry.tileId) {
        unique[unique.length - 1] = entry;
      } else {
        unique.add(entry);
      }
    }

    final directories = _buildDirectories(unique);
    final metadataBytes = Uint8List.fromList(
      gzip.encode(utf8.encode(jsonEncode(metadata))),
    );

    final rootOffset = PmTilesHeader.byteLength;
    final metadataOffset = rootOffset + directories.root.length;
    final leafOffset = metadataOffset + metadataBytes.length;
    final tileDataOffset = leafOffset + directories.leaves.length;

    final output = File(path);
    final sink = output.openWrite();
    try {
      sink.add(
        _header(
          rootOffset: rootOffset,
          rootLength: directories.root.length,
          metadataOffset: metadataOffset,
          metadataLength: metadataBytes.length,
          leafOffset: leafOffset,
          leafLength: directories.leaves.length,
          tileDataOffset: tileDataOffset,
          tileDataLength: _scratchLength,
          entryCount: unique.length,
          contentCount: _byContent.length,
          minZoom: minZoom,
          maxZoom: maxZoom,
          minLongitude: minLongitude,
          minLatitude: minLatitude,
          maxLongitude: maxLongitude,
          maxLatitude: maxLatitude,
        ),
      );
      sink.add(directories.root);
      sink.add(metadataBytes);
      sink.add(directories.leaves);

      // Streamed rather than read: this is the whole archive.
      await sink.addStream(_scratchFile.openRead());
      await sink.flush();
    } finally {
      await sink.close();
      if (await _scratchFile.exists()) await _scratchFile.delete();
      if (await _journalFile.exists()) await _journalFile.delete();
    }
  }

  /// Puts the working files down without deleting them, so the next run
  /// can pick the download up where it stopped.
  Future<void> close() async {
    try {
      await _queue;
      await _scratch.flush();
      await _scratch.close();
    } on FileSystemException {
      // Already closed by a finish that failed part-way; nothing to do.
    }
    await _closeJournal();
  }

  /// Throws the half-finished download away for good.
  Future<void> abandon() async {
    await close();
    if (await _scratchFile.exists()) await _scratchFile.delete();
    if (await _journalFile.exists()) await _journalFile.delete();
  }

  Future<void> _closeJournal() async {
    final journal = _journal;
    _journal = null;
    if (journal == null) return;
    await journal.flush();
    await journal.close();
  }

  /// The root directory must fit in the first 16,384 bytes of the file,
  /// header included. Below that everything goes in the root; above it,
  /// the entries are cut into leaves and the root points at those.
  static _Directories _buildDirectories(List<_WriteEntry> entries) {
    final flat = _serialize(entries);
    if (PmTilesHeader.byteLength + flat.length <= _rootDirectoryLimit) {
      return _Directories(flat, Uint8List(0));
    }

    // Grow the leaves until the root of pointers fits. Doubling rather
    // than solving for it: the serialized size depends on the values, and
    // three or four rounds settle it.
    var perLeaf = 4096;
    while (true) {
      final leafBytes = BytesBuilder();
      final rootEntries = <_WriteEntry>[];

      for (var start = 0; start < entries.length; start += perLeaf) {
        final end = start + perLeaf > entries.length
            ? entries.length
            : start + perLeaf;
        final slice = entries.sublist(start, end);
        final serialized = _serialize(slice);

        rootEntries.add(
          _WriteEntry(
            tileId: slice.first.tileId,
            offset: leafBytes.length,
            length: serialized.length,
            // Zero marks an entry that points at a leaf directory rather
            // than at a tile.
            runLength: 0,
          ),
        );
        leafBytes.add(serialized);
      }

      final root = _serialize(rootEntries);
      if (PmTilesHeader.byteLength + root.length <= _rootDirectoryLimit) {
        return _Directories(root, leafBytes.takeBytes());
      }
      perLeaf *= 2;
    }
  }

  static const _rootDirectoryLimit = 16384;

  /// Column-wise varints — all ids as deltas, then run lengths, then
  /// lengths, then offsets — gzipped, which is what the header declares
  /// as the internal compression.
  static Uint8List _serialize(List<_WriteEntry> entries) {
    final out = BytesBuilder();
    void varint(int value) {
      var remaining = value;
      while (remaining >= 0x80) {
        out.addByte((remaining & 0x7f) | 0x80);
        remaining >>= 7;
      }
      out.addByte(remaining);
    }

    varint(entries.length);

    var previous = 0;
    for (final entry in entries) {
      varint(entry.tileId - previous);
      previous = entry.tileId;
    }
    for (final entry in entries) {
      varint(entry.runLength);
    }
    for (final entry in entries) {
      varint(entry.length);
    }
    for (var i = 0; i < entries.length; i++) {
      // Zero is shorthand for "directly after the previous entry"; the
      // reader expands it. Anything else is stored as offset + 1, since
      // zero is taken.
      if (i > 0 &&
          entries[i].offset == entries[i - 1].offset + entries[i - 1].length) {
        varint(0);
      } else {
        varint(entries[i].offset + 1);
      }
    }

    return Uint8List.fromList(gzip.encode(out.takeBytes()));
  }

  Uint8List _header({
    required int rootOffset,
    required int rootLength,
    required int metadataOffset,
    required int metadataLength,
    required int leafOffset,
    required int leafLength,
    required int tileDataOffset,
    required int tileDataLength,
    required int entryCount,
    required int contentCount,
    required int minZoom,
    required int maxZoom,
    required double minLongitude,
    required double minLatitude,
    required double maxLongitude,
    required double maxLatitude,
  }) {
    final bytes = Uint8List(PmTilesHeader.byteLength);
    bytes.setRange(0, 7, ascii.encode('PMTiles'));
    bytes[7] = 3;

    final data = ByteData.sublistView(bytes);
    void u64(int at, int value) => data.setUint64(at, value, Endian.little);
    void coordinate(int at, double degrees) =>
        data.setInt32(at, (degrees * 1e7).round(), Endian.little);

    u64(8, rootOffset);
    u64(16, rootLength);
    u64(24, metadataOffset);
    u64(32, metadataLength);
    u64(40, leafOffset);
    u64(48, leafLength);
    u64(56, tileDataOffset);
    u64(64, tileDataLength);
    u64(72, _addressedTiles);
    u64(80, entryCount);
    u64(88, contentCount);

    // Not clustered: tiles were written in the order they arrived from
    // the network, not in tile-id order. The reader does not care, and
    // reordering would mean rewriting the whole archive.
    bytes[96] = 0;
    bytes[97] = PmTilesCompression.gzip.index;
    bytes[98] = PmTilesCompression.gzip.index;
    bytes[99] = PmTilesType.mvt.index;
    bytes[100] = minZoom;
    bytes[101] = maxZoom;

    coordinate(102, minLongitude);
    coordinate(106, minLatitude);
    coordinate(110, maxLongitude);
    coordinate(114, maxLatitude);

    bytes[118] = minZoom;
    coordinate(119, (minLongitude + maxLongitude) / 2);
    coordinate(123, (minLatitude + maxLatitude) / 2);

    return bytes;
  }

  /// Tiles arrive either as raw protobuf or already gzipped, depending on
  /// what the server and the HTTP client did between them. Compressing a
  /// gzip stream again would leave the reader with bytes the renderer
  /// cannot parse.
  static Uint8List _gzipped(Uint8List bytes) {
    if (bytes.length >= 2 && bytes[0] == 0x1f && bytes[1] == 0x8b) {
      return bytes;
    }
    return Uint8List.fromList(gzip.encode(bytes));
  }

  /// Length and a sample of the bytes. A full hash of every tile would
  /// cost more than the duplicates it finds; a collision here would only
  /// ever affect tiles that are the same size and identical at both ends.
  static String _contentKey(Uint8List bytes) {
    if (bytes.length <= 64) return '${bytes.length}:${bytes.join(',')}';
    return '${bytes.length}:${bytes.sublist(0, 32).join(',')}'
        ':${bytes.sublist(bytes.length - 32).join(',')}';
  }
}

class _Placement {
  const _Placement(this.offset, this.length);

  final int offset;
  final int length;
}

class _WriteEntry {
  const _WriteEntry({
    required this.tileId,
    required this.offset,
    required this.length,
    this.runLength = 1,
  });

  final int tileId;
  final int offset;
  final int length;
  final int runLength;
}

class _Directories {
  const _Directories(this.root, this.leaves);

  final Uint8List root;
  final Uint8List leaves;
}
