import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart' show XZEncoder;

/// One entry to put into a test archive.
class ZimFixtureEntry {
  const ZimFixtureEntry({
    required this.namespace,
    required this.url,
    this.title = '',
    this.content,
    this.redirectTo,
    this.mimeType = 0,
  });

  final String namespace;
  final String url;
  final String title;

  /// The bytes this entry holds, or null for a redirect.
  final List<int>? content;

  /// `namespace/url` of the entry this redirects to.
  final String? redirectTo;

  final int mimeType;
}

/// A minimal ZIM writer.
///
/// The reader is hand-written, so its tests are written against archives
/// that can be read and amended here rather than against a binary blob
/// nobody can inspect.
class ZimFixture {
  ZimFixture({
    required this.entries,
    this.majorVersion = 6,
    this.mimeTypes = const ['text/html', 'image/png'],
    this.compression = 1,
    this.includeTitleListing = true,
  });

  final List<ZimFixtureEntry> entries;
  final int majorVersion;
  final List<String> mimeTypes;

  /// 1 = none, 4 = xz. Anything else is left to the reader to reject.
  final int compression;

  /// Whether to write the `X/listing/titleOrdered/v1` entry that version 6
  /// archives carry.
  final bool includeTitleListing;

  Uint8List build() {
    final all = [...entries];
    if (includeTitleListing) {
      all.add(
        const ZimFixtureEntry(
          namespace: 'X',
          url: 'listing/titleOrdered/v1',
          content: [],
        ),
      );
    }

    all.sort((a, b) {
      final namespaces = a.namespace.compareTo(b.namespace);
      return namespaces != 0 ? namespaces : a.url.compareTo(b.url);
    });

    final indexOf = {
      for (var i = 0; i < all.length; i++)
        '${all[i].namespace}/${all[i].url}': i,
    };

    // Only content entries go into the title listing, which is what a real
    // v1 listing holds.
    final byTitle =
        all
            .asMap()
            .entries
            .where((e) => e.value.namespace == 'C' || e.value.namespace == 'A')
            .toList()
          ..sort((a, b) => _titleOf(a.value).compareTo(_titleOf(b.value)));
    final listing = Uint32List.fromList([for (final e in byTitle) e.key]);

    // --- blobs, in one cluster ---
    final blobs = <List<int>>[];
    final blobIndex = <int, int>{};
    for (var i = 0; i < all.length; i++) {
      final entry = all[i];
      if (entry.redirectTo != null) continue;

      final content = entry.namespace == 'X' && includeTitleListing
          ? listing.buffer.asUint8List()
          : entry.content ?? const <int>[];
      blobIndex[i] = blobs.length;
      blobs.add(content);
    }

    final cluster = _buildCluster(blobs);

    // --- directory entries ---
    final entryBytes = <Uint8List>[];
    for (var i = 0; i < all.length; i++) {
      entryBytes.add(_buildEntry(all[i], indexOf, blobIndex[i]));
    }

    // --- layout ---
    const headerLength = 80;
    final mimeList = _buildMimeList();

    var cursor = headerLength + mimeList.length;
    final entryOffsets = <int>[];
    for (final bytes in entryBytes) {
      entryOffsets.add(cursor);
      cursor += bytes.length;
    }

    final urlPointerPosition = cursor;
    cursor += all.length * 8;

    final titlePointerPosition = cursor;
    final writeTitleTable = majorVersion == 5;
    if (writeTitleTable) cursor += all.length * 4;

    final clusterPointerPosition = cursor;
    cursor += 8; // one cluster

    final clusterPosition = cursor;
    cursor += cluster.length;

    final checksumPosition = cursor;

    // --- serialize ---
    final out = BytesBuilder();
    out.add(
      _buildHeader(
        entryCount: all.length,
        urlPointerPosition: urlPointerPosition,
        titlePointerPosition: titlePointerPosition,
        clusterPointerPosition: clusterPointerPosition,
        mimeListPosition: headerLength,
        checksumPosition: checksumPosition,
      ),
    );
    out.add(mimeList);
    for (final bytes in entryBytes) {
      out.add(bytes);
    }
    out.add(_u64List(entryOffsets));
    if (writeTitleTable) {
      out.add(
        _u32List([
          for (final e in byTitle) e.key,
          ...List.filled(all.length - byTitle.length, 0),
        ]),
      );
    }
    out.add(_u64List([clusterPosition]));
    out.add(cluster);
    out.add(Uint8List(16)); // checksum, never verified here

    return out.toBytes();
  }

