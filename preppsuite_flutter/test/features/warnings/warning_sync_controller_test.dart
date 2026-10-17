import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/core/app_database_providers.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_poll_service.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_sync_controller.dart';
import 'package:preppsuite_flutter/local_db/database.dart';
import 'package:preppsuite_flutter/model/household_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Counts polls and holds each one open until it is released.
class _CountingPoll extends WarningPollService {
  _CountingPoll(AppDatabase database) : super(database: database);

  var polls = 0;
  Completer<void>? gate;

  @override
  Future<WarningPollResult> poll({
    required String countryCode,
    String? kreisSchluessel,
    Iterable<String> extraKreisSchluessel = const [],
  }) async {
    polls++;
    await gate?.future;
    return const WarningPollResult(
      fetched: 0,
      newsworthy: [],
      retired: 0,
      complete: true,
    );
  }
}

void main() {
  const profile = HouseholdProfile(id: 'h', name: 'Zuhause', countryCode: 'DE');

  testWidgets('polls on start and every fifteen minutes while open', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    final service = _CountingPoll(database);
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        warningPollServiceProvider.overrideWithValue(service),
      ],
    );
    final keepAlive = container.listen(
      warningSyncControllerProvider(profile),
      (_, _) {},
    );

    await tester.pump();
    expect(service.polls, 1, reason: 'the first poll is at start');

    await tester.pump(warningForegroundPollInterval);
    expect(service.polls, 2);
    await tester.pump(warningForegroundPollInterval);
    expect(service.polls, 3);

    // Gone with the shell: no timer outlives it.
    keepAlive.close();
    container.dispose();
    await tester.pump(warningForegroundPollInterval * 2);
    expect(service.polls, 3);
    await database.close();
  });

  testWidgets('a tap during a running poll joins it', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    final service = _CountingPoll(database)..gate = Completer<void>();
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        warningPollServiceProvider.overrideWithValue(service),
      ],
    );
    final keepAlive = container.listen(
      warningSyncControllerProvider(profile),
      (_, _) {},
    );
    await tester.pump();
    expect(service.polls, 1);
    expect(
      container.read(warningSyncControllerProvider(profile)).isLoading,
      isTrue,
    );

    final controller = container.read(
      warningSyncControllerProvider(profile).notifier,
    );
    final first = controller.syncNow();
    final second = controller.syncNow();
    expect(service.polls, 1, reason: 'the start-up poll is still out');

    service.gate!.complete();
    final results = await Future.wait([first, second]);
    expect(results.every((r) => r?.complete == true), isTrue);
    expect(service.polls, 1);
    expect(
      container.read(warningSyncControllerProvider(profile)).hasValue,
      isTrue,
    );

    // And once it is done, the next tap is a poll of its own.
    service.gate = null;
    await controller.syncNow();
    expect(service.polls, 2);

    keepAlive.close();
    container.dispose();
    await database.close();
  });
}
