import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/photo_hashes.dart';
import '../../../core/photo_vault.dart';
import 'inventory_photo_service.dart';

/// Which picture each photo file on this device holds (#376).
///
/// A row names its pictures by their SHA-256, and a file has to be opened
/// -- decrypted, then hashed -- to say which one it is. A folder sync asks
/// that of every photographed place every two minutes, so the answer is
/// kept, file by file. A file's contents never change once it is written:
/// a new picture is always a new file (see [InventoryPhotoService]), and
/// sealing a plain one in place keeps the picture. So the file's name is
/// enough to find the answer again.
///
/// Kept in the preferences rather than beside the pictures: everything in
/// the photo folder is taken for a picture and sealed at start-up. A
/// picture's hash says nothing about what is in it.
class PhotoContentIndex {
  PhotoContentIndex({this._vault = const PhotoVault(), PhotoHashStore? store})
    : _store = store ?? const PreferencesPhotoHashStore();

  /// The one the app uses, so that what one caller learns another finds.
  static final instance = PhotoContentIndex();

  final PhotoVault _vault;
  final PhotoHashStore _store;
  Map<String, String>? _known;

  Future<Map<String, String>> _loaded() async => _known ??= await _store.load();

  /// The hash of the picture in [file], or null when there is no picture
  /// this device can read there.
  Future<String?> hashOf(File file) async {
    // Asked first and without waiting: a place whose picture never arrived
    // is the common case on a device that has not been given it, and a
    // stat costs nothing.
    if (!file.existsSync()) return null;
    final known = await _loaded();
    final name = p.basename(file.path);
    final kept = known[name];
    if (kept != null) return kept;
    final bytes = await _vault.read(file);
    if (bytes == null) return null;
    final hash = await photoContentHash(bytes);
    await remember(file, hash);
    return hash;
  }

  /// A file in [directory] that holds [hash], or null.
  Future<File?> fileWith(String hash, Directory directory) async {
    final known = await _loaded();
    for (final MapEntry(key: name, value: kept) in known.entries) {
      if (kept != hash) continue;
      final file = File(p.join(directory.path, name));
      if (await file.exists()) return file;
    }
    return null;
  }

  /// Notes that [file] holds [hash], for a picture whose bytes were in
  /// hand when it was written.
  ///
  /// Kept at most every few seconds rather than on every picture: a first
  /// sync reads a few hundred of them, and writing the whole table each
  /// time grew with its square. [flush] keeps the rest; what is lost
  /// without it costs a second reading of those pictures, nothing else.
  Future<void> remember(File file, String hash) async {
    final known = await _loaded();
    final name = p.basename(file.path);
    if (known[name] == hash) return;
    known[name] = hash;
    _unsaved = true;
    final now = DateTime.now();
    final last = _savedAt;
    if (last == null || now.difference(last) >= const Duration(seconds: 5)) {
      await flush();
    }
  }

  bool _unsaved = false;
  DateTime? _savedAt;

  /// Keeps what has been learned since the last time.
  Future<void> flush() async {
    final known = _known;
    if (!_unsaved || known == null) return;
    _unsaved = false;
    _savedAt = DateTime.now();
    await _store.save(known);
  }

  /// Lets go of files that are no longer in [directory].
  Future<void> prune(Directory directory) async {
    final known = await _loaded();
    final gone = [
      for (final name in known.keys)
        if (!await File(p.join(directory.path, name)).exists()) name,
    ];
    if (gone.isNotEmpty) {
      known.removeWhere((name, _) => gone.contains(name));
      _unsaved = true;
    }
    await flush();
  }
}

/// Where [PhotoContentIndex] keeps what it has learned.
abstract interface class PhotoHashStore {
  Future<Map<String, String>> load();
  Future<void> save(Map<String, String> hashes);
}

/// The app's own: one preferences entry. A store that cannot be reached
/// costs a second reading of the pictures, nothing else.
class PreferencesPhotoHashStore implements PhotoHashStore {
  const PreferencesPhotoHashStore();

  static const _key = 'photoContentHashes.v1';

  @override
  Future<Map<String, String>> load() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_key);
      if (raw == null) return {};
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      return {
        for (final MapEntry(:key, :value) in decoded.entries)
          if (key is String && isPhotoHash(value)) key: value as String,
      };
    } on Object {
      return {};
    }
  }

  @override
  Future<void> save(Map<String, String> hashes) async {
    try {
      await (await SharedPreferences.getInstance()).setString(
        _key,
        jsonEncode(hashes),
      );
    } on Object {
      // Learned again on the next reading.
    }
  }
}

/// A store held in memory, for tests.
class MemoryPhotoHashStore implements PhotoHashStore {
  final Map<String, String> hashes = {};

  @override
  Future<Map<String, String>> load() async => {...hashes};

  @override
  Future<void> save(Map<String, String> next) async {
    hashes
      ..clear()
      ..addAll(next);
  }
}
