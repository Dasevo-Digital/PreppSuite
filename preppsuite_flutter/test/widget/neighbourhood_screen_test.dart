import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/core/app_database_providers.dart';
import 'package:preppsuite_flutter/features/neighbourhood/application/neighbour_offer_code.dart';
import 'package:preppsuite_flutter/features/neighbourhood/presentation/neighbour_offer_code_screen.dart';
import 'package:preppsuite_flutter/features/neighbourhood/presentation/neighbourhood_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:preppsuite_flutter/local_db/database.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'accessibility.dart';

/// The neighbourhood screen (#152).
///
/// What it promises is small and has to hold: the code holds what was
/// typed and nothing else, a neighbour's offer is looked at before it is
/// kept, and a phone without a camera still has a way in.
void main() {
  late AppDatabase db;
  late AppLocalizations l10n;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  /// A test of this screen, taken down at its end. Closing a drift stream
  /// schedules its clean-up on the next turn of the clock, and the
  /// framework checks for pending timers before any tear-down of ours
  /// would run -- so the screen goes, and one more frame runs, inside the
  /// test.
  void testScreen(String description, WidgetTesterCallback body) {
    testWidgets(description, (tester) async {
      await body(tester);
      await tester.pumpWidget(const SizedBox());
      // A duration, even zero: a plain pump() moves the fake clock not
      // at all and leaves a zero-length timer where it is.
      await tester.pump(Duration.zero);
    });
  }

  /// Lets real database work finish -- the rows arrive through a drift
  /// stream, and a fake clock moves none of it -- then the animations.
  Future<void> settle(WidgetTester tester) async {
    for (var round = 0; round < 10; round++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  Future<void> show(WidgetTester tester, {bool camera = false}) async {
    await tester.binding.setSurfaceSize(const Size(600, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: NeighbourhoodScreen(householdId: 'h', cameraAvailable: camera),
        ),
      ),
    );
    await settle(tester);
    l10n = AppLocalizations.of(
      tester.element(find.byType(NeighbourhoodScreen)),
    )!;
  }

  const neighbour =
      'Strom und Wärme: Powerbank laden\n'
      'Kontakt: Klingel Meier\n'
      'PreppSuite-Angebot/1 energy 2026-10-09';

  /// The rows, read where real database work can finish.
  Future<List<NeighbourOffer>> stored(WidgetTester tester) async =>
      (await tester.runAsync(() => db.watchNeighbourOffers('h').first))!;

  Future<void> paste(WidgetTester tester, String text) async {
    await tester.tap(find.text(l10n.neighbourhoodPaste));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), text);
    await tester.tap(find.text(l10n.neighbourhoodPasteConfirm));
    await settle(tester);
  }

  testScreen('empty, it says what an offer is and what is not in it', (
    tester,
  ) async {
    await show(tester);

    expect(find.text(l10n.neighbourhoodIntro), findsOneWidget);
    expect(find.text(l10n.neighbourhoodOwnEmpty), findsOneWidget);
    expect(find.text(l10n.neighbourhoodReceivedEmpty), findsOneWidget);
    expect(find.textContaining('kein Standort'), findsOneWidget);
  });

  testScreen('without a camera, pasting is still there', (tester) async {
    await show(tester);

    expect(find.text(l10n.neighbourhoodScan), findsNothing);
    expect(find.text(l10n.neighbourhoodPaste), findsOneWidget);
  });

  testScreen('with one, scanning is offered too', (tester) async {
    await show(tester, camera: true);

    expect(find.text(l10n.neighbourhoodScan), findsOneWidget);
  });

  testScreen('a pasted offer is shown before it is kept', (tester) async {
    await show(tester);
    await paste(tester, neighbour);

    expect(find.text(l10n.neighbourhoodReceiveTitle), findsOneWidget);
    expect(find.text('Powerbank laden'), findsOneWidget);
    // Asked, not yet kept.
    expect(await stored(tester), isEmpty);

    await tester.tap(find.text(l10n.neighbourhoodReceiveConfirm));
    await settle(tester);

    expect(find.text(l10n.neighbourhoodReceivedEmpty), findsNothing);
    expect(find.text('Powerbank laden'), findsOneWidget);
    expect(find.textContaining('Klingel Meier'), findsOneWidget);
    expect(find.textContaining('angeboten am'), findsOneWidget);
  });

  testScreen('the same offer twice is one offer', (tester) async {
    await show(tester);
    for (var i = 0; i < 2; i++) {
      await paste(tester, neighbour);
      await tester.tap(find.text(l10n.neighbourhoodReceiveConfirm));
      await settle(tester);
    }

    expect(find.text(l10n.neighbourhoodAlreadyKnown), findsOneWidget);
    expect(await stored(tester), hasLength(1));
  });

  testScreen('text that is no offer is said to be none', (tester) async {
    await show(tester);
    await paste(tester, 'https://example.org');

    expect(find.text(l10n.neighbourhoodNotAnOffer), findsOneWidget);
    expect(find.text(l10n.neighbourhoodReceiveTitle), findsNothing);
  });

  testScreen('an own offer becomes a code of exactly its text', (
    tester,
  ) async {
    await show(tester);
    await tester.tap(find.text(l10n.neighbourhoodCreate));
    await tester.pumpAndSettle();

    // What the form says about the code, before anything is saved.
    expect(find.text(l10n.neighbourhoodFormNote), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, l10n.neighbourhoodBodyField),
      '20 l Trinkwasser',
    );
    await tester.tap(find.text(l10n.saveButton));
    await settle(tester);

    expect(find.text('20 l Trinkwasser'), findsOneWidget);
    await tester.tap(find.text('20 l Trinkwasser'));
    await tester.pumpAndSettle();

    expect(find.byType(NeighbourOfferCodeScreen), findsOneWidget);
    final shown = find.textContaining('PreppSuite-Angebot/1 water');
    expect(shown, findsOneWidget);
    final text = tester.widget<Text>(shown).data!;
    expect(text, startsWith('Wasser: 20 l Trinkwasser\n'));
    expect(text.split('\n'), hasLength(2), reason: 'no contact, no line');
    expect(NeighbourOfferCode.decode(text), isA<ReadNeighbourOffer>());
  });

  testScreen('an offer without text is not saved', (tester) async {
    await show(tester);
    await tester.tap(find.text(l10n.neighbourhoodCreate));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.saveButton));
    await tester.pumpAndSettle();

    expect(find.text(l10n.neighbourhoodBodyRequired), findsOneWidget);
    expect(await stored(tester), isEmpty);
  });

  testScreen('the screen meets the accessibility guidelines', (tester) async {
    await show(tester, camera: true);
    await expectAccessible(tester);
  });

  testScreen('the screen survives twice the font size', (tester) async {
    useLargeText(tester);
    await show(tester, camera: true);
  });
}
