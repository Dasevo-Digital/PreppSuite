import 'dart:async';
import 'dart:convert';

import '../../../core/private_preferences.dart';

import 'package:uuid/uuid.dart';

import '../../../core/portable_paths.dart';
import 'document_calendar.dart';

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
    this.sourceFingerprint,
    this.recognized = false,
    this.validUntil,
    this.remindOn,
    this.reviewedOn,
    this.originalLocation = '',
  });

  final String id;
  final String location;
  final String label;
  final DateTime addedAt;

  /// Calendar dates, not instants: moving the backup to another time zone
  /// must not move a document's deadline to the previous day.
  final DateTime? validUntil;
  final DateTime? remindOn;
  final DateTime? reviewedOn;
  final String originalLocation;

  /// `ready`, `noText`, `failed`, `tooLarge`, or `notIndexed`.
  final String indexStatus;
  final int indexedCharacters;

  /// Last local scroll position in a text document. This is deliberately a
  /// pixel offset only: no passage, annotation or document text is copied
  /// into preferences merely to offer "continue reading".
  final double readerOffset;

  /// What the file looked like when its index was built, as
  /// `document_fingerprint.dart` describes it — or null for a document
  /// never indexed, or indexed before fingerprints were kept.
  final String? sourceFingerprint;

  /// Whether the indexed text came from reading the pages as images
  /// (#66) rather than from the file's own text. Said beside the
  /// document, because a recognition can leave gaps nothing reports.
  final bool recognized;

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
    'sourceFingerprint': ?sourceFingerprint,
    if (recognized) 'recognized': true,
    if (validUntil != null) 'validUntil': storeDocumentDate(validUntil!),
    if (remindOn != null) 'remindOn': storeDocumentDate(remindOn!),
    if (reviewedOn != null) 'reviewedOn': storeDocumentDate(reviewedOn!),
    if (originalLocation.isNotEmpty) 'originalLocation': originalLocation,
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
      sourceFingerprint: value['sourceFingerprint'] is String
          ? value['sourceFingerprint'] as String
          : null,
      recognized: value['recognized'] == true,
      validUntil: readDocumentDate(value['validUntil']),
      remindOn: readDocumentDate(value['remindOn']),
      reviewedOn: readDocumentDate(value['reviewedOn']),
      originalLocation: value['originalLocation'] is String
          ? value['originalLocation'] as String
          : '',
    );
  }

  PersonalDocument copyWith({
    String? indexStatus,
    int? indexedCharacters,
    double? readerOffset,
    String? sourceFingerprint,
    bool clearFingerprint = false,
    bool? recognized,
    String? location,
    DateTime? validUntil,
    DateTime? remindOn,
    DateTime? reviewedOn,
    bool clearValidUntil = false,
    bool clearRemindOn = false,
    bool clearReviewedOn = false,
    String? originalLocation,
  }) => PersonalDocument(
    id: id,
    location: location ?? this.location,
    label: label,
    addedAt: addedAt,
    indexStatus: indexStatus ?? this.indexStatus,
    indexedCharacters: indexedCharacters ?? this.indexedCharacters,
    readerOffset: readerOffset ?? this.readerOffset,
    sourceFingerprint: clearFingerprint
        ? null
        : sourceFingerprint ?? this.sourceFingerprint,
    recognized: recognized ?? this.recognized,
    validUntil: clearValidUntil ? null : validUntil ?? this.validUntil,
    remindOn: clearRemindOn ? null : remindOn ?? this.remindOn,
    reviewedOn: clearReviewedOn ? null : reviewedOn ?? this.reviewedOn,
    originalLocation: originalLocation ?? this.originalLocation,
  );
}

class PersonalDocumentStore {
  const PersonalDocumentStore();

  static Future<void>? _pending;
  static final _changes = StreamController<int>.broadcast();
  static var _revision = 0;

  static Stream<int> get changes => _changes.stream;

