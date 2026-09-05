import 'dart:async' show unawaited;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../maps/application/map_archive_access.dart' show openMapArchive;
import 'knowledge_index_database.dart';
import 'knowledge_indexer.dart';
import 'zim_archive.dart';
import 'zim_http_server.dart';
import 'zim_store.dart';

/// Why an archive cannot be used.
enum KnowledgeProblem {
  /// Missing, unreadable, or not a ZIM archive at all.
  unreadable,
}

class KnowledgeState {
  const KnowledgeState({
    this.label,
    this.archive,
    this.server,
    this.title,
    this.problem,
  });

  /// What to call the chosen file.
  final String? label;

  final ZimArchive? archive;

  /// Serves the archive to the article view. Started with the archive and
  /// stopped with it.
  final ZimHttpServer? server;

  /// The archive's own title, e.g. "Wikipedia (de, alle Artikel)".
  final String? title;

  final KnowledgeProblem? problem;

  bool get isReady => archive != null && server != null;

  bool get isConfigured => label != null;

  /// Identifies the archive an index was built from.
  ///
  /// Name, entry count and cluster count together: not a checksum — that
  /// would mean reading tens of gigabytes — but enough that swapping one
  /// download for another is noticed, and an index of entry numbers is
  /// never used against the wrong file.
  String? get fingerprint {
    final header = archive?.header;
    if (header == null || label == null) return null;
    return '$label|${header.entryCount}|${header.clusterCount}';
  }
}

class KnowledgeController extends AsyncNotifier<KnowledgeState> {
  static const _store = ZimStore();

  ZimArchive? _currentArchive;
  ZimHttpServer? _currentServer;

  @override
  Future<KnowledgeState> build() async {
    ref.onDispose(_closeCurrent);

    final stored = await _store.archive();
    if (stored == null) return const KnowledgeState();

    final opened = await _open(stored.location, stored.label);
    _currentArchive = opened.archive;
    _currentServer = opened.server;
    return opened;
  }

  /// Takes the archive at [location] into use, or explains why it cannot
  /// be. A rejected file leaves a working archive exactly where it was.
  Future<KnowledgeProblem?> useArchive({
    required String location,
    required String label,
  }) async {
    final opened = await _open(location, label);
    if (opened.problem != null) return opened.problem;

    await _store.save(location: location, label: label);

    final previousArchive = _currentArchive;
    final previousServer = _currentServer;
    _currentArchive = opened.archive;
    _currentServer = opened.server;
    state = AsyncData(opened);

    if (previousServer != null) unawaited(previousServer.close());
    if (previousArchive != null) unawaited(previousArchive.close());
    return null;
  }

  Future<void> forget() async {
    await _store.clear();
    _closeCurrent();
    state = const AsyncData(KnowledgeState());
  }

  void _closeCurrent() {
    final server = _currentServer;
    final archive = _currentArchive;
    _currentServer = null;
    _currentArchive = null;
    if (server != null) unawaited(server.close());
    if (archive != null) unawaited(archive.close());
  }

  Future<KnowledgeState> _open(String location, String label) async {
    ZimArchive? archive;
    try {
      // Same reader as the map archive: a file that is never copied, read
      // in ranges, and on Android reached through the Storage Access
      // Framework rather than as a path.
      archive = await ZimArchive.open(await openMapArchive(location));

      return KnowledgeState(
        label: label,
        archive: archive,
        server: await ZimHttpServer.start(archive),
        title: await archive.metadata('Title'),
      );
    } on Object {
      await archive?.close();
      return KnowledgeState(
        label: label,
        problem: KnowledgeProblem.unreadable,
      );
    }
  }
}

/// The full-text index, opened once and closed with the app.
final knowledgeIndexDatabaseProvider = Provider<KnowledgeIndexDatabase>((ref) {
  final database = KnowledgeIndexDatabase();
  ref.onDispose(database.close);
  return database;
});

final knowledgeProvider =
    AsyncNotifierProvider<KnowledgeController, KnowledgeState>(
      KnowledgeController.new,
    );

/// Whether a usable index exists, and how far it got.
enum KnowledgeIndexStatus {
  /// No index, or one built from a different archive.
  none,

  /// Being built right now.
  running,

  /// Stopped part-way. It answers about what it has, which beats
  /// answering nothing until the rest is done.
  partial,

  ready,
}

class KnowledgeIndexState {
  const KnowledgeIndexState({
    this.status = KnowledgeIndexStatus.none,
    this.progress,
    this.articleCount,
  });

