import 'dart:async' show unawaited;
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../maps/application/map_archive_access.dart' show openMapArchive;
import 'zim_archive.dart';
import 'zim_http_server.dart';
import 'zim_store.dart';

/// Why an archive cannot be used.
enum KnowledgeProblem {
  /// Missing, unreadable, or not a ZIM archive at all.
  unreadable,
}

/// Whether this platform can show an article.
///
/// The pages are real Wikipedia — stylesheets, tables, maths — so they are
/// rendered by the system's browser engine, and `webview_flutter` reaches
/// that on Android, iOS and macOS only. Searching the archive works
/// everywhere; on Linux and Windows the article is where it stops, and the
/// screen says so rather than opening an empty panel.
bool get supportsArticleView {
  if (kIsWeb) return false;
  return Platform.isAndroid || Platform.isIOS || Platform.isMacOS;
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

final knowledgeProvider =
    AsyncNotifierProvider<KnowledgeController, KnowledgeState>(
      KnowledgeController.new,
    );

/// Titles matching [query], or an empty list while nothing is configured.
final knowledgeSearchProvider = FutureProvider.autoDispose
    .family<List<ZimEntry>, String>((ref, query) async {
      final archive = ref.watch(knowledgeProvider).value?.archive;
      if (archive == null || query.trim().isEmpty) return const [];

      return archive.searchTitles(query.trim());
    });
