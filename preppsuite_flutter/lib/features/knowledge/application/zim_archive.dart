import 'archive_memory_limits.dart';

import 'dart:convert';
import 'dart:typed_data';

import '../../maps/application/pmtiles_archive.dart' show ByteRangeSource;
import 'zim_decompression.dart';

/// Reads a ZIM archive — the format Kiwix packs Wikipedia into.
///
/// Written by hand for the same reason the PMTiles reader was: there is no
/// Dart binding for libzim, and building one would mean carrying a C++
/// library with Xapian and ICU behind it onto every platform. The format
/// itself is a header, three sorted index tables and a pile of compressed
/// clusters.
///
/// Nothing is held in memory beyond one decompressed cluster at a time. A
/// German Wikipedia archive is tens of gigabytes; the point of the whole
/// exercise is that it stays on disk.
class ZimArchive {
  ZimArchive._(this._source, this.header, this._mimeTypes, this._decompress);

  final ByteRangeSource _source;
  final ClusterDecompressor _decompress;

  final ZimHeader header;

  /// Indexed by the `mimeType` field of a directory entry.
  final List<String> _mimeTypes;

  /// Decompressed clusters, keyed by cluster number.
  ///
  /// One article pulls its text, its stylesheet and several images, and
  /// those sit together in the same cluster far more often than not —
  /// without this, opening one page would decompress the same few
  /// megabytes half a dozen times.
  final _clusterCache = <int, Uint8List>{};

  static const _clusterCacheLimit = 4;
  int _cachedBytes = 0;
  void clearClusterCache() {
    _clusterCache.clear();
    _cachedBytes = 0;
  }

  static Future<ZimArchive> open(
    ByteRangeSource source, {
    ClusterDecompressor decompress = decompressCluster,
  }) async {
    try {
      final header = ZimHeader.parse(
        await source.read(0, ZimHeader.byteLength),
      );
      final mimeTypes = await _readMimeTypes(source, header.mimeListPosition);
      return ZimArchive._(source, header, mimeTypes, decompress);
    } on Object {
      await source.close();
      rethrow;
    }
  }

  Future<void> close() {
    clearClusterCache();
    return _source.close();
  }

  /// The entry at [index] in URL order, which is the order of the archive's
  /// main index.
  Future<ZimEntry> entryAt(int index) async {
    if (index < 0 || index >= header.entryCount) {
      throw ZimException('no entry at index $index');
    }

    final pointer = await _readUint64(header.urlPointerPosition + index * 8);
    return _readEntry(index, pointer);
  }

  /// The entry for [url] in [namespace], or null.
  ///
  /// Binary search over the URL index, which the format keeps sorted by
  /// namespace and then by URL. Each step reads one pointer and one entry,
  /// so a lookup in a twenty-million-entry archive is about fifty small
  /// reads rather than a scan.
  Future<ZimEntry?> findByUrl(String namespace, String url) async {
    var low = 0;
    var high = header.entryCount - 1;

    while (low <= high) {
      final middle = (low + high) >> 1;
      final entry = await entryAt(middle);
      final comparison = _compareKeys(
        entry.namespace,
        entry.url,
        namespace,
        url,
      );
      if (comparison == 0) return entry;
      if (comparison < 0) {
        low = middle + 1;
      } else {
        high = middle - 1;
      }
    }
    return null;
  }

  /// Follows a redirect to the entry it points at.
  ///
  /// Bounded rather than recursive: a chain longer than a couple of hops
  /// is a damaged archive, and following it forever would hang the reader
  /// rather than fail it.
  Future<ZimEntry?> resolve(ZimEntry entry) async {
    var current = entry;
    for (var hop = 0; hop < 5; hop++) {
      final target = current.redirectIndex;
      if (target == null) return current;
      current = await entryAt(target);
    }
    return null;
  }

  /// The bytes of [entry] — an article's HTML, an image, a stylesheet.
  Future<Uint8List> readBlob(ZimEntry entry) async {
    final cluster = entry.clusterNumber;
    final blob = entry.blobNumber;
    if (cluster == null || blob == null) {
      throw const ZimException('entry holds no content');
    }

    final body = await _cluster(cluster);
    return _blobFrom(body, blob);
  }

