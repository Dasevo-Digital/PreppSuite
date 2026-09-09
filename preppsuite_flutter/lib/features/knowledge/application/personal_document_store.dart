import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

const _documentsKey = 'knowledgePersonalDocuments';

class PersonalDocument {
  const PersonalDocument({
    required this.id,
    required this.location,
    required this.label,
    required this.addedAt,
  });

  final String id;
  final String location;
  final String label;
  final DateTime addedAt;

  String get extension {
    final dot = label.lastIndexOf('.');
    return dot < 0 ? '' : label.substring(dot + 1).toLowerCase();
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'location': location,
    'label': label,
    'addedAt': addedAt.toUtc().toIso8601String(),
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
      location: location,
      label: label,
      addedAt: addedAt,
    );
  }
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

  Future<void> _save(List<PersonalDocument> documents) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _documentsKey,
      jsonEncode([for (final document in documents) document.toJson()]),
    );
  }
}
