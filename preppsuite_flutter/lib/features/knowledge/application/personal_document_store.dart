import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
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
  });

  final String id;
  final String location;
  final String label;
  final DateTime addedAt;

  /// `ready`, `noText`, `failed`, `tooLarge`, or `notIndexed`.
  final String indexStatus;
  final int indexedCharacters;

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
    );
  }

  PersonalDocument copyWith({String? indexStatus, int? indexedCharacters}) =>
      PersonalDocument(
        id: id,
        location: location,
        label: label,
        addedAt: addedAt,
        indexStatus: indexStatus ?? this.indexStatus,
        indexedCharacters: indexedCharacters ?? this.indexedCharacters,
      );
}

class PersonalDocumentStore {
  const PersonalDocumentStore();

  Future<List<PersonalDocument>> load() async {
    final raw = (await SharedPreferences.getInstance()).getString(
      _documentsKey,
    );
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

  Future<void> _save(List<PersonalDocument> documents) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _documentsKey,
      jsonEncode([for (final document in documents) document.toJson()]),
    );
  }
}