  /// The archive's own full-text index, or null when it carries none.
  ///
  /// Two names, because the entry moved: current archives keep it under
  /// `X`, ones from before the namespace reform under `Z`. Archives built
  /// with `zimwriterfs` and no indexing step have neither.
  Future<ZimEntry?> fullTextIndexEntry() async {
    for (final (namespace, url) in const [
      ('X', 'fulltext/xapian'),
      ('Z', '/fulltextIndex/xapian'),
    ]) {
      final entry = await findByUrl(namespace, url);
      if (entry != null && !entry.isRedirect) return entry;
    }
    return null;
  }

  /// Where [entry]'s bytes physically lie in the file, or null when they
  /// have no such place.
  ///
  /// The one thing this reader hands out that is not bytes but a position,
  /// and it exists for the search index: Xapian opens a database from a
  /// file descriptor at an offset, so the index can be used where it lies
  /// rather than unpacked out of a thirty-gigabyte archive.
  ///
  /// Null whenever the cluster is compressed, which is most of them — a
  /// compressed blob exists only after it has been decompressed and has no
  /// offset to name. Kiwix writes the index uncompressed for this reason.
  Future<ZimBlobLocation?> directAccessInfo(ZimEntry entry) async {
    final cluster = entry.clusterNumber;
    final blob = entry.blobNumber;
    if (cluster == null || blob == null) return null;
    if (cluster >= header.clusterCount) return null;

    final start = await _readUint64(
      header.clusterPointerPosition + cluster * 8,
    );
    final info = (await _source.read(start, 1))[0];

    // Zero is what archives predating the field wrote, and meant the same
    // thing as one: the bytes are stored as they are.
    final compression = info & 0x0f;
    if (compression != ZimCompression.none && compression != 0) return null;

    final width = info & 0x10 != 0 ? 8 : 4;
    final body = start + 1;

    // Read straight from the file rather than through the cluster cache:
    // an uncompressed index cluster is the size of the index itself, and
    // caching it would mean holding gigabytes to learn one number.
    Future<int> offsetAt(int index) async {
      final bytes = await _source.read(body + index * width, width);
      final view = ByteData.sublistView(bytes);
      return width == 8
          ? view.getUint64(0, Endian.little)
          : view.getUint32(0, Endian.little);
    }

    final blobCount = await offsetAt(0) ~/ width - 1;
    if (blob < 0 || blob >= blobCount) return null;

    final from = await offsetAt(blob);
    final to = await offsetAt(blob + 1);
    return ZimBlobLocation(offset: body + from, length: to - from);
  }

  /// Entries whose title starts with [prefix], in title order.
  ///
  /// Title search, not full-text search: this finds "Wasseraufbereitung"
  /// by its name and cannot find the article that merely mentions it. The
  /// screen says so. Full text is either the index the app builds or, for
  /// archives that carry one, `XapianIndex`.
  Future<List<ZimEntry>> searchTitles(String prefix, {int limit = 25}) async {
    if (prefix.isEmpty) return const [];

    final order = await _titleOrder();
    if (order == null) return const [];

    // Wikipedia titles start with a capital and the index is sorted by
    // bytes, so a lowercase query would land past every match.
    final query = prefix[0].toUpperCase() + prefix.substring(1);

    var low = 0;
    var high = order.count - 1;
    while (low <= high) {
      final middle = (low + high) >> 1;
      final entry = await entryAt(await order.at(middle));
      if (entry.title.compareTo(query) < 0) {
        low = middle + 1;
      } else {
        high = middle - 1;
      }
    }

    final matches = <ZimEntry>[];
    for (var at = low; at < order.count && matches.length < limit; at++) {
      final entry = await entryAt(await order.at(at));
      if (!entry.title.startsWith(query)) break;
      if (entry.namespace == 'C' || entry.namespace == 'A') {
        matches.add(entry);
      }
    }
    return matches;
  }

  /// The entry the archive opens on, or null when it names none.
  ///
  /// Two ways of saying it, and the archive may use either. The well-known
  /// entry is checked first because the header field means different
  /// things in the two format versions, and reading it wrong lands on an
  /// arbitrary article rather than failing.
  Future<ZimEntry?> mainPage() async {
    final wellKnown = await findByUrl('W', 'mainPage');
    if (wellKnown != null) return resolve(wellKnown);

    final index = header.mainPage;
    if (index == null || index >= header.entryCount) return null;

    final order = await _titleOrder();
    final entryIndex = header.majorVersion == 5 && order != null
        ? await order.at(index)
        : index;
    return resolve(await entryAt(entryIndex));
  }

