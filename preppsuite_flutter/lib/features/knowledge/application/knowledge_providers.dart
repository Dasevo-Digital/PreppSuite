import 'dart:async' show unawaited;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/platform_storage.dart';
import '../../../core/memory_pressure_listener.dart';
import '../../maps/application/map_archive_access.dart' show openMapArchive;
import 'knowledge_index_database.dart';
import 'knowledge_indexer.dart';
import 'xapian_index.dart' show xapianAvailable;
import 'xapian_search.dart';
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
    this.library = const [],
    this.selectedId,
    this.archive,
    this.server,
    this.title,
    this.problem,
  });

  /// Every archive the device knows about, in the order they were added.
  ///
  /// They stay registered; only one is open at a time. Opening a ZIM costs
  /// a header and a mime list — switching is a moment — but each open one
  /// holds a file handle and a listening port, and a library is meant to
  /// be allowed to grow.
  final List<StoredArchive> library;

  /// Which entry of [library] is open, if any.
  final String? selectedId;

  final ZimArchive? archive;

  /// Serves the archive to the article view. Started with the archive and
  /// stopped with it.
  final ZimHttpServer? server;

  /// The archive's own title, e.g. "Wikipedia (de, alle Artikel)".
  final String? title;

  final KnowledgeProblem? problem;

  StoredArchive? get selected {
    for (final archive in library) {
      if (archive.id == selectedId) return archive;
    }
    return null;
  }

  /// What to call the open file.
  String? get label => selected?.label;

  bool get isReady => archive != null && server != null;

  /// Whether anything has been added, whether or not it opens.
  bool get isConfigured => library.isNotEmpty;

  /// Identifies the archive an index was built from.
  ///
  /// Name, entry count and cluster count together: not a checksum — that
  /// would mean reading tens of gigabytes — but enough that swapping one
  /// download for another is noticed, and an index of entry numbers is
  /// never used against the wrong file.
  String? get fingerprint {
    final header = archive?.header;
    final name = label;
    if (header == null || name == null) return null;
    return '$name|${header.entryCount}|${header.clusterCount}';
  }
}

class KnowledgeController extends AsyncNotifier<KnowledgeState> {
  static const _store = ZimStore();

  /// The archive currently open, held here rather than read back out of
  /// [state] so that closing it does not depend on the state still being
  /// readable.
  ZimArchive? _currentArchive;
  ZimHttpServer? _currentServer;

  @override
  Future<KnowledgeState> build() async {
    ref.onDispose(_closeCurrent);
    final memory = MemoryPressureListener(
      () => _currentArchive?.clearClusterCache(),
    );
    ref.onDispose(memory.dispose);

    final stored = await _store.library();
    if (stored.archives.isEmpty) return const KnowledgeState();

    // A selection that names nothing falls back to the first entry rather
    // than opening a library with nothing in it.
    final wanted = stored.archives.firstWhere(
      (archive) => archive.id == stored.selectedId,
      orElse: () => stored.archives.first,
    );

    final opened = await _open(stored.archives, wanted);
    _currentArchive = opened.archive;
    _currentServer = opened.server;
    return opened;
  }

  /// Adds the archive at [location] to the library and opens it, or
  /// explains why it cannot be opened.
  ///
  /// A rejected file leaves the library and the open archive exactly where
  /// they were — trying a second archive and failing should not cost the
  /// first one. Adding a file that is already in the library re-opens that
  /// entry rather than making a second one, so a download that is started
  /// twice does not show up twice.
  Future<KnowledgeProblem?> useArchive({
    required String location,
    required String label,
  }) async {
    final current = state.value ?? const KnowledgeState();

    final existing = _entryAt(current.library, location);
    final entry =
        existing ??
        StoredArchive(id: ZimStore.newId(), location: location, label: label);

    final library = existing == null
        ? [...current.library, entry]
        : current.library;

    return _switchTo(library, entry);
  }

  /// Opens an archive that is already in the library.
  Future<KnowledgeProblem?> select(String id) async {
    final current = state.value ?? const KnowledgeState();
    if (id == current.selectedId && current.isReady) return null;

    for (final entry in current.library) {
      if (entry.id == id) return _switchTo(current.library, entry);
    }
    return null;
  }

  /// The entry pointing at [location], or null.
  static StoredArchive? _entryAt(
    List<StoredArchive> library,
    String location,
  ) {
    for (final archive in library) {
      if (archive.location == location) return archive;
    }
    return null;
  }

