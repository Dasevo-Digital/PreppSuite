import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_freshness.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_poll_status_store.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_providers.dart';
import 'package:preppsuite_flutter/features/warnings/presentation/warning_list_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:preppsuite_flutter/model/household_profile.dart';

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

  Future<void> pump(WidgetTester tester, WarningPollStatus status) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
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
}