  /// A metadata value such as `Title`, `Language` or `Date`, or null.
  Future<String?> metadata(String name) async {
    final entry = await findByUrl('M', name);
    if (entry == null) return null;

    final resolved = await resolve(entry);
    if (resolved == null) return null;
    return utf8.decode(await readBlob(resolved), allowMalformed: true);
  }

  String mimeTypeOf(ZimEntry entry) {
    final index = entry.mimeTypeIndex;
    if (index == null || index >= _mimeTypes.length) {
      return 'application/octet-stream';
    }
    return _mimeTypes[index];
  }

  // --- Internals --------------------------------------------------------

  /// Namespace first, then URL, byte by byte — the order the index is
  /// written in. A locale-aware comparison would find the wrong entries.
  static int _compareKeys(
    String leftNamespace,
    String leftUrl,
    String rightNamespace,
    String rightUrl,
  ) {
    final namespaces = leftNamespace.compareTo(rightNamespace);
    if (namespaces != 0) return namespaces;
    return leftUrl.compareTo(rightUrl);
  }

  _TitleOrder? _titleOrderCache;
  bool _titleOrderResolved = false;

  /// How to walk the archive's entries by title.
  ///
  /// Version 6 moved the listing into an entry of its own, so it has to be
  /// read like any other blob; version 5 keeps a plain table of 32-bit
  /// indexes in the file, which can be binary-searched without loading
  /// anything at all.
  Future<_TitleOrder?> _titleOrder() async {
    if (_titleOrderResolved) return _titleOrderCache;
    _titleOrderResolved = true;

    for (final path in ['listing/titleOrdered/v1', 'listing/titleOrdered/v0']) {
      final listing = await findByUrl('X', path);
      if (listing == null || listing.isRedirect) continue;

      final bytes = await readBlob(listing);
      // Copied rather than viewed: the blob sits at an arbitrary offset
      // inside the cluster, and Uint32List needs four-byte alignment. The
      // length is rounded down so a truncated listing costs its last entry
      // rather than the whole search.
      final indexes = Uint32List.view(
        Uint8List.fromList(bytes).buffer,
        0,
        bytes.length ~/ 4,
      );
      return _titleOrderCache = _TitleOrder(
        count: indexes.length,
        at: (position) async => indexes[position],
      );
    }

    if (header.majorVersion == 5 && header.titlePointerPosition > 0) {
      return _titleOrderCache = _TitleOrder(
        count: header.entryCount,
        at: (position) async {
          final bytes = await _source.read(
            header.titlePointerPosition + position * 4,
            4,
          );
          return ByteData.sublistView(bytes).getUint32(0, Endian.little);
        },
      );
    }

    return null;
  }

  Future<Uint8List> _cluster(int number) async {
    final cached = _clusterCache[number];
    if (cached != null) {
      _clusterCache.remove(number);
      _clusterCache[number] = cached;
      return cached;
    }

    if (number >= header.clusterCount) {
      throw ZimException('no cluster $number');
    }

    final start = await _readUint64(header.clusterPointerPosition + number * 8);
    // The last cluster runs to the checksum, which is always the final
    // sixteen bytes of the file.
    final end = number + 1 < header.clusterCount
        ? await _readUint64(header.clusterPointerPosition + (number + 1) * 8)
        : header.checksumPosition;

    if (end <= start || end - start > maxClusterBytes) {
      throw const ZimException('cluster exceeds the 64 MiB memory limit');
    }
    final raw = await _source.read(start, end - start);
    final info = raw[0];
    final body = await _decompress(info & 0x0f, raw.sublist(1));

    if (body.length > maxClusterBytes) {
      throw const ZimException(
        'decoded cluster exceeds the 64 MiB memory limit',
      );
    }
    final tagged = _ClusterBody.tag(body, extended: info & 0x10 != 0);
    if (tagged.length <= clusterCacheBytes) {
      while (_clusterCache.isNotEmpty &&
          (_clusterCache.length >= _clusterCacheLimit ||
              _cachedBytes + tagged.length > clusterCacheBytes)) {
        _cachedBytes -= _clusterCache.remove(_clusterCache.keys.first)!.length;
      }
      // Another concurrent read may have completed this same cluster.
      _cachedBytes -= _clusterCache.remove(number)?.length ?? 0;
      _clusterCache[number] = tagged;
      _cachedBytes += tagged.length;
    }
    return tagged;
  }