  /// Indexing, reading position and the deadline editor can write at once.
  /// Serialize their read/modify/write cycles so none restores an old copy
  /// of another field. A failed write must not poison later operations.
  Future<T> _mutate<T>(Future<T> Function() action) {
    final result = _pending?.then((_) => action()) ?? action();
    final queued = result.then<void>(
      (_) => _changes.add(++_revision),
      onError: (Object _, StackTrace _) {},
    );
    _pending = queued;
    unawaited(
      queued.then((_) {
        if (identical(_pending, queued)) _pending = null;
      }),
    );
    return result;
  }

  Future<List<PersonalDocument>> load() =>
      _pending?.then((_) => _read()) ?? _read();

  Future<List<PersonalDocument>> _read() async {
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
  }) => _mutate(() async {
    final documents = await _read();
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
  });

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
  ) => _mutate(() async {
    final documents = await _read();
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
  });

  Future<List<PersonalDocument>> remove(String id) => _mutate(() async {
    final updated = [
      for (final item in await _read())
        if (item.id != id) item,
    ];
    await _save(updated);
    return updated;
  });

  /// [fingerprint] is the file as it was read for this index, and is
  /// written whenever it is given; a status without one (`indexing`)
  /// keeps the previous fingerprint until the run has an answer.
  Future<List<PersonalDocument>> updateIndex(
    String id, {
    required String status,
    int characters = 0,
    String? fingerprint,

    /// Whether the text was recognised from page images (#66). Every
    /// other index run is the file's own text, so it clears the mark.
    bool recognized = false,
  }) => _mutate(() async {
    final updated = [
      for (final item in await _read())
        if (item.id == id)
          item.copyWith(
            indexStatus: status,
            indexedCharacters: characters,
            sourceFingerprint: fingerprint,
            recognized: recognized,
          )
        else
          item,
    ];
    await _save(updated);
    return updated;
  });

  Future<List<PersonalDocument>> clearIndex() => _mutate(() async {
    final updated = [
      for (final item in await _read())
        item.copyWith(
          indexStatus: 'notIndexed',
          indexedCharacters: 0,
          clearFingerprint: true,
        ),
    ];
    await _save(updated);
    return updated;
  });

  /// Points document [id] at [location], keeping everything else about
  /// it -- its index, its reading position. For a file that is still
  /// there but could no longer be reached by the old handle.
  Future<void> relocate(String id, String location) => _mutate(() async {
    final updated = [
      for (final item in await _read())
        if (item.id == id) item.copyWith(location: location) else item,
    ];
    await _save(updated);
  });

  Future<void> updateReaderOffset(String id, double offset) =>
      _mutate(() async {
        final updated = [
          for (final item in await _read())
            if (item.id == id) item.copyWith(readerOffset: offset) else item,
        ];
        await _save(updated);
      });

  Future<List<PersonalDocument>> updateDeadline(
    String id, {
    required DateTime? validUntil,
    required DateTime? remindOn,
    required DateTime? reviewedOn,
    required String originalLocation,
  }) => _mutate(() async {
    final updated = [
      for (final item in await _read())
        if (item.id == id)
          item.copyWith(
            validUntil: validUntil,
            clearValidUntil: validUntil == null,
            remindOn: remindOn,
            clearRemindOn: remindOn == null,
            reviewedOn: reviewedOn,
            clearReviewedOn: reviewedOn == null,
            originalLocation: originalLocation.trim(),
          )
        else
          item,
    ];
    await _save(updated);
    return updated;
  });

  /// Old backups have no metadata and leave a current document's dates alone.
  /// Only these four fields may come back from the encrypted file manifest.
  Future<void> restoreDeadline(PersonalDocument document, Object? raw) async {
    if (raw is! Map) return;
    await updateDeadline(
      document.id,
      validUntil: readDocumentDate(raw['validUntil']),
      remindOn: readDocumentDate(raw['remindOn']),
      reviewedOn: readDocumentDate(raw['reviewedOn']),
      originalLocation: raw['originalLocation'] is String
          ? raw['originalLocation'] as String
          : '',
    );
  }

  Future<void> _save(List<PersonalDocument> documents) async {
    await const PrivatePreferences().setString(
      _documentsKey,
      jsonEncode([for (final document in documents) document.toJson()]),
    );
  }
}
