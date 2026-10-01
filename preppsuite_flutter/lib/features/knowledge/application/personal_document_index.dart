import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf_document/pdf_document.dart';
import 'package:pdf_graphics/pdf_graphics.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/local_database_encryption.dart';
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
  /// The schema of the local PDF, EPUB and Markdown full-text index.
  static const currentSchemaVersion = 1;

  PersonalDocumentIndex()
    : super(
        LocalDatabaseEncryption.instance.open('preppsuite_personal_documents'),
      );

  PersonalDocumentIndex.forTesting(super.executor);

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

/// Reads one personal document without copying it into app storage.
///
/// The file picker deliberately keeps the original where the person chose
/// it.  Android therefore gives us a content URI rather than a path, while
/// desktop platforms use ordinary files.  Both the indexer and the internal
/// reader use this one bounded reader so a large or malformed document cannot
/// make either feature allocate without a limit.
Future<Uint8List> readPersonalDocumentBytes(
  String location, {
  required int maxBytes,
}) async {
  var path = location;
  if (path.startsWith('bookmark://')) {
    path = await resolveStoragePath(path) ?? path;
  }
  if (!isNativeStorageHandle(path)) {
    final file = File(path);
    if (await file.length() > maxBytes) throw const _DocumentTooLarge();
    return file.readAsBytes();
  }

  final source = await NativeByteRangeSource.open(path);
  final builder = BytesBuilder(copy: false);
  const chunkSize = 1024 * 1024;
  try {
    for (var offset = 0; ; offset += chunkSize) {
      final chunk = await source.read(offset, chunkSize);
      if (builder.length + chunk.length > maxBytes) {
        throw const _DocumentTooLarge();
      }
      builder.add(chunk);
      if (chunk.length < chunkSize) return builder.takeBytes();
    }
  } finally {
    await source.close();
  }
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

  /// The largest file that is read at all — for the index and for the
  /// reader alike.
  ///
  /// This is a bound on the *file*, not on the text: of whatever comes
  /// out, only [maxIndexCharacters] is ever kept, so raising this does
  /// not make the index bigger. What it does is admit the large scanned
  /// PDFs and picture-heavy EPUBs that used to be refused outright.
  ///
  /// It is read whole, because neither the ZIP decoder nor the PDF
  /// parser can work from a stream, so this number is also the peak
  /// allocation. On a phone that is a real risk, and it is accepted
  /// knowingly: a document that will not fit is refused before a byte is
  /// read (the length is checked first), and a document that fails
  /// halfway is reported as failed rather than silently dropped.
  ///
  /// Index and reader used to differ — 48 MB against 64 MB. They are one
  /// number now, because the gap meant a document could be opened and
  /// read but never found by a search, which is the worse surprise of
  /// the two.
  static const maxDocumentBytes = 256 * 1024 * 1024;
  static const maxReaderDocumentBytes = maxDocumentBytes;

  /// How much extracted text is kept per document. Roughly two thousand
  /// printed pages; unchanged, because it was never the binding limit.
  static const maxIndexCharacters = 4 * 1024 * 1024;
  static const _maxEpubEntries = 4096;
  static const _maxEpubEntryBytes = 8 * 1024 * 1024;
  static const _maxEpubDecodedBytes = 16 * 1024 * 1024;

  final PersonalDocumentIndex _index;
  final bool _ownsIndex;

  Future<PersonalDocumentIndexResult> index(PersonalDocument document) async {
    try {
      final bytes = await readPersonalDocumentBytes(
        document.location,
        maxBytes: maxDocumentBytes,
      );
      final text = await _extractForIndex(document.extension, bytes);
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

  /// The reader's local text view for EPUB and Markdown.
  ///
  /// PDFs are rendered page for page by the PDF renderer.  EPUB and Markdown
  /// have no native renderer on every platform this app supports, so their
  /// content is drawn here as selectable, offline text.  Bounded by the same
  /// [maxDocumentBytes] as the index, so what can be read can also be found.
  static Future<String> readForReader(PersonalDocument document) async {
    final bytes = await readPersonalDocumentBytes(
      document.location,
      maxBytes: maxReaderDocumentBytes,
    );
    return _normalise(_extractText(document.extension, bytes));
  }

  static String _extractText(String extension, Uint8List bytes) =>
      switch (extension) {
        'md' || 'markdown' => utf8.decode(bytes, allowMalformed: true),
        'epub' => _extractEpub(bytes),
        'pdf' => _extractPdf(bytes),
        _ => '',
      };

  static Future<String> _extractForIndex(
    String extension,
    Uint8List bytes,
  ) async {
    final transferable = TransferableTypedData.fromList([bytes]);
    return Isolate.run(() {
      final source = transferable.materialize().asUint8List();
      return _normalise(_extractText(extension, source));
    });
  }

  static String _extractEpub(Uint8List bytes) {
    final archive = ZipDecoder().decodeBytes(bytes, verify: true);
    if (archive.files.length > _maxEpubEntries) {
      throw const _DocumentTooLarge();
    }
    final buffer = StringBuffer();
    var decodedBytes = 0;
    for (final file in archive.files) {
      final name = file.name.toLowerCase();
      if (!file.isFile ||
          !(name.endsWith('.xhtml') ||
              name.endsWith('.html') ||
              name.endsWith('.htm'))) {
        continue;
      }
      // The size in a ZIP header is only a claim, but rejecting a clearly
      // excessive one avoids starting an expensive inflate. The bounded
      // output below enforces the same limit against a forged header.
      if (file.size < 0 || file.size > _maxEpubEntryBytes) {
        throw const _DocumentTooLarge();
      }
      final content = _decodeEpubEntry(
        file,
        _maxEpubDecodedBytes - decodedBytes,
      );
      decodedBytes += content.length;
      buffer
        ..writeln(_stripMarkup(utf8.decode(content, allowMalformed: true)))
        ..writeln();
      if (buffer.length >= maxIndexCharacters) break;
    }
    return buffer.toString();
  }

  static Uint8List _decodeEpubEntry(ArchiveFile file, int remainingBytes) {
    if (remainingBytes <= 0) throw const _DocumentTooLarge();
    final output = _BoundedEpubOutput(remainingBytes);
    file.decompress(output);
    return output.getBytes();
  }

  static String _extractPdf(Uint8List bytes) {
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

  static String _normalise(String value) {
    final compact = _stripMarkup(value).replaceAll(RegExp(r'\s+'), ' ').trim();
    return compact.length <= maxIndexCharacters
        ? compact
        : compact.substring(0, maxIndexCharacters);
  }

  static String _stripMarkup(String value) => value
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

/// Archive's normal memory output grows without a ceiling. EPUBs are ZIP
/// files supplied by other people, so cap every entry while it is inflated.
class _BoundedEpubOutput extends OutputMemoryStream {
  _BoundedEpubOutput(this._limit) : super(size: 32 * 1024);

  final int _limit;

  void _reserve(int count) {
    if (count < 0 || length + count > _limit) {
      throw const _DocumentTooLarge();
    }
  }

  @override
  void writeByte(int value) {
    _reserve(1);
    super.writeByte(value);
  }

  @override
  void writeBytes(List<int> bytes, {int? length}) {
    _reserve(length ?? bytes.length);
    super.writeBytes(bytes, length: length);
  }

  @override
  void writeStream(InputStream stream) {
    _reserve(stream.length);
    super.writeStream(stream);
  }
}
