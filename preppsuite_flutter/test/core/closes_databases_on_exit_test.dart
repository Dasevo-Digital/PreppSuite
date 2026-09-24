import 'dart:async';
import 'dart:ui' show AppExitResponse;

import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:preppsuite_flutter/core/app_database_providers.dart';
import 'package:preppsuite_flutter/core/closes_databases_on_exit.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

/// A quit was the one moment this app never cleaned up after itself.
///
/// The crash that came of it was in `sqlite3_finalize`, on a worker isolate,
/// while the VM was being taken apart — a stack with no line of this project
/// in it. What these tests hold is the part that was ours: the databases are
/// closed before the engine is allowed to go.
void main() {
  Widget underTest(
    ProviderContainer container, {
    Duration timeout = const Duration(seconds: 5),
  }) => UncontrolledProviderScope(
    container: container,
    child: ClosesDatabasesOnExit(
      timeout: timeout,
      child: const Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(),
      ),
    ),
  );

  testWidgets('closes a database that was opened', (tester) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(underTest(container));
    // Reading it is what the app does long before anybody quits; without
    // this the provider was never created and there is nothing to close.
    container.read(appDatabaseProvider);
    await database.customSelect('SELECT 1').get();

    final response = await tester.binding.handleRequestAppExit();

    expect(response, AppExitResponse.exit);
    // Asked of the real database rather than of a stub: a closed one
    // refuses to work, and that is the property the crash needed.
    await expectLater(
      database.customSelect('SELECT 1').get(),
      throwsA(isA<StateError>()),
    );
  });

  testWidgets('does not open a database in order to close it', (tester) async {
    // Reaching for a provider is how it gets created. Opening a knowledge
    // index on the way out would be a strange way to leave, and on a large
    // archive not a cheap one.
    var built = 0;
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          built++;
          return AppDatabase.forTesting(NativeDatabase.memory());
        }),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(underTest(container));
    final response = await tester.binding.handleRequestAppExit();

    expect(response, AppExitResponse.exit);
    expect(built, 0);
  });

  testWidgets('a close that hangs does not hold the quit', (tester) async {
    // An app that will not quit is a worse failure than one that quits
    // untidily, and the file survives either way.
    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(_NeverCloses())],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      underTest(container, timeout: const Duration(milliseconds: 50)),
    );
    container.read(appDatabaseProvider);

    final pending = tester.binding.handleRequestAppExit();
    await tester.pump(const Duration(milliseconds: 100));

    expect(await pending, AppExitResponse.exit);
  });
}

class _NeverCloses extends AppDatabase {
  _NeverCloses() : super.forTesting(NativeDatabase.memory());

  @override
  Future<void> close() => Completer<void>().future;
}
