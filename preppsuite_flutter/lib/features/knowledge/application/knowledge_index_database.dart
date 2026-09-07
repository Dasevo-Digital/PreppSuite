import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'zim_store.dart' show legacyArchiveId;

part 'knowledge_index_database.g.dart';

/// The full-text index over a ZIM archive.
///
/// A database of its own rather than a table in [AppDatabase]: it is
/// derived, it is large — gigabytes for a whole encyclopedia — and it
/// belongs to one archive. Keeping it separate means dropping it is
/// deleting a file rather than a migration.
///
/// Declared with no drift tables because there is nothing for drift to
/// generate: FTS5 is a virtual table, and the two statements below are the
/// whole schema.
@DriftDatabase(tables: [])
class KnowledgeIndexDatabase extends _$KnowledgeIndexDatabase {
  KnowledgeIndexDatabase(String archiveId)
    : super(driftDatabase(name: fileNameFor(archiveId)));

  KnowledgeIndexDatabase.forTesting(super.executor);

  /// One file per archive, so switching between them keeps both indexes.
  ///
  /// The archive carried over from the single-archive version is the
  /// exception: its index is already on disk under the unsuffixed name,
  /// and rebuilding one over a whole encyclopedia is hours. It keeps the
  /// name it has.
  static String fileNameFor(String archiveId) => archiveId == legacyArchiveId
      ? 'preppsuite_knowledge'
      : 'preppsuite_knowledge_$archiveId';

  /// Deletes the index belonging to [archiveId], for an archive that has
  /// been taken out of the library.
  ///
  /// The file rather than the contents: nothing will ever reach this index
  /// again, and it is the largest thing the app writes. `drift_flutter`
  /// puts it in the documents directory under the name above; the two
  /// journal files beside it go with it.
  static Future<void> deleteFor(String archiveId) async {
    final directory = await getApplicationDocumentsDirectory();
    final base =
        '${directory.path}${Platform.pathSeparator}'
        '${fileNameFor(archiveId)}.sqlite';

    for (final path in [base, '$base-wal', '$base-shm']) {
      final file = File(path);
      if (await file.exists()) await file.delete();
    }
  }

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration =>
      MigrationStrategy(beforeOpen: (_) => _createSchema());

  Future<void> _createSchema() async {
    // `content=''` makes this a contentless index: FTS5 stores the terms
    // and not the text. The text is still in the archive, and a copy of a
    // whole encyclopedia beside it is exactly what this feature cannot
    // afford. The trade is that snippets have to be built from the archive
    // when a result is shown.
    //
    // `remove_diacritics 2` so that "Notvorrate" finds "Notvorräte". There
    // is no German stemmer in SQLite, so "Vorräte" still will not find
    // "Vorrat" — see docs/wissen-offline.md.
    await customStatement(
      "CREATE VIRTUAL TABLE IF NOT EXISTS articles USING fts5("
      "text, content='', tokenize='unicode61 remove_diacritics 2')",
    );
    await customStatement(
      'CREATE TABLE IF NOT EXISTS index_state ('
      'key TEXT NOT NULL PRIMARY KEY, value TEXT NOT NULL)',
    );
  }

  // --- State ------------------------------------------------------------

  /// Which archive this index was built from, or null when it is empty.
  ///
  /// Compared before the index is used at all: an index built from a
  /// different file would answer with entry numbers that point at the
  /// wrong articles, which is worse than answering nothing.
  Future<String?> indexedArchive() => _state('archive');

  Future<int> progress() async =>
      int.tryParse(await _state('position') ?? '') ?? 0;

  Future<int> total() async => int.tryParse(await _state('total') ?? '') ?? 0;

  Future<bool> isComplete() async => await _state('complete') == '1';

  /// Clears everything and starts an index for [archive] over [total]
  /// articles.
  Future<void> beginIndex(String archive, int total) async {
    await customStatement('DROP TABLE IF EXISTS articles');
    await customStatement('DELETE FROM index_state');
    await _createSchema();

    await _setState('archive', archive);
    await _setState('total', '$total');
    await _setState('position', '0');
    await _setState('complete', '0');
  }

  /// Writes a batch of articles and moves the resume point.
  ///
  /// One transaction for both, so a run that is killed mid-batch resumes
  /// at a position whose articles really are in the index.
  Future<void> addArticles(
    List<({int entryIndex, String text})> articles, {
    required int position,
  }) {
    return transaction(() async {
      for (final article in articles) {
        await customInsert(
          'INSERT INTO articles(rowid, text) VALUES (?, ?)',
          variables: [
            Variable<int>(article.entryIndex),
            Variable<String>(article.text),
          ],
        );
      }
      await _setState('position', '$position');
    });
  }

  Future<void> markComplete() => _setState('complete', '1');

  Future<void> discard() async {
    await customStatement('DROP TABLE IF EXISTS articles');
    await customStatement('DELETE FROM index_state');
    await _createSchema();
  }

  // --- Searching ---------------------------------------------------------

  /// ZIM entry indexes matching [query], best first.
  ///
  /// The rowid of a row *is* the entry index, which is what makes a
  /// contentless index enough: the result is a list of places to look in
  /// the archive.
  Future<List<int>> search(String query, {int limit = 30}) async {
    final expression = fts5QueryFor(query);
    if (expression == null) return const [];

    final rows = await customSelect(
      'SELECT rowid FROM articles WHERE articles MATCH ? '
      'ORDER BY rank LIMIT ?',
      variables: [Variable<String>(expression), Variable<int>(limit)],
    ).get();

    return [for (final row in rows) row.read<int>('rowid')];
  }

  Future<String?> _state(String key) async {
    final rows = await customSelect(
      'SELECT value FROM index_state WHERE key = ?',
      variables: [Variable<String>(key)],
    ).get();
    return rows.isEmpty ? null : rows.first.read<String>('value');
  }

  Future<void> _setState(String key, String value) {
    return customInsert(
      'INSERT INTO index_state(key, value) VALUES (?, ?) '
      'ON CONFLICT(key) DO UPDATE SET value = excluded.value',
      variables: [Variable<String>(key), Variable<String>(value)],
    );
  }
}

/// Turns what someone typed into an FTS5 expression.
///
/// Quoting every term is the point: FTS5 reads bare input as a query
/// language, so a stray `"` or a word like `AND` or `NEAR` would either
/// throw or mean something the user did not ask for. The last term gets a
/// prefix star, because people search while still typing it.
///
/// Returns null when nothing usable is left.
String? fts5QueryFor(String query) {
  final terms = [
    for (final term in query.split(RegExp(r'[^\p{L}\p{N}]+', unicode: true)))
      if (term.isNotEmpty) term,
  ];
  if (terms.isEmpty) return null;

  return [
    for (var i = 0; i < terms.length; i++)
      '"${terms[i]}"${i == terms.length - 1 ? '*' : ''}',
  ].join(' ');
}
