import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:preppsuite_flutter/features/maps/application/pmtiles_archive.dart';

/// A minimal PMTiles v3 writer, so the reader can be tested against
/// archives that are readable and amendable rather than a binary blob.

void _writeVarint(BytesBuilder out, int value) {
  var remaining = value;
  while (remaining >= 0x80) {
    out.addByte((remaining & 0x7f) | 0x80);
    remaining >>= 7;
  }
  out.addByte(remaining);
}

Uint8List _encodeDirectory(
  List<({int tileId, int offset, int length, int runLength})> entries, {
  required bool contiguousOffsets,
}) {
  final out = BytesBuilder();
  _writeVarint(out, entries.length);

  var previousId = 0;
  for (final entry in entries) {
    _writeVarint(out, entry.tileId - previousId);
    previousId = entry.tileId;
  }
  for (final entry in entries) {
    _writeVarint(out, entry.runLength);
  }
  for (final entry in entries) {
    _writeVarint(out, entry.length);
  }
  for (var i = 0; i < entries.length; i++) {
    final follows =
        contiguousOffsets &&
        i > 0 &&
        entries[i].offset == entries[i - 1].offset + entries[i - 1].length;
    _writeVarint(out, follows ? 0 : entries[i].offset + 1);
  }
  return out.toBytes();
}

/// Builds an archive holding [tiles], keyed by (z, x, y).
Uint8List buildArchive({
  required Map<(int, int, int), String> tiles,
  int minZoom = 0,
  int maxZoom = 14,
  (double, double, double, double) bounds = (-180, -85, 180, 85),
  Map<String, Object?> metadata = const {},
  bool contiguousOffsets = false,
  int? leafSize,
}) {
  final tileData = BytesBuilder();
  final entries = <({int tileId, int offset, int length, int runLength})>[];

  final sorted = tiles.entries.toList()
    ..sort((a, b) {
      final left = tileIdFor(a.key.$1, a.key.$2, a.key.$3);
      final right = tileIdFor(b.key.$1, b.key.$2, b.key.$3);
      return left.compareTo(right);
    });

  for (final tile in sorted) {
    final body = gzip.encode(utf8.encode(tile.value));
    entries.add((
      tileId: tileIdFor(tile.key.$1, tile.key.$2, tile.key.$3),
      offset: tileData.length,
      length: body.length,
      runLength: 1,
    ));
    tileData.add(body);
  }

  // Real archives split their directory once it stops fitting: the root
  // then holds one run-length-zero entry per leaf, and every tile costs a
  // second lookup.
  final leaves = BytesBuilder();
  final List<int> directory;
  if (leafSize == null) {
    directory = gzip.encode(
      _encodeDirectory(entries, contiguousOffsets: contiguousOffsets),
    );
  } else {
    final rootEntries =
        <({int tileId, int offset, int length, int runLength})>[];
    for (var start = 0; start < entries.length; start += leafSize) {
      final chunk = entries.sublist(
        start,
        (start + leafSize).clamp(0, entries.length),
      );
      final encoded = gzip.encode(
        _encodeDirectory(chunk, contiguousOffsets: contiguousOffsets),
      );
      rootEntries.add((
        tileId: chunk.first.tileId,
        offset: leaves.length,
        length: encoded.length,
        runLength: 0,
      ));
      leaves.add(encoded);
    }
    directory = gzip.encode(
      _encodeDirectory(rootEntries, contiguousOffsets: false),
    );
  }

  final metadataBytes = gzip.encode(utf8.encode(jsonEncode(metadata)));

  const headerLength = 127;
  final rootOffset = headerLength;
  final metadataOffset = rootOffset + directory.length;
  final leafOffset = metadataOffset + metadataBytes.length;
  final tileDataOffset = leafOffset + leaves.length;

  final header = Uint8List(headerLength);
  header.setRange(0, 7, utf8.encode('PMTiles'));
  header[7] = 3;

  final view = ByteData.sublistView(header);
  view.setUint64(8, rootOffset, Endian.little);
  view.setUint64(16, directory.length, Endian.little);
  view.setUint64(24, metadataOffset, Endian.little);
  view.setUint64(32, metadataBytes.length, Endian.little);
  view.setUint64(40, leafOffset, Endian.little);
  view.setUint64(48, leaves.length, Endian.little);
  view.setUint64(56, tileDataOffset, Endian.little);
  view.setUint64(64, tileData.length, Endian.little);
  header[96] = 1; // clustered
  header[97] = 2; // internal compression: gzip
  header[98] = 2; // tile compression: gzip
  header[99] = 1; // tile type: mvt
  header[100] = minZoom;
  header[101] = maxZoom;
  view.setInt32(102, (bounds.$1 * 1e7).round(), Endian.little);
  view.setInt32(106, (bounds.$2 * 1e7).round(), Endian.little);
  view.setInt32(110, (bounds.$3 * 1e7).round(), Endian.little);
  view.setInt32(114, (bounds.$4 * 1e7).round(), Endian.little);

  return (BytesBuilder()
        ..add(header)
        ..add(directory)
        ..add(metadataBytes)
        ..add(leaves.toBytes())
        ..add(tileData.toBytes()))
      .toBytes();
}
