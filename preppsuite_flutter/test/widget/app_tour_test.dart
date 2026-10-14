import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/checklists/application/checklist_providers.dart';
import 'package:preppsuite_flutter/features/home/presentation/home_shell.dart';
import 'package:preppsuite_flutter/features/inventory/application/inventory_providers.dart';
import 'package:preppsuite_flutter/features/tour/application/app_tour.dart';
import 'package:preppsuite_flutter/features/tour/application/app_tour_l10n.dart';
import 'package:preppsuite_flutter/features/tour/presentation/tour_banner.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_providers.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:preppsuite_flutter/local_db/database.dart';
import 'package:preppsuite_flutter/model/household_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'accessibility.dart';

/// The tour through the real shell (#173): every stop opens its screen,
/// and every control a stop's text names is on that screen. The second
/// half is what keeps the tour from going stale — a button that moves or
/// is renamed fails here rather than leaving a text that points at
/// nothing.
void main() {
  const answeredKey = 'appTourOfferAnswered';

  /// A test of the shell, taken down at its end. The stops open screens
  /// that read the database, and closing a drift stream schedules its
  /// clean-up on the next turn of the clock -- after which the framework
  /// looks for pending timers before any tear-down of ours runs. So the
  /// tree goes, and one more frame runs, inside the test.
  void testShell(String description, WidgetTesterCallback body) {
    testWidgets(description, (tester) async {
      await body(tester);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    });
  }

  Future<void> pumpShell(
    WidgetTester tester, {
    Locale locale = const Locale('de'),
    Map<String, Object>? preferences = const {},
    List<Warning> warnings = const [],
    Size size = const Size(390, 844),
  }) async {
    if (preferences != null) {
      SharedPreferences.setMockInitialValues(preferences);
    }
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          inventoryItemsProvider('h').overrideWith((ref) => Stream.value([])),
          activeWarningsProvider.overrideWith(
            (ref) => Stream.value(warnings),
          ),
          checklistTemplatesProvider(
            'h',
          ).overrideWith((ref) => Stream.value([])),
          allChecklistItemsProvider(
            'h',
          ).overrideWith((ref) => Stream.value([])),
        ],
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const HomeShell(
            profile: HouseholdProfile(
              id: 'h',
              name: 'Zuhause',
              countryCode: 'DE',
            ),
          ),
        ),
      ),
    );
    // Frames, not a settle: the reminder schedulers debounce for half a
    // second and then talk to the platform, which is no part of this.
    await tester.pump();
    await tester.pump();
  }

  AppLocalizations l10nOf(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(HomeShell)))!;

  Future<void> tapAndPump(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pump();
    await tester.pump();
  }

  int selectedInBar(WidgetTester tester) =>
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex;

  bool onScreen(String label) =>
      find.text(label).evaluate().isNotEmpty ||
      find.byTooltip(label).evaluate().isNotEmpty;

  /// On the screen, or reached by scrolling it the way a reader would --
  /// a text may point at something further down.
  Future<bool> reachable(WidgetTester tester, String label) async {
    for (var drag = 0; drag < 8 && !onScreen(label); drag++) {
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -200));
      await tester.pump();
    }
    return onScreen(label);
  }

  for (final locale in const [Locale('de'), Locale('en'), Locale('es')]) {
    testShell(
      'the tour takes every stop and finds what it names there '
      '(${locale.languageCode})',
      (tester) async {
        await pumpShell(tester, locale: locale);
        final l10n = l10nOf(tester);

        await tapAndPump(tester, find.byTooltip(l10n.tourOpen));

        for (final stop in TourStop.values) {
          final count = TourStop.values.length;
          expect(find.text('${stop.index + 1}/$count'), findsOneWidget);
          expect(find.text(tourStopBody(l10n, stop)), findsOneWidget);
          for (final anchor in tourStopAnchors(l10n, stop)) {
            expect(
              await reachable(tester, anchor),
              isTrue,
              reason:
                  '${stop.name}: the text names "$anchor", '
                  'which is not on the screen it opened',
            );
          }
          // Back is offered from the second stop on, and only there.
          expect(
            find.text(l10n.tourBack),
            stop.isFirst ? findsNothing : findsOneWidget,
          );

          await tapAndPump(
            tester,
            find.text(stop.isLast ? l10n.tourDone : l10n.tourNext),
          );
        }

        // Done hands the household back to the overview.
        expect(find.byTooltip(l10n.tourEnd), findsNothing);
        expect(find.text(tourStopBody(l10n, TourStop.settings)), findsNothing);
        expect(selectedInBar(tester), 0);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testShell('ending the tour leaves the screen where it is', (tester) async {
    await pumpShell(tester);
    final l10n = l10nOf(tester);

    await tapAndPump(tester, find.byTooltip(l10n.tourOpen));
    await tapAndPump(tester, find.text(l10n.tourNext));
    await tapAndPump(tester, find.text(l10n.tourNext));
    // Third stop: the inventory, which is the bar's third slot.
    expect(find.text(tourStopBody(l10n, TourStop.inventory)), findsOneWidget);
    await tapAndPump(tester, find.byTooltip(l10n.tourEnd));

    expect(find.text(tourStopBody(l10n, TourStop.inventory)), findsNothing);
    expect(selectedInBar(tester), 2);
  });

  testShell('back goes one stop back', (tester) async {
    await pumpShell(tester);
    final l10n = l10nOf(tester);

    await tapAndPump(tester, find.byTooltip(l10n.tourOpen));
    await tapAndPump(tester, find.text(l10n.tourNext));
    await tapAndPump(tester, find.text(l10n.tourBack));

    expect(find.text(tourStopBody(l10n, TourStop.emergency)), findsOneWidget);
    expect(selectedInBar(tester), 1);
  });

  testShell('the overview offers the tour until it is declined', (
    tester,
  ) async {
    await pumpShell(tester);
    final l10n = l10nOf(tester);

    expect(find.text(l10n.tourOfferTitle), findsOneWidget);
    await tapAndPump(tester, find.text(l10n.tourOfferDismiss));
    expect(find.text(l10n.tourOfferTitle), findsNothing);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(answeredKey), isTrue);

    // A new start of the app, on the same stored preferences.
    await tester.pumpWidget(const SizedBox.shrink());
    await pumpShell(tester, preferences: null);
    expect(find.text(l10n.tourOfferTitle), findsNothing);
    // The question mark stays.
    expect(find.byTooltip(l10n.tourOpen), findsOneWidget);
  });

  testShell('taking the tour answers the offer as well', (tester) async {
    await pumpShell(tester);
    final l10n = l10nOf(tester);

    await tapAndPump(tester, find.text(l10n.tourOfferStart));

    expect(find.text(tourStopBody(l10n, TourStop.emergency)), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(answeredKey), isTrue);

    await tapAndPump(tester, find.byTooltip(l10n.tourEnd));
    await tapAndPump(tester, find.byType(NavigationDestination).first);
    expect(find.text(l10n.tourOfferTitle), findsNothing);
  });

  testShell('an answered offer is not made again', (tester) async {
    await pumpShell(tester, preferences: {answeredKey: true});

    expect(find.text(l10nOf(tester).tourOfferTitle), findsNothing);
  });

  testShell('no offer in crisis mode', (tester) async {
    await pumpShell(tester, preferences: {'crisisModeGlobal': true});

    expect(find.text(l10nOf(tester).tourOfferTitle), findsNothing);
  });

  testShell('no offer while a severe warning concerns the household', (
    tester,
  ) async {
    final now = DateTime.now();
    await pumpShell(
      tester,
      warnings: [
        Warning(
          source: 'bbk',
          externalId: 'w1',
          countryCode: 'DE',
          severity: 'severe',
          eventType: 'Flood',
          headline: 'Hochwasser',
          effective: now,
          sent: now,
          updatedAt: now,
          notified: false,
        ),
      ],
    );

    expect(find.text(l10nOf(tester).tourOfferTitle), findsNothing);
  });

  testShell('at twice the text size the buttons stay in reach', (
    tester,
  ) async {
    useLargeText(tester);
    await pumpShell(tester, size: const Size(360, 640));
    final l10n = l10nOf(tester);

    await tapAndPump(tester, find.byTooltip(l10n.tourOpen));

    final next = find.text(l10n.tourNext);
    expect(next, findsOneWidget);
    final bar = tester.getRect(find.byType(NavigationBar));
    expect(tester.getRect(next).bottom, lessThanOrEqualTo(bar.top));
    // The band never takes more than half of what lies above the bar:
    // the text scrolls under its ceiling instead.
    final band = tester.getRect(find.byType(TourBanner));
    expect(band.height, lessThanOrEqualTo(bar.top / 2));

    await tapAndPump(tester, next);
    expect(find.text(tourStopBody(l10n, TourStop.warnings)), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testShell('offer and band are accessible', (tester) async {
    await pumpShell(tester);
    final l10n = l10nOf(tester);

    expect(find.text(l10n.tourOfferTitle), findsOneWidget);
    await expectAccessible(tester);

    await tapAndPump(tester, find.text(l10n.tourOfferStart));
    await tapAndPump(tester, find.text(l10n.tourNext));
    await expectAccessible(tester);
  });

  testShell('the band announces each stop', (tester) async {
    await pumpShell(tester);
    final l10n = l10nOf(tester);
    final handle = tester.ensureSemantics();

    List<String> announced() => [
      for (final node in liveRegions(tester)) node.getSemanticsData().label,
    ];

    await tapAndPump(tester, find.byTooltip(l10n.tourOpen));
    expect(
      announced(),
      contains(
        allOf(
          contains(tourStopTitle(l10n, TourStop.emergency)),
          contains(l10n.tourProgress(1, TourStop.values.length)),
        ),
      ),
    );

    await tapAndPump(tester, find.text(l10n.tourNext));
    expect(
      announced(),
      contains(contains(tourStopTitle(l10n, TourStop.warnings))),
    );
    handle.dispose();
  });
}