  KnowledgeIndexState copyWith({
    KnowledgeIndexStatus? status,
    IndexProgress? progress,
    int? articleCount,
  }) {
    return KnowledgeIndexState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      articleCount: articleCount ?? this.articleCount,
    );
  }

  final KnowledgeIndexStatus status;

  /// Set while [KnowledgeIndexStatus.running].
  final IndexProgress? progress;

  /// Articles the archive holds, once counted.
  final int? articleCount;

  bool get isUsable =>
      status == KnowledgeIndexStatus.ready ||
      status == KnowledgeIndexStatus.partial;
}

class KnowledgeIndexController extends AsyncNotifier<KnowledgeIndexState> {
  bool _cancelled = false;

  @override
  Future<KnowledgeIndexState> build() async {
    final fingerprint = ref.watch(knowledgeProvider).value?.fingerprint;
    if (fingerprint == null) return const KnowledgeIndexState();

    final index = ref.watch(knowledgeIndexDatabaseProvider);
    if (await index.indexedArchive() != fingerprint) {
      return const KnowledgeIndexState();
    }

    return KnowledgeIndexState(
      status: await index.isComplete()
          ? KnowledgeIndexStatus.ready
          : KnowledgeIndexStatus.partial,
      articleCount: await index.total(),
    );
  }

  /// Counts the articles without indexing them, so the screen can say what
  /// it is about to ask for.
  Future<int?> countArticles() async {
    final archive = ref.read(knowledgeProvider).value?.archive;
    if (archive == null) return null;

    final plan = await _indexerFor(archive).plan();
    state = AsyncData(
      (state.value ?? const KnowledgeIndexState()).copyWith(
        articleCount: plan.articleCount,
      ),
    );
    return plan.articleCount;
  }

  /// Builds the index, reporting progress as it goes.
  Future<void> buildIndex() async {
    final knowledge = ref.read(knowledgeProvider).value;
    final archive = knowledge?.archive;
    final fingerprint = knowledge?.fingerprint;
    if (archive == null || fingerprint == null) return;

    _cancelled = false;
    final indexer = _indexerFor(archive);

    void report(IndexProgress progress) {
      if (!ref.mounted) return;
      state = AsyncData(
        KnowledgeIndexState(
          status: KnowledgeIndexStatus.running,
          progress: progress,
          articleCount: state.value?.articleCount,
        ),
      );
    }

    state = const AsyncData(
      KnowledgeIndexState(status: KnowledgeIndexStatus.running),
    );

    final plan = await indexer.plan(
      onProgress: report,
      cancelled: () => _cancelled,
    );
    final finished = await indexer.run(
      plan,
      fingerprint: fingerprint,
      onProgress: report,
      cancelled: () => _cancelled,
    );

    if (!ref.mounted) return;
    state = AsyncData(
      KnowledgeIndexState(
        status: finished
            ? KnowledgeIndexStatus.ready
            : KnowledgeIndexStatus.partial,
        articleCount: plan.articleCount,
      ),
    );
  }

  /// Stops after the current batch. What is already indexed stays.
  void cancel() => _cancelled = true;

  Future<void> discard() async {
    _cancelled = true;
    await ref.read(knowledgeIndexDatabaseProvider).discard();
    if (!ref.mounted) return;
    state = const AsyncData(KnowledgeIndexState());
  }

  KnowledgeIndexer _indexerFor(ZimArchive archive) => KnowledgeIndexer(
    archive: archive,
    index: ref.read(knowledgeIndexDatabaseProvider),
  );
}

final knowledgeIndexProvider =
    AsyncNotifierProvider<KnowledgeIndexController, KnowledgeIndexState>(
      KnowledgeIndexController.new,
    );

/// Articles whose text matches [query].
final knowledgeFullTextProvider = FutureProvider.autoDispose
    .family<List<ZimEntry>, String>((ref, query) async {
      final archive = ref.watch(knowledgeProvider).value?.archive;
      final indexState = ref.watch(knowledgeIndexProvider).value;
      if (archive == null || !(indexState?.isUsable ?? false)) return const [];
      if (query.trim().isEmpty) return const [];

      final index = ref.watch(knowledgeIndexDatabaseProvider);
      return [
        for (final entryIndex in await index.search(query.trim()))
          await archive.entryAt(entryIndex),
      ];
    });

/// Titles matching [query], or an empty list while nothing is configured.
final knowledgeSearchProvider = FutureProvider.autoDispose
    .family<List<ZimEntry>, String>((ref, query) async {
      final archive = ref.watch(knowledgeProvider).value?.archive;
      if (archive == null || query.trim().isEmpty) return const [];

      return archive.searchTitles(query.trim());
    });
