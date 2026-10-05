import 'dart:ui' show AppExitResponse;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/knowledge/application/knowledge_providers.dart';
import 'app_database_providers.dart';
import 'open_databases.dart';

/// Closes the local databases while the app is still alive.
///
/// Nothing did. `appDatabaseProvider` hands its `close` to `ref.onDispose`,
/// but a desktop quit never disposes the scope: the platform asks the
/// engine to shut down and the engine takes the Dart VM apart with the
/// widget tree still standing. What is open at that moment is not closed,
/// it is abandoned.
///
/// That matters here more than it would elsewhere, because drift keeps its
/// SQLite handles on a background isolate. Shutting that isolate down runs
/// the native finalizers, and they call `sqlite3_finalize` on whatever is
/// left while the VM is being dismantled around them. In 2.1.0 that raced
/// and segfaulted on quit — once in eight attempts, which is exactly often
/// enough to look like bad luck.
///
/// Closing here removes the path instead of narrowing it: a database that
/// was closed has no finalizers left to run.
///
/// The exit is never blocked on it. A close that hangs or throws still ends
/// in [AppExitResponse.exit] — an app that refuses to quit is a worse
/// failure than an untidy one.
class ClosesDatabasesOnExit extends ConsumerStatefulWidget {
  const ClosesDatabasesOnExit({
    super.key,
    required this.child,
    this.timeout = const Duration(seconds: 5),
  });

  final Widget child;

  /// How long the quit may wait for the databases.
  final Duration timeout;

  @override
  ConsumerState<ClosesDatabasesOnExit> createState() =>
      _ClosesDatabasesOnExitState();
}

class _ClosesDatabasesOnExitState extends ConsumerState<ClosesDatabasesOnExit> {
  late final AppLifecycleListener _listener;

  @override
  void initState() {
    super.initState();
    _listener = AppLifecycleListener(onExitRequested: _closeThenExit);
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  Future<AppExitResponse> _closeThenExit() async {
    try {
      await _closeOpenDatabases().timeout(widget.timeout);
    } on Object {
      // Leaving is what was asked for. A database that would not close in
      // five seconds will not close in ten, and the file survives either
      // way — SQLite's journal is what makes that true.
    }
    return AppExitResponse.exit;
  }

  Future<void> _closeOpenDatabases() async {
    // Read through the container rather than through `ref`: asking a
    // provider for its value creates it, and opening a knowledge index in
    // order to close it again would be a strange way to leave.
    final container = ProviderScope.containerOf(context, listen: false);

    if (container.exists(appDatabaseProvider)) {
      await container.read(appDatabaseProvider).close();
    }
    if (container.exists(knowledgeIndexDatabaseProvider)) {
      await container.read(knowledgeIndexDatabaseProvider)?.close();
    }
    // And whatever no provider holds: a search over personal documents
    // left on screen, an indexer half way through (#113).
    await OpenDatabases.closeAll();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
