import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_document/pdf_document.dart';
import 'package:pdf_graphics/pdf_graphics.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/app_database_directory.dart';
import '../../../core/platform_storage.dart';
import '../../maps/application/map_archive_access.dart';
import 'knowledge_index_database.dart' show fts5QueryFor;
import 'personal_document_store.dart';

part 'personal_document_index.g.dart';

/// The derived, device-local full-text index for documents a household adds
/// itself. It deliberately has its own database: deleting the index must not
/// touch the original files or the household database.
@DriftDatabase(tables: [])
class PersonalDocumentIndex extends _$PersonalDocumentIndex {
  PersonalDocumentIndex()
    : super(
        driftDatabase(
          name: 'preppsuite_personal_documents',
          native: DriftNativeOptions(databaseDirectory: appDatabaseDirectory),
        ),
      );

  PersonalDocumentIndex.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (_) => customStatement(
      "CREATE VIRTUAL TABLE IF NOT EXISTS documents USING fts5("
      "id UNINDEXED, label, text, tokenize='unicode61 remove_diacritics 2')",
    ),
  );

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
class PersonalDocumentIndexer {
  PersonalDocumentIndexer({PersonalDocumentIndex? index})
    : _index = index ?? PersonalDocumentIndex(),
      _ownsIndex = index == null;

  static const maxDocumentBytes = 48 * 1024 * 1024;
  static const maxIndexCharacters = 4 * 1024 * 1024;

  final PersonalDocumentIndex _index;
  final bool _ownsIndex;

  Future<PersonalDocumentIndexResult> index(PersonalDocument document) async {
    try {
      final bytes = await _readBytes(document.location);
      final extracted = switch (document.extension) {
        'md' || 'markdown' => utf8.decode(bytes, allowMalformed: true),
        'epub' => _extractEpub(bytes),
        'pdf' => _extractPdf(bytes),
        _ => '',
      };
      final text = _normalise(extracted);
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
    } on _DocumentTooLarge {
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

  Future<Uint8List> _readBytes(String location) async {
    var path = location;
    if (path.startsWith('bookmark://')) {
      path = await resolveStoragePath(path) ?? path;
    }
    if (!isNativeStorageHandle(path)) {
      final file = File(path);
      if (await file.length() > maxDocumentBytes) {
        throw const _DocumentTooLarge();
      }
      return file.readAsBytes();
    }

    final source = await NativeByteRangeSource.open(path);
    final builder = BytesBuilder(copy: false);
    const chunkSize = 1024 * 1024;
    try {
      for (var offset = 0; ; offset += chunkSize) {
        final chunk = await source.read(offset, chunkSize);
        if (builder.length + chunk.length > maxDocumentBytes) {
          throw const _DocumentTooLarge();
        }
        builder.add(chunk);
        if (chunk.length < chunkSize) return builder.takeBytes();
      }
    } finally {
      await source.close();
    }
  }

  String _extractEpub(Uint8List bytes) {
    final archive = ZipDecoder().decodeBytes(bytes, verify: true);
    final buffer = StringBuffer();
    for (final file in archive.files) {
      final name = file.name.toLowerCase();
      if (!file.isFile ||
          !(name.endsWith('.xhtml') ||
              name.endsWith('.html') ||
              name.endsWith('.htm'))) {
        continue;
      }
      buffer
        ..writeln(_stripMarkup(utf8.decode(file.content, allowMalformed: true)))
        ..writeln();
      if (buffer.length >= maxIndexCharacters) break;
    }
    return buffer.toString();
  }

  String _extractPdf(Uint8List bytes) {
    final document = PdfDocument.open(bytes);
    final buffer = StringBuffer();
    for (var page = 0; page < document.pageCount; page++) {
      buffer
        ..writeln(PdfTextExtractor.extract(document, page).text)
        ..writeln();
      if (buffer.length >= maxIndexCharacters) break;
    }
    return buffer.toString();
  }

  String _normalise(String value) {
    final compact = _stripMarkup(value).replaceAll(RegExp(r'\s+'), ' ').trim();
    return compact.length <= maxIndexCharacters
        ? compact
        : compact.substring(0, maxIndexCharacters);
  }

  String _stripMarkup(String value) => value
      .replaceAll(
        RegExp(r'<script\b[^>]*>[\s\S]*?</script>', caseSensitive: false),
        '',
      )
      .replaceAll(
        RegExp(r'<style\b[^>]*>[\s\S]*?</style>', caseSensitive: false),
        '',
      )
      .replaceAll(RegExp(r'<[^>]+>'), ' ')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>');
}

class _DocumentTooLarge implements Exception {
  const _DocumentTooLarge();
}
