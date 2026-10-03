/// Whether a personal document is still the file its index was built from.
///
/// Documents are read where they lie and never copied (see
/// `personal_document_text.dart`), so the original can be replaced behind
/// the app's back — a newer edition of a PDF saved over the old one — and
/// the full-text search would go on finding what the old one said (#77).
///
/// The fingerprint is taken when a document is indexed and compared when
/// the library opens. It is deliberately cheap, because the library opens
/// often and a household's papers can be hundreds of megabytes: the size
/// and modification time where the platform tells them, and a SHA-256 of
/// the first and last 64 KiB. Hashing the whole file would be exact and
/// would read every byte of every document each time the screen appears.
///
/// What it can miss is a change in the middle of a file that keeps both
/// its length and its modification time, which no ordinary editor does.
/// What it can over-report is a file touched but unchanged, which costs
/// one offer to re-index — the direction to err in, since a stale index
/// answers searches with confidence.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../../../core/platform_storage.dart';
import '../../maps/application/map_archive_access.dart';

/// How much of each end is hashed.
const _window = 64 * 1024;

/// The fingerprint of the document at [location], or null when it cannot
/// be read — moved, deleted, or a permission that did not survive. A
/// document that cannot be read is not called changed: the reader says
/// so when it is opened, and that is the honest place for it.
Future<String?> documentFingerprint(String location) async {
  try {
    var path = location;
    if (path.startsWith('bookmark://')) {
      path = await resolveStoragePath(path) ?? path;
    }
    if (isNativeStorageHandle(path)) return await _nativeFingerprint(path);
    return await _fileFingerprint(File(path));
  } on Object {
    return null;
  }
}

/// Whether [stored] and [current] describe different files. False when
/// either is unknown: a document indexed before fingerprints existed, or
/// one that cannot be read right now, is not claimed to have changed.
bool documentChanged(String? stored, String? current) =>
    stored != null && current != null && stored != current;

Future<String> _fileFingerprint(File file) async {
  final stat = await file.stat();
  final size = stat.size;
  final handle = await file.open();
  try {
    final head = await handle.read(_window);
    var tail = Uint8List(0);
    if (size > _window) {
      // Overlaps the head when the file is under 128 KiB; harmless.
      await handle.setPosition(size - _window);
      tail = await handle.read(_window);
    }
    final modified = stat.modified.toUtc().millisecondsSinceEpoch ~/ 1000;
    return 'f1:$size:$modified:${await _hash([head, tail])}';
  } finally {
    await handle.close();
  }
}

/// An Android `content://` document has no size or modification time the
/// app can ask for without reading it all, so only its beginning counts.
/// Weaker, and marked as such with its own prefix so the two kinds are
/// never compared with each other.
Future<String> _nativeFingerprint(String uri) async {
  final source = await NativeByteRangeSource.open(uri);
  try {
    final head = await source.read(0, _window);
    return 'n1:${head.length}:${await _hash([head])}';
  } finally {
    await source.close();
  }
}

Future<String> _hash(List<List<int>> parts) async {
  final sink = Sha256().newHashSink();
  for (final part in parts) {
    sink.add(part);
  }
  sink.close();
  final digest = await sink.hash();
  return [
    for (final byte in digest.bytes) byte.toRadixString(16).padLeft(2, '0'),
  ].join();
}
