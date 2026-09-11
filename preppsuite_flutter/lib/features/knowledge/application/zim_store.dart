import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

const _libraryKey = 'knowledgeArchives';
const _selectedKey = 'knowledgeSelectedArchive';

// The single archive this used to hold. Read once more, to carry an
// existing setup into the library, and then removed.
const _legacyLocationKey = 'knowledgeArchiveLocation';
const _legacyLabelKey = 'knowledgeArchiveLabel';

/// The id given to an archive carried over from the single-archive
/// version.
///
/// Fixed rather than random because the full-text index is a file named
/// after the id, and the one that already exists on the device is named
/// for no id at all. Keeping this entry recognisable is what lets that
/// index go on being used instead of being rebuilt — which for a whole
/// encyclopedia is hours of work.
const legacyArchiveId = 'legacy';

/// One ZIM archive the device knows about.
///
/// Only where the file is, never a copy of it: a Wikipedia archive is tens
/// of gigabytes.
class StoredArchive {
  const StoredArchive({
    required this.id,
    required this.location,
    required this.label,
    this.sizeBytes,
    this.entryCount,
    this.title,
    this.description,
    this.cover,
  });

  /// Stable for the life of the entry. Names this archive's index file, so
  /// it must stay filesystem-safe and must not be reused.
  final String id;

  /// A path, or on Android a `content://` URI.
  final String location;

  final String label;
  final int? sizeBytes;
  final int? entryCount;

  /// What the archive calls itself, from its own `M/Title`. The label is
  /// whatever the file happened to be named — for a download that is
  /// `wikipedia_de_all_maxi_2026-01.zim`, which is a file name and not a
  /// thing anybody would choose to read in a library.
  final String? title;

  /// The archive's own one-line description, from `M/Description`.
  final String? description;

  /// The archive's own cover, from `M/Illustration_48x48@1` — a PNG of a
  /// few kilobytes that every openZIM archive carries.
  ///
  /// Kept here rather than read on demand because showing a library
  /// means showing all of them at once, and reading one out of a file
  /// costs opening it and decompressing a cluster. Written when the
  /// archive is opened, alongside the size and the entry count.
  final Uint8List? cover;

  StoredArchive copyWith({
    int? sizeBytes,
    int? entryCount,
    String? title,
    String? description,
    Uint8List? cover,
  }) => StoredArchive(
    id: id,
    location: location,
    label: label,
    sizeBytes: sizeBytes ?? this.sizeBytes,
    entryCount: entryCount ?? this.entryCount,
    title: title ?? this.title,
    description: description ?? this.description,
    cover: cover ?? this.cover,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'location': location,
    'label': label,
    'sizeBytes': sizeBytes,
    'entryCount': entryCount,
    'title': title,
    'description': description,
    if (cover != null) 'cover': base64Encode(cover!),
  };

  static StoredArchive? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final location = json['location'];
    if (id is! String || id.isEmpty) return null;
    if (location is! String || location.isEmpty) return null;

    final label = json['label'];
    String? text(Object? value) =>
        value is String && value.trim().isNotEmpty ? value.trim() : null;

    // An entry written before covers were stored simply has none, and an
    // unreadable one is not worth losing the archive over — it comes
    // back the next time the archive is opened.
    Uint8List? cover;
    final encoded = json['cover'];
    if (encoded is String && encoded.isNotEmpty) {
      try {
        cover = base64Decode(encoded);
      } on FormatException {
        cover = null;
      }
    }

    return StoredArchive(
      id: id,
      location: location,
      label: label is String && label.isNotEmpty ? label : location,
      sizeBytes: json['sizeBytes'] is int ? json['sizeBytes'] as int : null,
      entryCount: json['entryCount'] is int ? json['entryCount'] as int : null,
      title: text(json['title']),
      description: text(json['description']),
      cover: cover,
    );
  }
}

/// Which ZIM archives this device reads, and which one is open.
class ZimStore {
  const ZimStore();

  /// The library, and the entry that was open when the app last ran.
  ///
  /// [selectedId] can name an entry that is no longer there — a removal
  /// that did not finish, a file edited by hand — so callers pick a
  /// fallback rather than trusting it.
  Future<({List<StoredArchive> archives, String? selectedId})> library() async {
    final prefs = await SharedPreferences.getInstance();

    final raw = prefs.getString(_libraryKey);
    if (raw == null) return _carryOverSingleArchive(prefs);

    final archives = <StoredArchive>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        for (final entry in decoded) {
          final archive = StoredArchive.fromJson(entry);
          if (archive != null) archives.add(archive);
        }
      }
    } on FormatException {
      // Unreadable preferences are not worth failing over: the files are
      // still on disk and can be added again.
      return (archives: const <StoredArchive>[], selectedId: null);
    }

    return (archives: archives, selectedId: prefs.getString(_selectedKey));
  }

  Future<void> save(
    List<StoredArchive> archives, {
    required String? selectedId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _libraryKey,
      jsonEncode([for (final archive in archives) archive.toJson()]),
    );
    if (selectedId == null) {
      await prefs.remove(_selectedKey);
    } else {
      await prefs.setString(_selectedKey, selectedId);
    }
  }

  /// A fresh id. Hex so it can be part of a file name anywhere.
  static String newId() {
    final random = Random.secure();
    return [
      for (var i = 0; i < 8; i++)
        random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ].join();
  }

  /// Turns the one archive the old version stored into a library of one.
  ///
  /// Runs once. The old keys go, so a device that has been through this
  /// does not come back here even if the user later removes every archive.
  Future<({List<StoredArchive> archives, String? selectedId})>
  _carryOverSingleArchive(SharedPreferences prefs) async {
    final location = prefs.getString(_legacyLocationKey);
    if (location == null || location.isEmpty) {
      return (archives: const <StoredArchive>[], selectedId: null);
    }

    final label = prefs.getString(_legacyLabelKey);
    final archive = StoredArchive(
      id: legacyArchiveId,
      location: location,
      label: label == null || label.isEmpty ? location : label,
    );

    await save([archive], selectedId: archive.id);
    await prefs.remove(_legacyLocationKey);
    await prefs.remove(_legacyLabelKey);

    return (archives: [archive], selectedId: archive.id);
  }
}
