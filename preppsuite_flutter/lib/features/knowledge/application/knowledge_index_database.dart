import 'dart:io';

import 'package:drift/drift.dart';
import '../../../core/app_database_directory.dart';
import '../../../core/local_database_encryption.dart';
import 'german_stemmer.dart';
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
  /// The schema of each derived, per-ZIM full-text index.
  static const currentSchemaVersion = 1;
  static const _compactFormat = 'fts5-terms-v2';

  KnowledgeIndexDatabase(String archiveId)
    : super(LocalDatabaseEncryption.instance.open(fileNameFor(archiveId)));

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
  /// again, and it is the largest thing the app writes. The native executor
  /// puts it in the app-private directory under the name above; the two
  /// journal files beside it go with it.
  static Future<void> deleteFor(String archiveId) async {
    final base = await _databasePath(archiveId);

    for (final path in [base, '$base-wal', '$base-shm']) {
      final file = File(path);
      if (await file.exists()) await file.delete();
    }
  }

  static Future<String> _databasePath(String archiveId) async {
    final directory = await appDatabaseDirectory();
    return '${directory.path}${Platform.pathSeparator}'
        '${fileNameFor(archiveId)}.sqlite';
  }

  @override
  int get schemaVersion => currentSchemaVersion;

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
    // `detail=none` and `columnsize=0` retain only the term-to-article map.
    // We never render FTS snippets or run phrase/NEAR queries: results are
    // opened from the archive itself. That makes a large archive's derived
    // index materially smaller without dropping ordinary word search.
    //
    // `remove_diacritics 2` so that "Notvorrate" finds "Notvorräte". There
    // is no German stemmer in SQLite, so "Vorräte" still will not find
    // "Vorrat" — see docs/wissen-offline.md.
    await customStatement(
      "CREATE VIRTUAL TABLE IF NOT EXISTS articles USING fts5("
      "text, content='', detail=none, columnsize=0, "
      "tokenize='unicode61 remove_diacritics 2')",
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

  /// Whether this was built with the compact term-only layout.
  ///
  /// Older indexes remain usable.  They are deliberately not replaced at
  /// startup, because rebuilding an encyclopedia can take a long time and is
  /// a decision the household should make explicitly.
  Future<bool> isCompact() async => await _state('format') == _compactFormat;

  /// Bytes consumed by the SQLite database and its current journal files.
  ///
  /// This is deliberately file based rather than an SQLite page estimate, so
  /// the size shown in the app matches storage the operating system reports.
  Future<int> storageBytes(String archiveId) async {
    final base = await _databasePath(archiveId);
    var bytes = 0;
    for (final path in [base, '$base-wal', '$base-shm']) {
      final file = File(path);
      if (await file.exists()) bytes += await file.length();
    }
    return bytes;
  }

  /// Which stemmer this index was built with, or null for none.
  ///
  /// Written into the index rather than worked out again at search time,
  /// because the two have to agree and there is no way to notice when
  /// they do not: a query stemmed differently than the text simply finds
  /// nothing, which reads exactly like an article that is not there.
  ///
  /// Indexes from before 0.15.0 have no such entry and answer null, which
  /// is the truth about them — they keep working unstemmed until they are
  /// rebuilt.
  Future<String?> stemmerName() => _state('stemmer');

  /// Clears everything and starts an index for [archive] over [total]
  /// articles.
  Future<void> beginIndex(
    String archive,
    int total, {
    String stemmer = 'none',
  }) async {
    await customStatement('DROP TABLE IF EXISTS articles');
    await customStatement('DELETE FROM index_state');
    await _createSchema();

    await _setState('archive', archive);
    await _setState('total', '$total');
    await _setState('position', '0');
    await _setState('complete', '0');
    await _setState('stemmer', stemmer);
    await _setState('format', _compactFormat);
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
    final expression = fts5QueryFor(
      query,
      stem: stemmerNamed(await stemmerName()),
    );
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
/// [stem] must be the same one the index was built with, or the terms
/// will not be the ones in it. Prefix search survives stemming: a stem
/// only ever loses letters from the end, so what is left is still a
/// prefix of the word that was typed.
///
/// Returns null when nothing usable is left.
String? fts5QueryFor(String query, {String Function(String)? stem}) {
  final terms = [
    for (final term in query.split(RegExp(r'[^\p{L}\p{N}]+', unicode: true)))
      if (term.isNotEmpty)
        // Lowercased only on the way into the stemmer, which is defined
        // for lowercase words. Without one the term goes in as typed:
        // FTS5 folds case itself, and an index built before there was a
        // stemmer should be queried exactly as it was.
        stem == null ? term : stem(term.toLowerCase()),
  ];
  if (terms.isEmpty) return null;

  return [
    for (var i = 0; i < terms.length; i++)
      '"${terms[i]}"${i == terms.length - 1 ? '*' : ''}',
  ].join(' ');
}