  /// Takes an archive out of the library. The file itself is left alone —
  /// the app never owned it.
  ///
  /// Its full-text index is dropped, because nothing would ever reach it
  /// again and it is the largest thing the app writes.
  Future<void> remove(String id) async {
    final current = state.value ?? const KnowledgeState();
    final library = [
      for (final archive in current.library)
        if (archive.id != id) archive,
    ];
    if (library.length == current.library.length) return;

    unawaited(_discardIndexFor(id));

    if (library.isEmpty) {
      await _store.save(const [], selectedId: null);
      _closeCurrent();
      state = const AsyncData(KnowledgeState());
      return;
    }

    // Removing the open one moves to whatever is left; removing another
    // leaves the open one alone.
    if (id != current.selectedId) {
      await _store.save(library, selectedId: current.selectedId);
      state = AsyncData(
        KnowledgeState(
          library: library,
          selectedId: current.selectedId,
          archive: current.archive,
          server: current.server,
          title: current.title,
          problem: current.problem,
        ),
      );
      return;
    }

    await _switchTo(library, library.first);
  }

  /// Removes every archive from the library.
  Future<void> forget() async {
    for (final archive in state.value?.library ?? const <StoredArchive>[]) {
      unawaited(_discardIndexFor(archive.id));
    }
    await _store.save(const [], selectedId: null);
    _closeCurrent();
    state = const AsyncData(KnowledgeState());
  }

  /// Opens [entry], and only on success writes the library and swaps the
  /// open archive for it.
  Future<KnowledgeProblem?> _switchTo(
    List<StoredArchive> library,
    StoredArchive entry,
  ) async {
    final before = state.value ?? const KnowledgeState();
    final known = before.library.any((archive) => archive.id == entry.id);

    final opened = await _open(library, entry);
    if (opened.problem != null) {
      // A file being added for the first time is simply refused. One that
      // was already in the library stays in it — an unplugged disk comes
      // back, and the alternative is making the user find the file again —
      // but the archive that is open stays open, and the problem is
      // reported so the screen can say what happened.
      if (!known) return opened.problem;

      await _store.save(library, selectedId: before.selectedId);
      state = AsyncData(
        KnowledgeState(
          library: library,
          selectedId: before.selectedId,
          archive: before.archive,
          server: before.server,
          title: before.title,
          problem: opened.problem,
        ),
      );
      return opened.problem;
    }

    await _store.save(library, selectedId: entry.id);

    final previousArchive = _currentArchive;
    final previousServer = _currentServer;
    _currentArchive = opened.archive;
    _currentServer = opened.server;
    state = AsyncData(opened);

    if (previousServer != null) unawaited(previousServer.close());
    if (previousArchive != null) unawaited(previousArchive.close());
    return null;
  }

  Future<void> _discardIndexFor(String id) async {
    try {
      await KnowledgeIndexDatabase.deleteFor(id);
    } on Object {
      // An index that cannot be deleted is one nothing reaches anyway.
      // This runs unawaited, so an error escaping here would surface far
      // from anything the user did.
    }
  }

  void _closeCurrent() {
    final server = _currentServer;
    final archive = _currentArchive;
    _currentServer = null;
    _currentArchive = null;
    if (server != null) unawaited(server.close());
    if (archive != null) unawaited(archive.close());
  }

  Future<KnowledgeState> _open(
    List<StoredArchive> library,
    StoredArchive entry,
  ) async {
    ZimArchive? archive;
    ZimHttpServer? server;
    try {
      // Same reader as the map archive: a file that is never copied, read
      // in ranges, and on Android reached through the Storage Access
      // Framework rather than as a path.
      archive = await ZimArchive.open(await openMapArchive(entry.location));
      // Held in locals rather than built inline in the state, so that a
      // failure after the server is listening still has something to
      // close it by. A rejected archive used to leave its port bound.
      server = await ZimHttpServer.start(archive);

      return KnowledgeState(
        library: library,
        selectedId: entry.id,
        archive: archive,
        server: server,
        title: await archive.metadata('Title'),
      );
    } on Object {
      await server?.close();
      await archive?.close();
      return KnowledgeState(
        library: library,
        selectedId: entry.id,
        problem: KnowledgeProblem.unreadable,
      );
    }
  }
}

/// The full-text index of whichever archive is open, or null when none
/// is.
///
/// One database file per archive, named after its id. Before that they
/// shared one file and switching threw the index away — which was fine
/// while there was one archive and is not fine now that switching is the
/// point.
final knowledgeIndexDatabaseProvider = Provider<KnowledgeIndexDatabase?>((ref) {
  final id = ref.watch(
    knowledgeProvider.select((state) => state.value?.selectedId),
  );
  if (id == null) return null;

  final database = KnowledgeIndexDatabase(id);
  ref.onDispose(database.close);
  return database;
});

final knowledgeProvider =
    AsyncNotifierProvider<KnowledgeController, KnowledgeState>(
      KnowledgeController.new,
    );