  static Uint8List _blobFrom(Uint8List body, int blob) {
    final extended = _ClusterBody.isExtended(body);
    final data = _ClusterBody.data(body);
    final width = extended ? 8 : 4;
    final view = ByteData.sublistView(data);

    int offsetAt(int index) => extended
        ? view.getUint64(index * 8, Endian.little)
        : view.getUint32(index * 4, Endian.little);

    // The first offset is where the blobs start, so it also says how long
    // the offset table is — and therefore how many blobs there are.
    final blobCount = offsetAt(0) ~/ width - 1;
    if (blob < 0 || blob >= blobCount) {
      throw ZimException('no blob $blob in this cluster');
    }

    return Uint8List.sublistView(data, offsetAt(blob), offsetAt(blob + 1));
  }

  Future<int> _readUint64(int offset) async {
    final bytes = await _source.read(offset, 8);
    return ByteData.sublistView(bytes).getUint64(0, Endian.little);
  }

  /// Reads a directory entry, whose strings have no length and simply end
  /// at a zero byte — so the read is speculative and grows if it has to.
  Future<ZimEntry> _readEntry(int index, int offset) async {
    var window = 512;
    while (true) {
      final bytes = await _source.read(offset, window);
      final entry = _parseEntry(index, bytes);
      if (entry != null) return entry;
      if (bytes.length < window) {
        throw ZimException('entry $index runs past the end of the file');
      }
      window *= 4;
    }
  }

  /// Returns null when [bytes] stops before both strings are complete.
  static ZimEntry? _parseEntry(int index, Uint8List bytes) {
    if (bytes.length < 16) return null;
    final view = ByteData.sublistView(bytes);

    final mimeType = view.getUint16(0, Endian.little);
    final parameterLength = bytes[2];
    final namespace = String.fromCharCode(bytes[3]);

    // 0xffff marks a redirect; the two below it mark entry kinds the
    // format deprecated and no current archive writes.
    final isRedirect = mimeType == 0xffff;
    var cursor = 8;

    int? redirectIndex;
    int? clusterNumber;
    int? blobNumber;

    if (isRedirect) {
      redirectIndex = view.getUint32(cursor, Endian.little);
      cursor += 4;
    } else {
      clusterNumber = view.getUint32(cursor, Endian.little);
      blobNumber = view.getUint32(cursor + 4, Endian.little);
      cursor += 8;
    }

    final url = _readString(bytes, cursor);
    if (url == null) return null;
    cursor += url.byteLength + 1;

    final title = _readString(bytes, cursor);
    if (title == null) return null;

    return ZimEntry(
      index: index,
      namespace: namespace,
      url: url.value,
      title: title.value.isEmpty ? url.value : title.value,
      mimeTypeIndex: isRedirect ? null : mimeType,
      redirectIndex: redirectIndex,
      clusterNumber: clusterNumber,
      blobNumber: blobNumber,
      parameterLength: parameterLength,
    );
  }

  static ({String value, int byteLength})? _readString(
    Uint8List bytes,
    int from,
  ) {
    for (var at = from; at < bytes.length; at++) {
      if (bytes[at] == 0) {
        return (
          value: utf8.decode(
            Uint8List.sublistView(bytes, from, at),
            allowMalformed: true,
          ),
          byteLength: at - from,
        );
      }
    }
    return null;
  }

  /// Zero-terminated strings from [position] until an empty one.
  static Future<List<String>> _readMimeTypes(
    ByteRangeSource source,
    int position,
  ) async {
    final bytes = await source.read(position, 4096);
    final types = <String>[];

    var from = 0;
    while (from < bytes.length) {
      final end = bytes.indexOf(0, from);
      if (end < 0 || end == from) break;
      types.add(
        utf8.decode(
          Uint8List.sublistView(bytes, from, end),
          allowMalformed: true,
        ),
      );
      from = end + 1;
    }
    return types;
  }
}

