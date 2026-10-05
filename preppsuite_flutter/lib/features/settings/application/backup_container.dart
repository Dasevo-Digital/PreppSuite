/// Backup format 3: the household and every file that belongs to it, in
/// one file that is written and read a piece at a time (#114).
///
/// Formats 1 and 2 were a JSON envelope, built in memory and handed to a
/// file picker whole. That is fine for rows and settings and impossible
/// for what a household keeps beside them: a Wikipedia archive is fifty
/// gigabytes. So the files go into a container of their own, and the
/// envelope rides in it as its header -- the same map, decrypted by the
/// same code, so a format 3 backup restores its household exactly as a
/// format 2 one does.
///
/// ```text
/// file    = "PSBACKUP" u16(3) u32(len) header-json entry* "E"
/// entry   = "F" u32(index) chunk* u32(0) u32(len) trailer
/// chunk   = u32(len) bytes                 -- len > 0
/// ```
///
/// All integers little-endian. The header is the format 2 envelope plus
/// a `files` section: the list of entries, encrypted like every other
/// section. Each entry is cut into chunks of at most [backupChunkSize]
/// bytes, and its trailer -- encrypted too -- carries its index, length
/// and SHA-256, so a file that was cut short, swapped with another or
/// altered is refused rather than restored.
///
/// What is private is encrypted chunk by chunk: the photos and the
/// household's own documents. What is public is not -- the knowledge
/// archives and the map are the same bytes anybody can download, and
/// AES-GCM in pure Dart runs at a few megabytes a second, which for an
/// encyclopedia is the better part of a day. Their integrity rests on the
/// hash in the encrypted trailer instead, and which archives a household
/// keeps is only in the encrypted list.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:cryptography/dart.dart';

import '../../maps/application/pmtiles_archive.dart' show ByteRangeSource;
import '../../sharing/application/folder_crypto.dart';

/// The version a container announces after its magic.
const backupContainerVersion = 3;

/// How much of a file goes into one chunk.
const backupChunkSize = 1024 * 1024;

const _magic = 'PSBACKUP';
const _entryTag = 0x46; // F
const _endTag = 0x45; // E
const _nonceLength = 12;
const _macLength = 16;

/// The largest header a reader accepts. A household's rows are a few
/// megabytes; a length beyond this is a damaged or hostile file, and
/// believing it would mean allocating whatever it claims.
const _maxHeaderLength = 512 * 1024 * 1024;
const _maxTrailerLength = 64 * 1024;
const _maxChunkLength = backupChunkSize + _nonceLength + _macLength;

/// Whether [head] -- the first bytes of a file -- start a format 3
/// container rather than a JSON backup.
bool looksLikeBackupContainer(List<int> head) {
  if (head.length < _magic.length) return false;
  for (var i = 0; i < _magic.length; i++) {
    if (head[i] != _magic.codeUnitAt(i)) return false;
  }
  return true;
}

/// A [ByteRangeSource] over bytes already in memory -- a photo, opened
/// out of the vault, on its way into a backup.
class MemoryByteRangeSource implements ByteRangeSource {
  MemoryByteRangeSource(this.bytes);

  final Uint8List bytes;

  @override
  Future<Uint8List> read(int offset, int length) async {
    if (offset >= bytes.length) return Uint8List(0);
    final end = offset + length > bytes.length ? bytes.length : offset + length;
    return Uint8List.sublistView(bytes, offset, end);
  }

  @override
  Future<void> close() async {}
}

/// Thrown when a container is damaged, cut short or altered.
class BackupFormatException implements Exception {
  const BackupFormatException(this.message);

  final String message;

  @override
  String toString() => 'BackupFormatException: $message';
}

/// Thrown out of a long write or read that was cancelled.
class BackupCancelled implements Exception {
  const BackupCancelled();
}

/// Asked between chunks whether to stop.
class BackupCancellation {
  var _cancelled = false;

  bool get isCancelled => _cancelled;

  void cancel() => _cancelled = true;

  void check() {
    if (_cancelled) throw const BackupCancelled();
  }
}

/// Writes a container. One entry at a time, in the order the header
/// lists them.
class BackupWriter {
  BackupWriter(this._out, this._key);

  final RandomAccessFile _out;
  final FolderKey _key;

  Future<void> writeHeader(Map<String, Object?> envelope) async {
    final header = utf8.encode(jsonEncode(envelope));
    final start = BytesBuilder(copy: false)
      ..add(ascii.encode(_magic))
      ..add(_u16(backupContainerVersion))
      ..add(_u32(header.length));
    await _out.writeFrom(start.takeBytes());
    await _out.writeFrom(header);
  }

