import 'dart:convert';

import 'html_to_text.dart';
import 'knowledge_index_database.dart';
import 'zim_archive.dart';

/// Above this many articles, indexing is long enough that the user should
/// be asked rather than told.
///
/// A themed collection sits well below it and is done in minutes; a whole
/// encyclopedia is far above and is an hour or more of work on a phone.
const indexConfirmThreshold = 50000;

/// How many articles go into one transaction.
///
/// Small enough that a run killed by the system loses little, large enough
/// that SQLite is not paying for a transaction per article.
const _batchSize = 200;

/// What the indexer is doing right now.
class IndexProgress {
  const IndexProgress({
    required this.phase,
    required this.done,
    required this.total,
  });

  final IndexPhase phase;
  final int done;
  final int total;

  double get fraction => total == 0 ? 0 : (done / total).clamp(0.0, 1.0);
}

enum IndexPhase {
  /// Walking the archive's entries to find the articles and the order to
  /// read them in.
  scanning,

  /// Reading and indexing them.
  indexing,
}

/// The articles of an archive, in the order they should be read.
class IndexPlan {
  const IndexPlan(this.entryIndexes);

  /// ZIM entry indexes, ordered so each cluster is decompressed once.
  final List<int> entryIndexes;

  int get articleCount => entryIndexes.length;
}

/// Builds a full-text index over a ZIM archive.
///
/// The archive already carries one — a Xapian database — but that is a C++
/// library with no Dart binding, so this builds its own with SQLite's
/// FTS5. The trade is written down in docs/wissen-offline.md: this one has
/// to be built once, on the device, and it is worth it for a themed
/// collection long before it is worth it for the whole encyclopedia.
///
/// Runs on the main isolate, deliberately. On Android the archive is a
/// `content://` document read through a platform channel, and a plain
/// isolate cannot reach one. Every batch is an await, so the interface
/// keeps moving.
class KnowledgeIndexer {
  const KnowledgeIndexer({required this.archive, required this.index});

  final ZimArchive archive;
  final KnowledgeIndexDatabase index;

  /// Finds the articles and works out the order to read them in.
  ///
  /// Sorted by cluster and then by blob, which is the whole difference
  /// between decompressing each cluster once and decompressing it again
  /// for every article inside it. Entry order is URL order, and that is
  /// not the order they were written in.
  Future<IndexPlan> plan({
    void Function(IndexProgress)? onProgress,
    bool Function()? cancelled,
  }) async {
    final total = archive.header.entryCount;
    final targets = <({int cluster, int blob, int entry})>[];

    for (var at = 0; at < total; at++) {
      if (at % 2000 == 0) {
        if (cancelled?.call() ?? false) break;
        onProgress?.call(
          IndexProgress(phase: IndexPhase.scanning, done: at, total: total),
        );
        // Lets the interface draw between chunks of a scan that can run
        // into the millions.
        await Future<void>.delayed(Duration.zero);
      }

      final entry = await archive.entryAt(at);
      if (!_isArticle(entry)) continue;

      targets.add((
        cluster: entry.clusterNumber!,
        blob: entry.blobNumber!,
        entry: at,
      ));
    }

    targets.sort((a, b) {
      final clusters = a.cluster.compareTo(b.cluster);
      return clusters != 0 ? clusters : a.blob.compareTo(b.blob);
    });

    return IndexPlan([for (final target in targets) target.entry]);
  }

  bool _isArticle(ZimEntry entry) {
    if (entry.isRedirect) return false;
    if (entry.namespace != 'C' && entry.namespace != 'A') return false;
    if (entry.clusterNumber == null || entry.blobNumber == null) return false;

    return archive.mimeTypeOf(entry).startsWith('text/html');
  }

  /// Indexes [plan] under [fingerprint], resuming where a previous run
  /// stopped if it was over the same archive.
  ///
  /// Returns false when it was asked to stop. The index stays usable
  /// either way — a partial index answers about what it has, which is
  /// better than answering nothing until an hour has passed.
  Future<bool> run(
    IndexPlan plan, {
    required String fingerprint,
    void Function(IndexProgress)? onProgress,
    bool Function()? cancelled,
  }) async {
    final resumable =
        await index.indexedArchive() == fingerprint &&
        !await index.isComplete();
    if (!resumable) {
      await index.beginIndex(fingerprint, plan.articleCount);
    }

    final total = plan.articleCount;
    var position = resumable ? await index.progress() : 0;
    var batch = <({int entryIndex, String text})>[];

    while (position < total) {
      if (cancelled?.call() ?? false) {
        await _flush(batch, position);
        return false;
      }

      final entryIndex = plan.entryIndexes[position];
      position++;

      try {
        final entry = await archive.entryAt(entryIndex);
        final text = htmlToIndexableText(
          utf8.decode(await archive.readBlob(entry), allowMalformed: true),
        );
        if (text.isNotEmpty) {
          batch.add((entryIndex: entryIndex, text: text));
        }
      } on Object {
        // One unreadable article is not worth abandoning the index for.
        // It simply will not be findable.
      }

      if (batch.length >= _batchSize) {
        await _flush(batch, position);
        batch = [];
        onProgress?.call(
          IndexProgress(
            phase: IndexPhase.indexing,
            done: position,
            total: total,
          ),
        );
      }
    }

    await _flush(batch, position);
    await index.markComplete();
    onProgress?.call(
      IndexProgress(phase: IndexPhase.indexing, done: total, total: total),
    );
    return true;
  }

  Future<void> _flush(
    List<({int entryIndex, String text})> batch,
    int position,
  ) {
    return index.addArticles(batch, position: position);
  }
}