  static String _titleOf(ZimFixtureEntry entry) =>
      entry.title.isEmpty ? entry.url : entry.title;

  Uint8List _buildHeader({
    required int entryCount,
    required int urlPointerPosition,
    required int titlePointerPosition,
    required int clusterPointerPosition,
    required int mimeListPosition,
    required int checksumPosition,
  }) {
    final header = Uint8List(80);
    final view = ByteData.sublistView(header);
    view.setUint32(0, 72173914, Endian.little);
    view.setUint16(4, majorVersion, Endian.little);
    view.setUint16(6, 1, Endian.little);
    view.setUint32(24, entryCount, Endian.little);
    view.setUint32(28, 1, Endian.little); // one cluster
    view.setUint64(32, urlPointerPosition, Endian.little);
    view.setUint64(40, titlePointerPosition, Endian.little);
    view.setUint64(48, clusterPointerPosition, Endian.little);
    view.setUint64(56, mimeListPosition, Endian.little);
    view.setUint32(64, 0xffffffff, Endian.little); // no main page by default
    view.setUint64(72, checksumPosition, Endian.little);
    return header;
  }

  Uint8List _buildMimeList() {
    final out = BytesBuilder();
    for (final type in mimeTypes) {
      out.add(utf8.encode(type));
      out.addByte(0);
    }
    out.addByte(0); // the empty string that ends the list
    return out.toBytes();
  }

  Uint8List _buildEntry(
    ZimFixtureEntry entry,
    Map<String, int> indexOf,
    int? blob,
  ) {
    final out = BytesBuilder();
    final head = Uint8List(16);
    final view = ByteData.sublistView(head);

    final redirect = entry.redirectTo;
    view.setUint16(
      0,
      redirect != null ? 0xffff : entry.mimeType,
      Endian.little,
    );
    head[2] = 0; // no extra parameters
    head[3] = entry.namespace.codeUnitAt(0);
    view.setUint32(4, 0, Endian.little); // revision

    if (redirect != null) {
      view.setUint32(8, indexOf[redirect]!, Endian.little);
      out.add(Uint8List.sublistView(head, 0, 12));
    } else {
      view.setUint32(8, 0, Endian.little); // cluster
      view.setUint32(12, blob ?? 0, Endian.little);
      out.add(head);
    }

    out.add(utf8.encode(entry.url));
    out.addByte(0);
    out.add(utf8.encode(entry.title));
    out.addByte(0);
    return out.toBytes();
  }

  Uint8List _buildCluster(List<List<int>> blobs) {
    final offsets = <int>[];
    var at = (blobs.length + 1) * 4;
    for (final blob in blobs) {
      offsets.add(at);
      at += blob.length;
    }
    offsets.add(at);

    final body = BytesBuilder()..add(_u32List(offsets));
    for (final blob in blobs) {
      body.add(blob);
    }

    final raw = body.toBytes();
    // Only xz is actually applied. zstd is a platform plugin no test can
    // reach, so a fixture that claims it stores its bytes plainly and the
    // test injects a decompressor that hands them back.
    final stored = switch (compression) {
      4 => Uint8List.fromList(XZEncoder().encodeBytes(raw)),
      _ => raw,
    };

    return (BytesBuilder()
          ..addByte(compression)
          ..add(stored))
        .toBytes();
  }

  static Uint8List _u64List(List<int> values) {
    final bytes = Uint8List(values.length * 8);
    final view = ByteData.sublistView(bytes);
    for (var i = 0; i < values.length; i++) {
      view.setUint64(i * 8, values[i], Endian.little);
    }
    return bytes;
  }

  static Uint8List _u32List(List<int> values) {
    final bytes = Uint8List(values.length * 4);
    final view = ByteData.sublistView(bytes);
    for (var i = 0; i < values.length; i++) {
      view.setUint32(i * 4, values[i], Endian.little);
    }
    return bytes;
  }
}

/// Writes [fixture] to a file in [directory] and returns its path.
String writeZim(
  Directory directory,
  ZimFixture fixture, {
  String name = 'test.zim',
}) {
  final path = '${directory.path}/$name';
  File(path).writeAsBytesSync(fixture.build());
  return path;
}
