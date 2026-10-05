import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/local_database_encryption.dart';
import '../../../core/open_databases.dart';
import '../../../core/platform_storage.dart';
import 'knowledge_index_database.dart' show fts5QueryFor;
import 'personal_document_store.dart';
import 'personal_document_text.dart';

export 'personal_document_text.dart';

part 'personal_document_index.g.dart';

/// The derived, device-local full-text index for documents a household adds
/// itself. It deliberately has its own database: deleting the index must not
/// touch the original files or the household database.
@DriftDatabase(tables: [])
class PersonalDocumentIndex extends _$PersonalDocumentIndex {
  /// The schema of the local PDF, EPUB and Markdown full-text index.
  static const currentSchemaVersion = 1;

  PersonalDocumentIndex()
    : super(
        LocalDatabaseEncryption.instance.open('preppsuite_personal_documents'),
      ) {
    OpenDatabases.track(this);
  }

  PersonalDocumentIndex.forTesting(super.executor);

  @override
  Future<void> close() {
    OpenDatabases.untrack(this);
    return super.close();
  }

  @override
  int get schemaVersion => currentSchemaVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (_) => customStatement(
      "CREATE VIRTUAL TABLE IF NOT EXISTS documents USING fts5("
      "id UNINDEXED, label, text, tokenize='unicode61 remove_diacritics 2')",
    ),
  );

  // Note the difference from `KnowledgeIndexDatabase`, which declares
  // `content=''` and therefore stores no text at all: it can re-read any
  // passage from the archive it indexed, because that archive is a file
  // the app put there and can open again.
  //
  // This one cannot. A personal document may live on a removable disk, or
  // behind a bookmark whose grant has lapsed, and a search result has to
  // be readable either way. So the text is kept — which means this
  // database holds, in the clear, whatever the household indexed:
  // passports, policies, medical letters.
  //
  // That is the reason `appDatabaseDirectory` marks this whole directory
  // as not-to-be-backed-up. Storing the text is a deliberate trade for
  // being able to search when the original is out of reach; letting it
  // leave the device was never part of the trade.

  Future<void> replace({
    required String id,
    required String label,
    required String text,
  }) => transaction(() async {
    await remove(id);
    await customInsert(
      'INSERT INTO documents(id, label, text) VALUES (?, ?, ?)',
      variables: [
        Variable<String>(id),
        Variable<String>(label),
        Variable<String>(text),
      ],
    );
  });

  Future<void> remove(String id) => customStatement(
    'DELETE FROM documents WHERE id = ?',
    [id],
  );

  Future<void> clear() => customStatement('DELETE FROM documents');

  Future<List<PersonalDocumentMatch>> search(String query) async {
    final expression = fts5QueryFor(query);
    if (expression == null) return const [];
    final rows = await customSelect(
      "SELECT id, label, snippet(documents, 2, '', '', ' … ', 18) AS excerpt "
      'FROM documents WHERE documents MATCH ? ORDER BY rank LIMIT 30',
      variables: [Variable<String>(expression)],
    ).get();
    return [
      for (final row in rows)
        PersonalDocumentMatch(
          id: row.read<String>('id'),
          label: row.read<String>('label'),
          excerpt: row.read<String>('excerpt'),
        ),
    ];
  }
}

class PersonalDocumentMatch {
  const PersonalDocumentMatch({
    required this.id,
    required this.label,
    required this.excerpt,
  });

  final String id;
  final String label;
  final String excerpt;
}

/// Opens a registered source document with the operating system's reader.
/// The index is deliberately independent from this: a hit can still be shown
/// while a removable disk is disconnected, but opening then simply fails.
Future<bool> openPersonalDocument(PersonalDocument document) async {
  var location = document.location;
  if (location.startsWith('bookmark://')) {
    location = await resolveStoragePath(location) ?? location;
  }
  final uri = location.startsWith('content://')
      ? Uri.parse(location)
      : Uri.file(location);
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}

final personalDocumentSearchProvider = FutureProvider.autoDispose
    .family<List<PersonalDocumentMatch>, String>((ref, query) async {
      final index = PersonalDocumentIndex();
      ref.onDispose(index.close);
      return index.search(query);
    });

enum PersonalDocumentIndexStatus { ready, noText, failed, tooLarge }

class PersonalDocumentIndexResult {
  const PersonalDocumentIndexResult(this.status, {this.characters = 0});

  final PersonalDocumentIndexStatus status;
  final int characters;
}

/// Extracts and indexes one document. Original files never enter the app
/// database; only text needed for an offline query is stored there.
///
/// The reading and the extraction are [PersonalDocumentTextJob]'s, which
/// the reader uses too, so the two can never disagree about what a
/// document says or how large it may be.
class PersonalDocumentIndexer {
  PersonalDocumentIndexer({PersonalDocumentIndex? index, int? maxBytes})
    : _index = index ?? PersonalDocumentIndex(),
      _ownsIndex = index == null,
      _maxBytes = maxBytes;

  final PersonalDocumentIndex _index;
  final bool _ownsIndex;
  final int? _maxBytes;

  Future<PersonalDocumentIndexResult> index(PersonalDocument document) async {
    try {
      final extracted = await PersonalDocumentTextJob.start(
        document,
        maxBytes: _maxBytes,
      ).result;
      final text = extracted.searchText;
      if (text.isEmpty) {
        await _index.remove(document.id);
        return const PersonalDocumentIndexResult(
          PersonalDocumentIndexStatus.noText,
        );
      }
      await _index.replace(
        id: document.id,
        label: document.label,
        text: text,
      );
      return PersonalDocumentIndexResult(
        PersonalDocumentIndexStatus.ready,
        characters: text.length,
      );
    } on PersonalDocumentTooLarge {
      await _index.remove(document.id);
      return const PersonalDocumentIndexResult(
        PersonalDocumentIndexStatus.tooLarge,
      );
    } on Object {
      await _index.remove(document.id);
      return const PersonalDocumentIndexResult(
        PersonalDocumentIndexStatus.failed,
      );
    } finally {
      if (_ownsIndex) await _index.close();
    }
  }

  Future<void> remove(String id) async {
    try {
      await _index.remove(id);
    } finally {
      if (_ownsIndex) await _index.close();
    }
  }
}