/// Access to the archive's entries in title order.
class _TitleOrder {
  const _TitleOrder({required this.count, required this.at});

  final int count;

  /// The URL-order index of the entry at [position] in title order.
  final Future<int> Function(int position) at;
}

/// Keeps the "are the offsets 64-bit" flag with the decompressed body,
/// because the flag lives in the compressed cluster's first byte and the
/// cache holds only what came after it.
class _ClusterBody {
  static Uint8List tag(Uint8List body, {required bool extended}) {
    final tagged = Uint8List(body.length + 1);
    tagged[0] = extended ? 1 : 0;
    tagged.setRange(1, tagged.length, body);
    return tagged;
  }

  static bool isExtended(Uint8List tagged) => tagged[0] == 1;

  static Uint8List data(Uint8List tagged) => Uint8List.sublistView(tagged, 1);
}

/// A blob's position in the archive file, for a reader that is not this
/// one.
class ZimBlobLocation {
  const ZimBlobLocation({required this.offset, required this.length});

  /// Absolute, from the start of the file.
  final int offset;

  final int length;
}

class ZimException implements Exception {
  const ZimException(this.message);

  final String message;

  @override
  String toString() => 'ZimException: $message';
}

/// One entry in the archive: an article, an image, or a redirect to one.
class ZimEntry {
  const ZimEntry({
    required this.index,
    required this.namespace,
    required this.url,
    required this.title,
    this.mimeTypeIndex,
    this.redirectIndex,
    this.clusterNumber,
    this.blobNumber,
    this.parameterLength = 0,
  });

  /// Position in the archive's URL-ordered index.
  final int index;

  /// One character. Current archives put all content under `C`; ones from
  /// before 2020 split it into `A` for articles, `I` for images and so on.
  final String namespace;

  final String url;

  /// The entry's own title, or its URL when it has none of its own.
  final String title;

  final int? mimeTypeIndex;
  final int? redirectIndex;
  final int? clusterNumber;
  final int? blobNumber;
  final int parameterLength;

  bool get isRedirect => redirectIndex != null;
}

/// The fixed header at the start of every archive.
class ZimHeader {
  const ZimHeader({
    required this.majorVersion,
    required this.minorVersion,
    required this.entryCount,
    required this.clusterCount,
    required this.urlPointerPosition,
    required this.titlePointerPosition,
    required this.clusterPointerPosition,
    required this.mimeListPosition,
    required this.mainPage,
    required this.checksumPosition,
  });

  static const byteLength = 80;
  static const _magic = 72173914;

  final int majorVersion;
  final int minorVersion;
  final int entryCount;
  final int clusterCount;

  final int urlPointerPosition;

  /// Only meaningful in major version 5. Version 6 moved the title
  /// listing into an entry of its own under the `X` namespace.
  final int titlePointerPosition;

  final int clusterPointerPosition;
  final int mimeListPosition;

  /// Index of the entry to show first, or null when the archive names
  /// none.
  final int? mainPage;

  /// Where the archive's own checksum sits, which is also where the last
  /// cluster ends.
  final int checksumPosition;

  static ZimHeader parse(Uint8List bytes) {
    if (bytes.length < byteLength) {
      throw const ZimException('file is too short to be a ZIM archive');
    }

    final view = ByteData.sublistView(bytes);
    if (view.getUint32(0, Endian.little) != _magic) {
      throw const ZimException('not a ZIM archive');
    }

    final major = view.getUint16(4, Endian.little);
    if (major != 5 && major != 6) {
      throw ZimException('unsupported ZIM version $major');
    }

    final mainPage = view.getUint32(64, Endian.little);
    return ZimHeader(
      majorVersion: major,
      minorVersion: view.getUint16(6, Endian.little),
      entryCount: view.getUint32(24, Endian.little),
      clusterCount: view.getUint32(28, Endian.little),
      urlPointerPosition: view.getUint64(32, Endian.little),
      titlePointerPosition: view.getUint64(40, Endian.little),
      clusterPointerPosition: view.getUint64(48, Endian.little),
      mimeListPosition: view.getUint64(56, Endian.little),
      mainPage: mainPage == 0xffffffff ? null : mainPage,
      checksumPosition: view.getUint64(72, Endian.little),
    );
  }
}
