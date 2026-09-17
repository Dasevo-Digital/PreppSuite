import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// A small local reading list. It stores only the archive id and entry URL;
/// the article itself remains in the user-selected offline archive.
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
    final exists = current.any((item) => item.key == bookmark.key);
    final updated = exists
        ? [
            for (final item in current)
              if (item.key != bookmark.key) item,
          ]
        : [bookmark, ...current];
    await (await SharedPreferences.getInstance()).setString(
      _key,
      jsonEncode([for (final item in updated) item.toJson()]),
    );
    return !exists;
  }

  Future<bool> contains(String archiveId, String entryUrl) async =>
      (await load()).any((item) => item.key == '$archiveId::$entryUrl');
}

class KnowledgeBookmark {
  const KnowledgeBookmark({
    required this.archiveId,
    required this.entryUrl,
    required this.title,
    required this.createdAt,
  });
  final String archiveId, entryUrl, title;
  final DateTime createdAt;
  String get key => '$archiveId::$entryUrl';
  Map<String, Object?> toJson() => {
    'archiveId': archiveId,
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
    );
  }
}
