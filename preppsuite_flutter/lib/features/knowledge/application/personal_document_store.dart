import 'dart:convert';

import '../../../core/private_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../core/portable_paths.dart';

const _documentsKey = 'knowledgePersonalDocuments';

class PersonalDocument {
  const PersonalDocument({
    required this.id,
    required this.location,
    required this.label,
    required this.addedAt,
    this.indexStatus = 'notIndexed',
    this.indexedCharacters = 0,
    this.readerOffset = 0,
  });

  final String id;
  final String location;
  final String label;
  final DateTime addedAt;

  /// `ready`, `noText`, `failed`, `tooLarge`, or `notIndexed`.
  final String indexStatus;
  final int indexedCharacters;

  /// Last local scroll position in a text document. This is deliberately a
  /// pixel offset only: no passage, annotation or document text is copied
  /// into preferences merely to offer "continue reading".
  final double readerOffset;

  bool get isSearchable => indexStatus == 'ready';

  String get extension {
    final dot = label.lastIndexOf('.');
    return dot < 0 ? '' : label.substring(dot + 1).toLowerCase();
  }

  Map<String, Object?> toJson() => {
    'id': id,
    // Written down relative to the data folder when it is inside it, so
    // a document carried on the same disk is still found after the disk
    // comes up under another letter. See `portable_paths.dart`.
    'location': storeLocation(location),
    'label': label,
    'addedAt': addedAt.toUtc().toIso8601String(),
    'indexStatus': indexStatus,
    'indexedCharacters': indexedCharacters,
    'readerOffset': readerOffset,
  };

  static PersonalDocument? fromJson(Object? value) {
    if (value is! Map) return null;
    final id = value['id'];
    final location = value['location'];
    final label = value['label'];
    final addedAt = DateTime.tryParse('${value['addedAt'] ?? ''}');
    if (id is! String ||
        location is! String ||
        label is! String ||
        addedAt == null) {
      return null;
    }
    return PersonalDocument(
      id: id,
      location: readLocation(location),
      label: label,
      addedAt: addedAt,
      indexStatus: value['indexStatus'] is String
          ? value['indexStatus'] as String
          : 'notIndexed',
      indexedCharacters: value['indexedCharacters'] is int
          ? value['indexedCharacters'] as int
          : 0,
      readerOffset: value['readerOffset'] is num
          ? (value['readerOffset'] as num).toDouble().clamp(0, double.infinity)
          : 0,
    );
  }

  PersonalDocument copyWith({
    String? indexStatus,
    int? indexedCharacters,
    double? readerOffset,
  }) => PersonalDocument(
    id: id,
    location: location,
    label: label,
    addedAt: addedAt,
    indexStatus: indexStatus ?? this.indexStatus,
    indexedCharacters: indexedCharacters ?? this.indexedCharacters,
    readerOffset: readerOffset ?? this.readerOffset,
  );
}

class PersonalDocumentStore {
  const PersonalDocumentStore();

  Future<List<PersonalDocument>> load() async {
    final raw = await const PrivatePreferences().getString(_documentsKey);
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return [
        for (final value in decoded) ?PersonalDocument.fromJson(value),
      ];
    } on FormatException {
      return const [];
    }
  }

  Future<List<PersonalDocument>> add({
    required String location,
    required String label,
  }) async {
    final documents = await load();
    if (documents.any((document) => document.location == location)) {
      return documents;
    }
    final updated = [
      ...documents,
      PersonalDocument(
        id: const Uuid().v4(),
        location: location,
        label: label,
        addedAt: DateTime.now().toUtc(),
      ),
    ];
    await _save(updated);
    return updated;
  }

  /// Adds several at once, in one read and one write.
  ///
  /// A folder import would otherwise load and save the whole list once
  /// per file, and that list lives in the encrypted preferences — every
  /// round trip is a decrypt and an encrypt. What comes back is the whole
  /// library and, separately, only the entries that were actually new, so
  /// the caller indexes exactly those and not the ones that were already
  /// there.
  Future<({List<PersonalDocument> all, List<PersonalDocument> added})> addAll(
    List<({String location, String label})> entries,
  ) async {
    final documents = await load();
    final known = {for (final document in documents) document.location};
    final added = <PersonalDocument>[];
    for (final entry in entries) {
      if (!known.add(entry.location)) continue;
      added.add(
        PersonalDocument(
          id: const Uuid().v4(),
          location: entry.location,
          label: entry.label,
          addedAt: DateTime.now().toUtc(),
        ),
      );
    }
    if (added.isEmpty) {
      return (all: documents, added: const <PersonalDocument>[]);
    }
    final updated = [...documents, ...added];
    await _save(updated);
    return (all: updated, added: added);
  }

  Future<List<PersonalDocument>> remove(String id) async {
    final updated = [
      for (final item in await load())
        if (item.id != id) item,
    ];
    await _save(updated);
    return updated;
  }

  Future<List<PersonalDocument>> updateIndex(
    String id, {
    required String status,
    int characters = 0,
  }) async {
    final updated = [
      for (final item in await load())
        if (item.id == id)
          item.copyWith(indexStatus: status, indexedCharacters: characters)
        else
          item,
    ];
    await _save(updated);
    return updated;
  }

  Future<List<PersonalDocument>> clearIndex() async {
    final updated = [
      for (final item in await load())
        item.copyWith(indexStatus: 'notIndexed', indexedCharacters: 0),
    ];
    await _save(updated);
    return updated;
  }

  Future<void> updateReaderOffset(String id, double offset) async {
    final updated = [
      for (final item in await load())
        if (item.id == id) item.copyWith(readerOffset: offset) else item,
    ];
    await _save(updated);
  }

  Future<void> _save(List<PersonalDocument> documents) async {
    await const PrivatePreferences().setString(
      _documentsKey,
      jsonEncode([for (final document in documents) document.toJson()]),
    );
  }
}