  /// Copies everything [source] holds into entry [index].
  ///
  /// Read until a read comes back empty rather than until one comes back
  /// short: that costs one read per file, and it does not depend on any
  /// source filling every buffer it is handed. [onBytes] is told how many
  /// bytes went in, for a progress bar.
  Future<void> writeEntry(
    int index,
    ByteRangeSource source, {
    required bool encrypted,
    BackupCancellation? cancellation,
    void Function(int bytes)? onBytes,
  }) async {
    await _out.writeFrom([_entryTag, ..._u32(index)]);
    final hash = const DartSha256().newHashSink();
    var offset = 0;
    var chunk = 0;
    while (true) {
      cancellation?.check();
      final clear = await source.read(offset, backupChunkSize);
      if (clear.isEmpty) break;
      hash.add(clear);
      offset += clear.length;
      final stored = encrypted
          ? await _sealChunk(clear, _key.bytes, index, chunk)
          : clear;
      await _out.writeFrom(_u32(stored.length));
      await _out.writeFrom(stored);
      chunk++;
      onBytes?.call(clear.length);
    }
    hash.close();
    await _out.writeFrom(_u32(0));

    final trailer = utf8.encode(
      await encryptForFolder(
        jsonEncode({
          'index': index,
          'size': offset,
          'sha256': base64Encode(hash.hashBytes),
        }),
        _key,
      ),
    );
    await _out.writeFrom(_u32(trailer.length));
    await _out.writeFrom(trailer);
  }

  Future<void> finish() async {
    await _out.writeFrom([_endTag]);
    await _out.flush();
  }
}

/// Reads a container front to back.
///
/// Sequential, but through a [ByteRangeSource]: skipping an entry the
/// person did not ask for jumps over its chunks instead of reading them,
/// which for an archive left out of a restore is the difference between
/// a second and an hour.
class BackupReader {
  BackupReader._(this._source, this.envelope, this._offset);

  final ByteRangeSource _source;

  /// The format 2 envelope this container carries as its header.
  final Map<String, Object?> envelope;

  int _offset;
  bool _done = false;

  /// Null when [source] is not a format 3 container.
  static Future<BackupReader?> open(ByteRangeSource source) async {
    final start = await source.read(0, _magic.length + 2 + 4);
    if (start.length < _magic.length + 6 || !looksLikeBackupContainer(start)) {
      return null;
    }
    final view = ByteData.sublistView(start);
    final version = view.getUint16(_magic.length, Endian.little);
    if (version != backupContainerVersion) {
      throw const BackupFormatException('unknown container version');
    }
    final length = view.getUint32(_magic.length + 2, Endian.little);
    if (length > _maxHeaderLength) {
      throw const BackupFormatException('header too large');
    }
    final offset = start.length;
    final header = await _readExactly(source, offset, length);
    final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(header));
    } on FormatException {
      throw const BackupFormatException('header is not JSON');
    }
    if (decoded is! Map<String, Object?>) {
      throw const BackupFormatException('header is not an object');
    }
    return BackupReader._(source, decoded, offset + length);
  }

  /// The index of the next entry, or null at the end.
  ///
  /// After this the caller has to take the entry -- [copyEntry] or
  /// [skipEntry] -- before asking for the next.
  Future<int?> nextEntry() async {
    if (_done) return null;
    final tag = await _readExactly(_source, _offset, 1);
    _offset += 1;
    if (tag[0] == _endTag) {
      _done = true;
      return null;
    }
    if (tag[0] != _entryTag) {
      throw const BackupFormatException('expected an entry');
    }
    final index = await _u32At(_offset);
    _offset += 4;
    return index;
  }

  /// Steps over the entry [nextEntry] just named, without reading it.
  Future<void> skipEntry() async {
    while (true) {
      final length = await _u32At(_offset);
      _offset += 4;
      if (length == 0) break;
      if (length > _maxChunkLength) {
        throw const BackupFormatException('chunk too large');
      }
      _offset += length;
    }
    final trailer = await _u32At(_offset);
    if (trailer > _maxTrailerLength) {
      throw const BackupFormatException('trailer too large');
    }
    _offset += 4 + trailer;
  }

  /// Hands the entry [nextEntry] just named to [write], a chunk at a
  /// time, and checks it against its trailer at the end.
  ///
  /// Returns false when the entry does not match -- a wrong length, a
  /// wrong hash, a trailer for a different entry. The caller has then
  /// written something it must throw away; nothing here can unwrite it.
  Future<bool> copyEntry(
    int index, {
    required bool encrypted,
    required FolderKey key,
    required Future<void> Function(Uint8List bytes) write,
    BackupCancellation? cancellation,
    void Function(int bytes)? onBytes,
  }) async {
    final hash = const DartSha256().newHashSink();
    var size = 0;
    var chunk = 0;
    while (true) {
      cancellation?.check();
      final length = await _u32At(_offset);
      _offset += 4;
      if (length == 0) break;
      if (length > _maxChunkLength) {
        throw const BackupFormatException('chunk too large');
      }
      final stored = await _readExactly(_source, _offset, length);
      _offset += length;
      final clear = encrypted
          ? await _openChunk(stored, key.bytes, index, chunk)
          : stored;
      if (clear == null) return false;
      hash.add(clear);
      size += clear.length;
      chunk++;
      await write(clear);
      onBytes?.call(clear.length);
    }
    hash.close();

    final trailerLength = await _u32At(_offset);
    _offset += 4;
    if (trailerLength > _maxTrailerLength) {
      throw const BackupFormatException('trailer too large');
    }
    final trailer = await _readExactly(_source, _offset, trailerLength);
    _offset += trailerLength;

    final clear = await decryptFromFolder(utf8.decode(trailer), key);
    if (clear == null) return false;
    final Object? facts;
    try {
      facts = jsonDecode(clear);
    } on FormatException {
      return false;
    }
    if (facts is! Map<String, Object?>) return false;
    return facts['index'] == index &&
        facts['size'] == size &&
        facts['sha256'] == base64Encode(hash.hashBytes);
  }

  Future<int> _u32At(int offset) async {
    final bytes = await _readExactly(_source, offset, 4);
    return ByteData.sublistView(bytes).getUint32(0, Endian.little);
  }
}

