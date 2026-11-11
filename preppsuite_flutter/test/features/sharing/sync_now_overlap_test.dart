import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/core/app_database_providers.dart';
import 'package:preppsuite_flutter/features/sharing/application/sharing_providers.dart';
import 'package:preppsuite_flutter/local_db/database.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A run that only says when it starts and waits to be let go.
class _Controller extends SharedFolderController {
  final runs = <bool>[];
  final gates = <Completer<void>>[];

  @override
  Future<void> runSync({required bool republish}) {
    runs.add(republish);
    final gate = Completer<void>();
    gates.add(gate);
    return gate.future;
  }
}

/// The return to the app, the two-minute timer and the button could each
/// start a folder run while another was still reading the folder path:
/// two runs writing the same file, and a request to republish dropped
/// (#370).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late _Controller controller;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        sharedFolderProvider.overrideWith(_Controller.new),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await db.close();
    });
    await container.read(sharedFolderProvider.future);
    controller = container.read(sharedFolderProvider.notifier) as _Controller;
  });

  test('requests during a run are one more run after it', () async {
    final first = controller.syncNow();
    final second = controller.syncNow();
    final third = controller.syncNow();
    await pumpEventQueue();
    expect(controller.runs, hasLength(1), reason: 'never two at once');

    var secondDone = false;
    unawaited(second.then((_) => secondDone = true));
    controller.gates[0].complete();
    await first;
    await pumpEventQueue();
    expect(controller.runs, hasLength(2), reason: 'one more, not two');
    expect(secondDone, isFalse, reason: 'it waits for the run it asked for');

    controller.gates[1].complete();
    await Future.wait([second, third]);
    expect(controller.runs, hasLength(2));
  });

  test('a request to republish during a run is not dropped', () async {
    final first = controller.syncNow();
    final republish = controller.syncNow(republish: true);
    await pumpEventQueue();

    controller.gates[0].complete();
    await first;
    await pumpEventQueue();
    expect(controller.runs, [false, true]);

    controller.gates[1].complete();
    await republish;
  });

  test('leaving waits for a run that has only just started', () async {
    unawaited(controller.syncNow());
    var left = false;
    unawaited(controller.leaveFolder().then((_) => left = true));
    await pumpEventQueue();
    expect(left, isFalse);

    controller.gates[0].complete();
    await pumpEventQueue();
    expect(left, isTrue);
  });
}
