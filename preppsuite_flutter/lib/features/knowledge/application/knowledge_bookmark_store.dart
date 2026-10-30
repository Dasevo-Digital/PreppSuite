import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// A small reading list. It stores which archive and which entry, never
/// the article, which remains in the user-selected offline archive.
///
/// It travels with the household and into the backup. The archive is
/// therefore named twice: by this device's id for it, and by the name the
/// archive gives itself, which is the one every device shares (#240).
class KnowledgeBookmarkStore {
  const KnowledgeBookmarkStore();
  static const _key = 'knowledgeArticleBookmarksV1';

  Future<List<KnowledgeBookmark>> load() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_key);
      if (raw == null) return const [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .map(KnowledgeBookmark.fromJson)
          .whereType<KnowledgeBookmark>()
          .toList();
    } on Object {
      return const [];
    }
  }

  Future<bool> toggle(KnowledgeBookmark bookmark) async {
    final current = await load();
    bool same(KnowledgeBookmark item) =>
        item.entryUrl == bookmark.entryUrl &&
        item.isIn(bookmark.archiveId, bookmark.archiveName);
    final exists = current.any(same);
    final updated = exists
        ? [
            for (final item in current)
              if (!same(item)) item,
          ]
        : [bookmark, ...current];
    await _save(updated);
    return !exists;
  }

  Future<bool> contains(
    String archiveId,
    String entryUrl, {
    String? archiveName,
  }) async => (await load()).any(
    (item) => item.entryUrl == entryUrl && item.isIn(archiveId, archiveName),
  );

  /// Gives [name] to the bookmarks that know archive [archiveId] by its
  /// id alone, which were all of them before 2.8.0.
  ///
  /// Only the device that set them holds that id, so only it can name
  /// them, and it does so when it opens the archive. Writes nothing when
  /// there is nothing to name: the list travels, and a write would send
  /// it again.
  Future<void> adoptArchiveName(String archiveId, String name) async {
    try {
      final current = await load();
      if (!current.any(
        (item) => item.archiveId == archiveId && item.archiveName == null,
      )) {
        return;
      }
      await _save([
        for (final item in current)
          item.archiveId == archiveId && item.archiveName == null
              ? item.withArchiveName(name)
              : item,
      ]);
    } on Object {
      // Named the next time the archive is opened.
    }
  }

  Future<void> _save(List<KnowledgeBookmark> bookmarks) async {
    await (await SharedPreferences.getInstance()).setString(
      _key,
      jsonEncode([for (final item in bookmarks) item.toJson()]),
    );
  }
}

class KnowledgeBookmark {
  const KnowledgeBookmark({
    required this.archiveId,
    required this.entryUrl,
    required this.title,
    required this.createdAt,
    this.archiveName,
  });
  final String archiveId, entryUrl, title;
  final DateTime createdAt;

  /// The archive's own `M/Name`, or null where it has none or the
  /// bookmark was set before 2.8.0.
  final String? archiveName;

  /// Whether this bookmark points into the archive known here as [id]
  /// and, where it says, as [name].
  ///
  /// The name decides wherever both sides have one. The id is drawn per
  /// device and means nothing on another; and since every device that
  /// moved up from a single archive calls it `legacy`, two of them can
  /// share an id for different archives.
  bool isIn(String? id, String? name) {
    final own = archiveName;
    if (own != null && name != null) return own == name;
    return id != null && archiveId == id;
  }

  KnowledgeBookmark withArchiveName(String name) => KnowledgeBookmark(
    archiveId: archiveId,
    entryUrl: entryUrl,
    title: title,
    createdAt: createdAt,
    archiveName: name,
  );

  Map<String, Object?> toJson() => {
    'archiveId': archiveId,
    if (archiveName != null) 'archiveName': archiveName,
    'entryUrl': entryUrl,
    'title': title,
    'createdAt': createdAt.toUtc().toIso8601String(),
  };
  static KnowledgeBookmark? fromJson(Object? value) {
    if (value is! Map) return null;
    final archiveId = value['archiveId'];
    final entryUrl = value['entryUrl'];
    final title = value['title'];
    final createdAt = DateTime.tryParse('${value['createdAt'] ?? ''}');
    final archiveName = value['archiveName'];
    if (archiveId is! String ||
        entryUrl is! String ||
        title is! String ||
        createdAt == null) {
      return null;
    }
    return KnowledgeBookmark(
      archiveId: archiveId,
      entryUrl: entryUrl,
      title: title,
      createdAt: createdAt.toLocal(),
      archiveName: archiveName is String && archiveName.isNotEmpty
          ? archiveName
          : null,
    );
  }
}
