import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/transfer/presentation/household_conflict_dialog.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';

import 'accessibility.dart';

/// The one question both roads into somebody else's household ask.
///
/// It stands alone because the QR code and the shared folder used to
/// disagree about the most irreversible step in the app: one refused, the
/// other adopted silently and mentioned it afterwards.
void main() {
  Future<HouseholdConflictChoice?> open(
    WidgetTester tester, {
    int rows = 12,
  }) async {
    HouseholdConflictChoice? answer;
    var asked = false;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: Builder(
                builder: (inner) {
                  if (!asked) {
                    asked = true;
                    WidgetsBinding.instance.addPostFrameCallback((_) async {
                      answer = await askAboutHouseholdConflict(
                        inner,
                        mine: 'Familie Muster',
                        rows: rows,
                      );
                    });
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return answer;
  }

  testWidgets('it says it cannot be undone, before anything happens', (
    tester,
  ) async {
    await open(tester);

    expect(find.text('Zwei verschiedene Haushalte'), findsOneWidget);
    expect(find.textContaining('nicht rückgängig'), findsOneWidget);
    expect(find.textContaining('Familie Muster'), findsOneWidget);
  });

  testWidgets('each answer names what it costs, with the count', (
    tester,
  ) async {
    await open(tester, rows: 12);

    // Merging is the one that loses nothing, and says so.
    expect(
      find.textContaining('Die 12 eigenen Einträge wandern mit'),
      findsOneWidget,
    );
    expect(find.textContaining('Nichts geht verloren'), findsOneWidget);
    // Discarding names the number it deletes rather than saying "data".
    expect(
      find.textContaining('Die 12 eigenen Einträge werden gelöscht'),
      findsOneWidget,
    );
  });

  testWidgets('a device with nothing of its own is told so', (tester) async {
    await open(tester, rows: 0);

    expect(
      find.textContaining('hat nichts einzubringen'),
      findsOneWidget,
    );
  });

  testWidgets('one entry is one entry, not "1 Einträge"', (tester) async {
    await open(tester, rows: 1);

    expect(
      find.textContaining('Der eine eigene Eintrag wandert'),
      findsOneWidget,
    );
  });

  testWidgets('tapping merge answers merge', (tester) async {
    HouseholdConflictChoice? answer;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async => answer = await askAboutHouseholdConflict(
                  context,
                  mine: 'Familie Muster',
                  rows: 3,
                ),
                child: const Text('los'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('los'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zusammenführen'));
    await tester.pumpAndSettle();

    expect(answer, HouseholdConflictChoice.merge);
  });

  testWidgets('is accessible', (tester) async {
    await open(tester);
    await expectAccessible(tester);
  });
}