/// The full-text index the open archive brings with it, or null when
/// there is none to be had.
///
/// A Kiwix archive carries the index Kiwix itself searches — a Xapian
/// database lying uncompressed inside the file — and Xapian can open one
/// from a descriptor at an offset. That turns the app's most expensive
/// operation into no operation at all: no hours of indexing, no gigabytes
/// written, and the archive's own stemmer, which is what makes
/// "Notvorraete" find "Notvorrat".
///
/// Null has four ordinary causes, and every one of them falls back to the
/// index the app builds itself:
///
///  - the native library is not in this build (only macOS carries it),
///  - the archive has no index, which is normal for a hand-built one,
///  - its index cluster is compressed, so it has no offset to open at,
///  - the file cannot be named as a path — Android reaches archives
///    through the Storage Access Framework, which needs a descriptor
///    instead.
final builtInIndexProvider = FutureProvider<XapianSearcher?>((ref) async {
  if (!xapianAvailable) return null;

  // Narrowly watched: opening a Xapian database is cheap but not free,
  // and the knowledge state changes for reasons that have nothing to do
  // with which file is open — another archive added, one removed, a
  // problem reported.
  final archive = ref.watch(
    knowledgeProvider.select((state) => state.value?.archive),
  );
  final location = ref.watch(
    knowledgeProvider.select((state) => state.value?.selected?.location),
  );
  if (archive == null || location == null) return null;

  final entry = await archive.fullTextIndexEntry();
  if (entry == null) return null;

  final where = await archive.directAccessInfo(entry);
  if (where == null) return null;

  final path = await _archivePath(location);
  if (path == null) return null;

  try {
    final searcher = await XapianSearcher.open(path, where);
    ref.onDispose(searcher.close);
    return searcher;
  } on Object {
    // A refused index is not a broken app. The archive is still open,
    // titles still search, and the indexer is still there to be asked.
    return null;
  }
});

/// The archive as a path Xapian can open, or null when there is none.
///
/// Where the app runs sandboxed the location is a bookmark rather than a
/// path, and resolving it also opens the security scope the descriptor
/// will hang on — so this is not just a lookup, and the order matters.
Future<String?> _archivePath(String location) async {
  if (!isNativeStorageHandle(location)) return location;
  return resolveStoragePath(location);
}

/// Whether a usable index exists, and how far it got.
enum KnowledgeIndexStatus {
  /// No index, or one built from a different archive.
  none,

  /// The archive carries its own, and it is open. Nothing to build and
  /// nothing to wait for — see [builtInIndexProvider].
  builtIn,

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
      status == KnowledgeIndexStatus.builtIn ||
      status == KnowledgeIndexStatus.ready ||
      status == KnowledgeIndexStatus.partial;
}

class KnowledgeIndexController extends AsyncNotifier<KnowledgeIndexState> {
  bool _cancelled = false;

  @override
  Future<KnowledgeIndexState> build() async {
    final fingerprint = ref.watch(knowledgeProvider).value?.fingerprint;
    if (fingerprint == null) return const KnowledgeIndexState();

    // An archive that brings its own index is never offered the choice of
    // building a second one. Asking someone to spend an hour on what they
    // already have would be the wrong question.
    final builtIn = await ref.watch(builtInIndexProvider.future);
    if (builtIn != null) {
      return KnowledgeIndexState(
        status: KnowledgeIndexStatus.builtIn,
        articleCount: builtIn.documentCount,
      );
    }

    final index = ref.watch(knowledgeIndexDatabaseProvider);
    if (index == null || await index.indexedArchive() != fingerprint) {
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

    final indexer = _indexerFor(archive);
    if (indexer == null) return null;

    final plan = await indexer.plan();
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
    if (indexer == null) return;

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
    await ref.read(knowledgeIndexDatabaseProvider)?.discard();
    if (!ref.mounted) return;
    state = const AsyncData(KnowledgeIndexState());
  }

  /// Null when no archive is open, which is also when there is nothing to
  /// index.
  KnowledgeIndexer? _indexerFor(ZimArchive archive) {
    final index = ref.read(knowledgeIndexDatabaseProvider);
    if (index == null) return null;
    return KnowledgeIndexer(archive: archive, index: index);
  }
}

final knowledgeIndexProvider =
    AsyncNotifierProvider<KnowledgeIndexController, KnowledgeIndexState>(
      KnowledgeIndexController.new,
    );

/// Articles whose text matches [query].
///
/// Two indexes can answer this, and the archive's own is asked first: it
/// stems, and it is already there. The one the app builds itself is the
/// fallback, for archives that carry none.
final knowledgeFullTextProvider = FutureProvider.autoDispose
    .family<List<ZimEntry>, String>((ref, query) async {
      final archive = ref.watch(knowledgeProvider).value?.archive;
      if (archive == null || query.trim().isEmpty) return const [];

      final builtIn = await ref.watch(builtInIndexProvider.future);
      if (builtIn != null) {
        final found = await builtIn.search(query.trim());
        // The index names entries by path, and a path can point at
        // something the archive no longer holds — a redirect that was
        // resolved away, an index built against a different revision.
        // Those are dropped rather than shown as a result that opens
        // nothing.
        return [
          for (final hit in found.hits)
            ?await archive.findByUrl(hit.namespace, hit.url),
        ];
      }

      final indexState = ref.watch(knowledgeIndexProvider).value;
      if (!(indexState?.isUsable ?? false)) return const [];

      final index = ref.watch(knowledgeIndexDatabaseProvider);
      if (index == null) return const [];

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