/// [length] bytes at [offset], or a [BackupFormatException] when the
/// file ends first. Read in pieces: a header of a few hundred megabytes
/// should not be one message across a platform channel.
Future<Uint8List> _readExactly(
  ByteRangeSource source,
  int offset,
  int length,
) async {
  if (length == 0) return Uint8List(0);
  final out = BytesBuilder(copy: false);
  var read = 0;
  while (read < length) {
    final want = length - read > 4 * backupChunkSize
        ? 4 * backupChunkSize
        : length - read;
    final piece = await source.read(offset + read, want);
    if (piece.isEmpty) {
      throw const BackupFormatException('file ends early');
    }
    out.add(piece);
    read += piece.length;
  }
  return out.takeBytes();
}

/// What a chunk is bound to. Without it a chunk could be moved to
/// another place in the same entry, or into another entry, and still
/// decrypt.
List<int> _aad(int index, int chunk) =>
    utf8.encode('psbackup$backupContainerVersion/$index/$chunk');

// Off the interface's isolate: a megabyte of AES-GCM in pure Dart is a
// good part of a second.
Future<Uint8List> _sealChunk(
  Uint8List clear,
  Uint8List key,
  int index,
  int chunk,
) => Isolate.run(() async {
  final algorithm = AesGcm.with256bits();
  final box = await algorithm.encrypt(
    clear,
    secretKey: SecretKey(key),
    nonce: algorithm.newNonce(),
    aad: _aad(index, chunk),
  );
  return (BytesBuilder(copy: false)
        ..add(box.nonce)
        ..add(box.cipherText)
        ..add(box.mac.bytes))
      .takeBytes();
});

Future<Uint8List?> _openChunk(
  Uint8List stored,
  Uint8List key,
  int index,
  int chunk,
) {
  if (stored.length < _nonceLength + _macLength) return Future.value(null);
  return Isolate.run(() async {
    final body = stored.length - _macLength;
    try {
      final clear = await AesGcm.with256bits().decrypt(
        SecretBox(
          Uint8List.sublistView(stored, _nonceLength, body),
          nonce: Uint8List.sublistView(stored, 0, _nonceLength),
          mac: Mac(Uint8List.sublistView(stored, body)),
        ),
        secretKey: SecretKey(key),
        aad: _aad(index, chunk),
      );
      return Uint8List.fromList(clear);
    } on SecretBoxAuthenticationError {
      return null;
    }
  });
}

Uint8List _u16(int value) =>
    Uint8List(2)..buffer.asByteData().setUint16(0, value, Endian.little);

Uint8List _u32(int value) =>
    Uint8List(4)..buffer.asByteData().setUint32(0, value, Endian.little);
