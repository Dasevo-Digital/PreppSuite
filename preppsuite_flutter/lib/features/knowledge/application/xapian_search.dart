import 'dart:async';
import 'dart:isolate';

import 'xapian_index.dart';
import 'zim_archive.dart' show ZimBlobLocation;

/// The archive's own full-text index, kept on an isolate of its own.
///
/// [XapianIndex] blocks: it is a binding to a C++ library, and a query
/// against thirty gigabytes of Wikipedia is not something the interface
/// can wait for. So the index lives here, behind a port, and the app
/// asks it questions the same way it asks anything else that takes time.
///
/// One index is one Xapian database, which two threads may not use at
/// once. That is why there is one isolate and why it answers one query
/// at a time — the queue is the lock.
class XapianSearcher {
  XapianSearcher._();

  Isolate? _isolate;
  late final SendPort _commands;
  final ReceivePort _replies = ReceivePort();
  final Completer<_Ready> _opened = Completer<_Ready>();
  final Map<int, Completer<XapianResults>> _pending = {};
  int _nextId = 0;
  bool _closed = false;

  late final int documentCount;

  /// The language the index was built for, or null when it names none.
  late final String? language;

  /// Opens the index inside the archive at [path].
  ///
  /// Throws [XapianException] when the archive's index cannot be read —
  /// an older format, a build without the native library, a file that
  /// moved. Every one of those is an ordinary state with a fallback
  /// behind it, so the caller catches rather than the user seeing it.
  static Future<XapianSearcher> open(
    String path,
    ZimBlobLocation location,
  ) async {
    final searcher = XapianSearcher._();
    await searcher._start(path, location);
    return searcher;
  }

  Future<void> _start(String path, ZimBlobLocation location) async {
    _replies.listen(_receive);

    // The exit and error ports are the same one on purpose: an isolate
    // that dies mid-query would otherwise leave the caller waiting for an
    // answer that is never coming.
    _isolate = await Isolate.spawn(
      _serve,
      _Boot(_replies.sendPort, path, location.offset),
      onExit: _replies.sendPort,
      onError: _replies.sendPort,
      debugName: 'xapian',
    );

    final ready = await _opened.future;
    _commands = ready.commands;
    documentCount = ready.documentCount;
    language = ready.language;
  }

  void _receive(Object? message) {
    switch (message) {
      case _Ready():
        if (!_opened.isCompleted) _opened.complete(message);
      case _Failed():
        _abort(XapianException(message.problem));
      case _Answer():
        final waiting = _pending.remove(message.id);
        if (waiting == null || waiting.isCompleted) return;
        final problem = message.problem;
        if (problem != null) {
          waiting.completeError(XapianException(problem));
        } else {
          waiting.complete(
            XapianResults(hits: message.hits, estimate: message.estimate),
          );
        }
      case null:
        // The exit port fires with null. Expected after close, and after
        // that there is nobody left to disappoint.
        if (!_closed) _abort(const XapianException('the index isolate ended'));
      case List():
        // The error port sends [description, stackTrace].
        _abort(XapianException('${message.first}'));
    }
  }

  /// Fails everything outstanding at once.
  ///
  /// Half-answering is the worse outcome: a query whose future never
  /// completes shows a spinner that never stops.
  void _abort(Object error) {
    if (!_opened.isCompleted) _opened.completeError(error);
    for (final waiting in _pending.values) {
      if (!waiting.isCompleted) waiting.completeError(error);
    }
    _pending.clear();
  }

  Future<XapianResults> search(
    String query, {
    int offset = 0,
    int limit = 25,
  }) {
    if (_closed) {
      return Future.error(const XapianException('the index is closed'));
    }
    if (query.trim().isEmpty) {
      return Future.value(const XapianResults(hits: [], estimate: 0));
    }

    final id = _nextId++;
    final waiting = Completer<XapianResults>();
    _pending[id] = waiting;
    _commands.send(_Query(id, query.trim(), offset, limit));
    return waiting.future;
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _abort(const XapianException('the index was closed'));

    // Asked to close rather than killed, so that Xapian lets go of the
    // descriptor it was handed. On macOS that descriptor is holding a
    // security scope open.
    if (_opened.isCompleted) _commands.send(const _Close());
    await Future<void>.delayed(const Duration(milliseconds: 50));
    _isolate?.kill(priority: Isolate.beforeNextEvent);
    _isolate = null;
    _replies.close();
  }
}

/// What one query came back with.
class XapianResults {
  const XapianResults({required this.hits, required this.estimate});

  final List<XapianHit> hits;

  /// Xapian's guess at how many articles match in total, which is not the
  /// same as how many were asked for.
  final int estimate;
}

// --- The isolate ------------------------------------------------------

/// Runs the index. Sequential by construction: one message at a time,
/// which is exactly what one Xapian database allows.
void _serve(_Boot boot) async {
  XapianIndex index;
  try {
    index = XapianIndex.openFile(
      boot.path,
      ZimBlobLocation(offset: boot.offset, length: 0),
    );
  } on Object catch (error) {
    boot.replies.send(_Failed('$error'));
    return;
  }

  final problem = index.problem;
  if (problem != null) {
    index.close();
    boot.replies.send(_Failed(problem));
    return;
  }

  final commands = ReceivePort();
  boot.replies.send(
    _Ready(
      commands: commands.sendPort,
      documentCount: index.documentCount,
      language: index.language,
    ),
  );

  await for (final message in commands) {
    if (message is _Close) break;
    if (message is! _Query) continue;

    try {
      final hits = index.search(
        message.query,
        offset: message.offset,
        limit: message.limit,
      );
      boot.replies.send(
        _Answer(
          id: message.id,
          hits: hits,
          estimate: index.estimatedMatches,
          problem: null,
        ),
      );
    } on Object catch (error) {
      // A query can be malformed in ways only Xapian knows about. That is
      // one query's problem, not the index's: the searcher stays open.
      boot.replies.send(
        _Answer(id: message.id, hits: const [], estimate: 0, problem: '$error'),
      );
    }
  }

  commands.close();
  index.close();
}

class _Boot {
  const _Boot(this.replies, this.path, this.offset);

  final SendPort replies;
  final String path;
  final int offset;
}

class _Ready {
  const _Ready({
    required this.commands,
    required this.documentCount,
    required this.language,
  });

  final SendPort commands;
  final int documentCount;
  final String? language;
}

class _Failed {
  const _Failed(this.problem);

  final String problem;
}

class _Query {
  const _Query(this.id, this.query, this.offset, this.limit);

  final int id;
  final String query;
  final int offset;
  final int limit;
}

class _Answer {
  const _Answer({
    required this.id,
    required this.hits,
    required this.estimate,
    required this.problem,
  });

  final int id;
  final List<XapianHit> hits;
  final int estimate;
  final String? problem;
}

class _Close {
  const _Close();
}
