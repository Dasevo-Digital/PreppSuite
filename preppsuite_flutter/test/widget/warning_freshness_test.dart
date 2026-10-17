import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_freshness.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_poll_service.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_poll_status_store.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_providers.dart';
import 'package:preppsuite_flutter/features/warnings/presentation/warning_list_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:preppsuite_flutter/model/household_profile.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_sync_controller.dart';

import 'fake_warning_sync.dart';

/// "No warnings" is only said when the feeds were heard from lately
/// (#138).
void main() {
  final now = DateTime(2026, 5, 20, 15);

  group('freshness', () {
    test('the household feed decides, an hour is the line', () {
      WarningFreshness at(Duration ago, {String source = 'bbk'}) =>
          warningFreshness(
            WarningPollStatus(sourceComplete: {source: now.subtract(ago)}),
            countryCode: 'DE',
            now: now,
          ).freshness;
      expect(at(const Duration(minutes: 20)), WarningFreshness.current);
      expect(at(const Duration(minutes: 60)), WarningFreshness.current);
      expect(at(const Duration(minutes: 61)), WarningFreshness.stale);
      // MeteoAlarm answering does not make the German state current.
      expect(
        at(const Duration(minutes: 5), source: 'meteoalarm'),
        WarningFreshness.never,
      );
      expect(
        warningFreshness(
          const WarningPollStatus(),
          countryCode: 'DE',
          now: now,
        ).freshness,
        WarningFreshness.never,
      );
    });
  });

  Future<void> pump(
    WidgetTester tester,
    WarningPollStatus status, {
    FakeWarningSync Function(HouseholdProfile profile) sync =
        FakeWarningSync.new,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // The screen keeps the poll alive; this one fetches nothing.
          warningSyncControllerProvider.overrideWith2(sync),
          allWarningsProvider.overrideWith((ref) => Stream.value(const [])),
          warningPollStatusProvider.overrideWith((ref) async => status),
        ],
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: WarningListScreen(
            profile: HouseholdProfile(
              id: 'household-1',
              name: 'Testhaushalt',
              countryCode: 'DE',
            ),
            now: now,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('current: the time, and no warnings is no warnings', (
    tester,
  ) async {
    await pump(
      tester,
      WarningPollStatus(
        sourceComplete: {'bbk': now.subtract(const Duration(minutes: 10))},
      ),
    );
    expect(find.text('Stand: heute 14:50'), findsOneWidget);
    expect(
      find.text('Aktuell keine Warnungen für deine Region.'),
      findsOneWidget,
    );
    expect(find.text('Warnungen nicht aktuell'), findsNothing);
  });

  testWidgets('stale: said loudly, and the empty list does not reassure', (
    tester,
  ) async {
    await pump(
      tester,
      WarningPollStatus(
        sourceComplete: {'bbk': now.subtract(const Duration(hours: 26))},
      ),
    );
    expect(find.text('Warnungen nicht aktuell'), findsOneWidget);
    expect(
      find.textContaining('Radio, Sirenen und Durchsagen'),
      findsOneWidget,
    );
    expect(
      find.text('Aktuell keine Warnungen für deine Region.'),
      findsNothing,
    );
    expect(
      find.textContaining('lässt sich ohne aktuellen Abruf nicht sagen'),
      findsOneWidget,
    );
  });

  testWidgets('never: says the app has not heard anything yet', (
    tester,
  ) async {
    await pump(tester, const WarningPollStatus());
    expect(
      find.textContaining('noch keine Warnungen abgerufen'),
      findsOneWidget,
    );
  });

  group('fetching by hand (#178)', () {
    final current = WarningPollStatus(
      sourceComplete: {'bbk': now.subtract(const Duration(minutes: 10))},
    );
    FakeWarningSync? fake;
    FakeWarningSync Function(HouseholdProfile) remembering({
      WarningPollResult? result = const WarningPollResult(
        fetched: 3,
        newsworthy: [],
        retired: 0,
        complete: true,
      ),
      Object? error,
    }) =>
        (profile) =>
            fake = FakeWarningSync(profile, result: result, error: error);

    testWidgets('the button fetches and says so', (tester) async {
      await pump(tester, current, sync: remembering());

      await tester.tap(find.byTooltip('Warnungen jetzt abrufen'));
      await tester.pump();

      expect(fake!.calls, 1);
      expect(find.text('Warnungen abgerufen.'), findsOneWidget);
    });

    testWidgets('a source that did not answer is named as such', (
      tester,
    ) async {
      await pump(
        tester,
        current,
        sync: remembering(
          result: const WarningPollResult(
            fetched: 3,
            newsworthy: [],
            retired: 0,
            complete: false,
          ),
        ),
      );

      await tester.tap(find.byTooltip('Warnungen jetzt abrufen'));
      await tester.pump();

      expect(
        find.textContaining('Nicht alle Warnquellen haben geantwortet'),
        findsOneWidget,
      );
    });

    testWidgets('a failed run says that it failed', (tester) async {
      await pump(
        tester,
        current,
        sync: remembering(result: null, error: StateError('kaputt')),
      );

      await tester.tap(find.byTooltip('Warnungen jetzt abrufen'));
      await tester.pump();

      expect(find.textContaining('Abruf fehlgeschlagen'), findsOneWidget);
    });

    testWidgets('the stale card offers a fetch of its own', (tester) async {
      await pump(
        tester,
        WarningPollStatus(
          sourceComplete: {'bbk': now.subtract(const Duration(hours: 26))},
        ),
        sync: remembering(),
      );

      await tester.tap(find.text('Jetzt abrufen'));
      await tester.pump();

      expect(fake!.calls, 1);
    });
  });
}
