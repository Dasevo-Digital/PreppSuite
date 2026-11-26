import 'dart:io';

import 'package:drift/drift.dart';

import '../../../core/app_database_directory.dart';
import '../../../core/local_database_encryption.dart';
import '../../../core/open_databases.dart';
import 'stemmers.dart';
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

  /// How every index begun now is laid out (#391): terms with their
  /// positions, which is what lets bm25 rank.
  static const _format = 'fts5-ranked-v3';

  /// The layout of 23 September to #391: `detail=none`, much smaller and
  /// with no ranking at all. bm25 counts how often a term occurs in an
  /// article, and that layout keeps only whether it does; every rank was
  /// 0, and `ORDER BY rank LIMIT 30` gave the first thirty matches in URL
  /// order -- in a whole Wikipedia thirty early-alphabet articles that
  /// mention "Trinkwasser" somewhere, and not the article itself.
  static const _unrankedFormat = 'fts5-terms-v2';

  KnowledgeIndexDatabase(String this.archiveId)
    : super(LocalDatabaseEncryption.instance.open(fileNameFor(archiveId))) {
    OpenDatabases.track(this);
    _register();
  }

  /// [archiveId] for a test that needs [deleteFor] to find this one open.
  KnowledgeIndexDatabase.forTesting(super.executor, {this.archiveId}) {
    _register();
  }

  /// The archive this index belongs to; null only in a test.
  final String? archiveId;
  Future<void>? _closing;

  /// The index databases open in this isolate, by archive, so that one
  /// about to be deleted is closed first (#408).
  static final _open = <String, Set<KnowledgeIndexDatabase>>{};

  void _register() {
    final id = archiveId;
    if (id != null) (_open[id] ??= {}).add(this);
  }

  /// Closes once, however often it is asked: by [deleteFor] and then by
  /// the provider that opened it.
  @override
  Future<void> close() => _closing ??= _close();

  Future<void> _close() async {
    OpenDatabases.untrack(this);
    try {
      await super.close();
    } finally {
      final id = archiveId;
      final open = id == null ? null : _open[id];
      open?.remove(this);
      if (open != null && open.isEmpty) _open.remove(id);
    }
  }

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
  ///
  /// Closed first, if it is still open (#408). Windows does not delete an
  /// open file, and the index of the archive just removed was always
  /// still open: the deletion failed without a word and gigabytes stayed
  /// for good. What still cannot go is left to [deleteAllBut].
  static Future<void> deleteFor(
    String archiveId, {
    Directory? directory,
  }) async {
    for (final database in [...?_open[archiveId]]) {
      await database.close();
    }
    final base = await _databasePath(archiveId, directory: directory);

    for (final path in [base, '$base-wal', '$base-shm']) {
      final file = File(path);
      if (await file.exists()) await file.delete();
    }
  }

  /// Deletes every index whose archive is not one of [archiveIds] (#408).
  ///
  /// For what [deleteFor] could not remove -- a file Windows still held,
  /// an app ended before the deletion ran. Nothing names such an index any
  /// more, so without this it would stay as long as the app is installed.
  /// Only the index files themselves, by their exact names; none that is
  /// open, and nothing while the databases are being encrypted, which
  /// renames them. [archiveIds] is asked again for every file, so that an
  /// archive added meanwhile keeps its index.
  static Future<void> deleteAllBut(
    Set<String> Function() archiveIds, {
    Directory? directory,
  }) async {
    final encryption = LocalDatabaseEncryption.instance;
    if (encryption.isMigrating) return;
    // Where the indexes are opened. Before that is settled nothing can
    // have opened one, and there is nothing to look at.
    final Directory folder;
    if (directory != null) {
      folder = directory;
    } else if (encryption.isInitialized) {
      folder = encryption.databaseFile(fileNameFor(legacyArchiveId)).parent;
    } else {
      return;
    }
    await for (final entity in folder.list(followLinks: false)) {
      if (entity is! File) continue;
      final name = entity.uri.pathSegments.last;
      final base = _indexFile.firstMatch(name)?.group(1);
      if (base == null) continue;
      final kept = {
        for (final id in {...archiveIds(), ..._open.keys}) fileNameFor(id),
      };
      if (kept.contains(base) || LocalDatabaseEncryption.instance.isMigrating) {
        continue;
      }
      try {
        await entity.delete();
      } on FileSystemException {
        // Still held somewhere; the next start tries again.
      }
    }
  }

  /// `preppsuite_knowledge.sqlite`, `preppsuite_knowledge_<id>.sqlite`
  /// and their journals. Ids are hex (`ZimStore.newId`).
  static final _indexFile = RegExp(
    r'^(preppsuite_knowledge(?:_[0-9a-f]+)?)\.sqlite(?:-wal|-shm)?$',
  );

  static Future<String> _databasePath(
    String archiveId, {
    Directory? directory,
  }) async {
    final folder = directory ?? await appDatabaseDirectory();
    return '${folder.path}${Platform.pathSeparator}'
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
    // `columnsize=0` leaves out each article's length, which costs bm25
    // its length normalisation and nothing else: it still ranks by how
    // often and how rarely the terms occur. The positions stay
    // (`detail=full`, the default). `detail=none`, which dropped them as
    // well, ranked nothing (#391).
    //
    // `remove_diacritics 2` so that "Notvorrate" finds "Notvorräte". SQLite
    // has no stemmer for these languages; the words are stemmed in Dart on
    // the way in (stemmers.dart), so "Vorräte" finds "Vorrat" -- see
    // docs/wissen-offline.md.
    await customStatement(
      "CREATE VIRTUAL TABLE IF NOT EXISTS articles USING fts5("
      "text, content='', columnsize=0, "
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

  /// Whether this index orders its results by relevance.
  ///
  /// False only for the term-only layout of [_unrankedFormat]. Every other
  /// index ranks: the current one, and those from before that layout,
  /// which carry no format at all and keep each article's length as well.
  /// An unranked index still answers and is deliberately not replaced at
  /// startup, because rebuilding an encyclopedia can take hours and is a
  /// decision the household should make; the panel offers it.
  Future<bool> ranksResults() async =>
      await _state('format') != _unrankedFormat;

  /// Bytes consumed by the SQLite database and its current journal files.
  ///
  /// This is deliberately file based rather than an SQLite page estimate, so
  /// the size shown in the app matches storage the operating system reports.
  Future<int> storageBytes(String archiveId) => storageBytesFor(archiveId);

  /// [storageBytes] without opening the index -- for adding up every
  /// archive's at once (#26).
  static Future<int> storageBytesFor(String archiveId) async {
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
    await _setState('format', _format);
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

/// [hits] with the ones whose title is what was searched for moved to the
/// front, in bm25's order otherwise (#391).
///
/// The article called "Trinkwasser" answers "Trinkwasser" more surely than
/// any article that only says the word often, and the titles are at hand:
/// every hit is read out of the archive to be shown anyway. First the
/// titles that are exactly the query, then those that hold every word of
/// it. Words are compared as the index compares them -- lower case,
/// without accents, and through [stem], the stemmer the index was built
/// with -- so "Notvorräte" puts "Notvorrat" first.
List<T> titleMatchesFirst<T>(
  List<T> hits,
  String query, {
  required String Function(T hit) titleOf,
  String Function(String)? stem,
}) {
  List<String> words(String text) => [
    for (final word in text.toLowerCase().split(_notAWord))
      if (word.isNotEmpty) _unaccented(stem == null ? word : stem(word)),
  ];

  final terms = words(query);
  if (terms.isEmpty) return hits;

  int tier(T hit) {
    final title = words(titleOf(hit));
    if (title.join(' ') == terms.join(' ')) return 0;
    return terms.every(title.contains) ? 1 : 2;
  }

  final tiers = [for (final hit in hits) tier(hit)];
  final order = List<int>.generate(hits.length, (i) => i)
    ..sort((a, b) {
      final byTier = tiers[a].compareTo(tiers[b]);
      return byTier != 0 ? byTier : a.compareTo(b);
    });
  return [for (final i in order) hits[i]];
}

final _notAWord = RegExp(r'[^\p{L}\p{N}]+', unicode: true);

/// [word] without the accents FTS5's `remove_diacritics` drops too, for
/// the letters of the four languages the index stems.
String _unaccented(String word) {
  final out = StringBuffer();
  for (final rune in word.runes) {
    final letter = String.fromCharCode(rune);
    out.write(_plainLetters[letter] ?? letter);
  }
  return out.toString();
}

const _plainLetters = {
  'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a', //
  'ç': 'c', 'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e', //
  'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i', 'ñ': 'n', //
  'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o', //
  'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u', 'ý': 'y', 'ÿ': 'y', //
};
