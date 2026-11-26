import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/core/app_database_providers.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_freshness.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_poll_service.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_region_store.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_sync_controller.dart';
import 'package:preppsuite_flutter/local_db/database.dart';
import 'package:preppsuite_flutter/model/household_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

/// Counts polls and holds each one open until it is released.
class _CountingPoll extends WarningPollService {
  _CountingPoll(AppDatabase database) : super(database: database);

  var polls = 0;
  Completer<void>? gate;

  /// The district each poll asked for, in order.
  final asked = <String?>[];

  @override
  Future<WarningPollResult> poll({
    required String countryCode,
    String? kreisSchluessel,
    Iterable<String> extraKreisSchluessel = const [],
  }) async {
    polls++;
    asked.add(kreisSchluessel);
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

  group('back in front (#396)', () {
    /// Back to the front after a while in the background.
    void comeBack(WidgetTester tester) {
      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
    }

    /// Writes past the open app's copy of the preferences, as the
    /// background run does from its own isolate.
    Future<void> attemptedElsewhere(DateTime at) =>
        SharedPreferencesStorePlatform.instance.setValue(
          'String',
          'flutter.warningPollLastAttempt',
          at.toUtc().toIso8601String(),
        );

    testWidgets('polls when the last attempt is older than the interval', (
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
      expect(service.polls, 1);

      // The night: the last poll was at eleven, and the device slept.
      await attemptedElsewhere(
        DateTime.now().subtract(const Duration(hours: 8)),
      );
      comeBack(tester);
      await tester.pump();
      await tester.pump();

      expect(service.polls, 2);

      keepAlive.close();
      container.dispose();
      await database.close();
    });

    testWidgets('a recent background run is enough, and its time is shown', (
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
      final status = container.listen(warningPollStatusProvider, (_, _) {});
      await tester.pump();
      expect(service.polls, 1);
      await tester.runAsync(
        () => container.read(warningPollStatusProvider.future),
      );

      final background = DateTime.now().toUtc().subtract(
        const Duration(minutes: 3),
      );
      await attemptedElsewhere(background);
      comeBack(tester);
      await tester.pump();
      await tester.pump();

      expect(service.polls, 1, reason: 'the background run polled just now');
      final shown = await tester.runAsync(
        () => container.read(warningPollStatusProvider.future),
      );
      expect(shown?.lastAttempt, background);

      status.close();
      keepAlive.close();
      container.dispose();
      await database.close();
    });
  });

  testWidgets('a changed household stops the old poll (#249)', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    final service = _CountingPoll(database);
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        warningPollServiceProvider.overrideWithValue(service),
      ],
    );
    const braunschweig = HouseholdProfile(
      id: 'h',
      name: 'Zuhause',
      countryCode: 'DE',
      regionKey: '031010000000',
    );
    // The same household after "Meine Region" moved it: a new profile.
    const muenchen = HouseholdProfile(
      id: 'h',
      name: 'Zuhause',
      countryCode: 'DE',
      regionKey: '091620000000',
    );

    final before = container.listen(
      warningSyncControllerProvider(braunschweig),
      (_, _) {},
    );
    await tester.pump();
    // The shell now shows the new profile and lets go of the old one.
    before.close();
    final after = container.listen(
      warningSyncControllerProvider(muenchen),
      (_, _) {},
    );
    await tester.pump();
    expect(service.asked, ['03101', '09162']);

    service.asked.clear();
    await tester.pump(warningForegroundPollInterval);
    await tester.pump();

    expect(
      service.asked,
      ['09162'],
      reason: 'the old region is not asked again, and nobody polls twice',
    );
    final stored = await const WarningRegionStore().load();
    expect(stored?.ownKreisSchluessel, '09162');

    after.close();
    container.dispose();
    await database.close();
  });
}
