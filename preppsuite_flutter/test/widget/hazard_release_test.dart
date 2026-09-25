import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/warnings/presentation/hazard_release_screen.dart';
import 'package:preppsuite_flutter/features/warnings/presentation/iodine_tablets_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';

import 'accessibility.dart';

/// The two pages that say what to do when something has been released.
///
/// Everything on them is the BBK's and the BfS's own wording. What these
/// tests hold is the part a translation or a tidy-up could quietly lose:
/// that both halves of the cellar rule are present, and that the two
/// sentences carrying the iodine page come before anything else.
void main() {
  late AppLocalizations l10n;

  Future<void> pump(WidgetTester tester, Widget screen) async {
    await tester.binding.setSurfaceSize(const Size(900, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            l10n = AppLocalizations.of(context)!;
            return screen;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the cellar rule is on the page with both of its halves', (
    tester,
  ) async {
    await pump(tester, const HazardReleaseScreen());

    // Half of this rule is worse than none of it: a household that
    // remembers only "go to the cellar" walks into the gas, and one that
    // remembers only "avoid the cellar" gives up the best shielding it
    // has.
    expect(find.text(l10n.hazardReleaseCellarChemical), findsOneWidget);
    expect(find.text(l10n.hazardReleaseCellarRadio), findsOneWidget);
  });

  testWidgets('the instructions keep the order they were given in', (
    tester,
  ) async {
    await pump(tester, const HazardReleaseScreen());

    // Closing the windows before finding the inner room is not the same
    // plan in a different sequence, so the numbers are load-bearing.
    final windows = tester.getTopLeft(
      find.text(l10n.hazardReleaseHomeWindows),
    );
    final room = tester.getTopLeft(find.text(l10n.hazardReleaseHomeRoom));
    final wait = tester.getTopLeft(find.text(l10n.hazardReleaseHomeWait));
    expect(windows.dy, lessThan(room.dy));
    expect(room.dy, lessThan(wait.dy));
  });

  testWidgets('the page names where it comes from', (tester) async {
    await pump(tester, const HazardReleaseScreen());
    expect(find.text(l10n.hazardReleaseSource), findsOneWidget);
  });

  testWidgets('the iodine page leads with the two rules, not the detail', (
    tester,
  ) async {
    await pump(tester, const IodineTabletsScreen());

    final onOrder = tester.getTopLeft(
      find.text(l10n.iodineOnlyOnOrderBody),
    );
    final thyroidOnly = tester.getTopLeft(
      find.text(l10n.iodineOnlyThyroidBody),
    );
    final where = tester.getTopLeft(find.text(l10n.iodineWhereBody));

    // Somebody who stops reading after the first card has still read the
    // half that keeps them out of trouble.
    expect(onOrder.dy, lessThan(where.dy));
    expect(thyroidOnly.dy, lessThan(where.dy));
  });

  testWidgets('over 45 is on the page, not only the who-should', (
    tester,
  ) async {
    await pump(tester, const IodineTabletsScreen());
    expect(find.text(l10n.iodineWhoOver45), findsOneWidget);
    expect(find.text(l10n.iodineWhoThyroid), findsOneWidget);
  });

  testWidgets('both are accessible', (tester) async {
    await pump(tester, const HazardReleaseScreen());
    await expectAccessible(tester);
    await pump(tester, const IodineTabletsScreen());
    await expectAccessible(tester);
  });
}
