import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/home/presentation/burglary_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';

import 'accessibility.dart';

/// The burglary page.
///
/// What these tests hold is the order, because on this page the order is
/// the content: the police's own first rule is not to get hurt, and a
/// layout that opens with retrofitting standards would bury it under the
/// quiet-afternoon half.
void main() {
  late AppLocalizations l10n;

  Future<void> pump(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 2600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context)!;
              return const BurglaryScreen(householdId: 'h');
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the rule about not getting hurt comes before everything', (
    tester,
  ) async {
    await pump(tester);

    final rule = tester.getTopLeft(find.text(l10n.burglaryRuleBody));
    final caught = tester.getTopLeft(find.text(l10n.burglaryCaughtLeave));
    final prevention = tester.getTopLeft(find.text(l10n.burglaryPreventNew));

    expect(rule.dy, lessThan(caught.dy));
    // Prevention is the half somebody reads on a quiet afternoon. It does
    // not belong above the half they read at two in the morning.
    expect(caught.dy, lessThan(prevention.dy));
  });

  testWidgets('the two things that are easiest to get wrong are there', (
    tester,
  ) async {
    await pump(tester);

    // Tidying up destroys the traces, and not reporting a failed attempt
    // keeps it out of the statistics the prevention advice is built on.
    expect(find.text(l10n.burglaryAfterNoTidy), findsOneWidget);
    expect(find.text(l10n.burglaryAfterReport), findsOneWidget);
  });

  testWidgets('it points at the inventory the police ask for', (tester) async {
    await pump(tester);
    expect(find.text(l10n.burglaryPossessionsLink), findsOneWidget);
  });

  testWidgets('the page names where it comes from', (tester) async {
    await pump(tester);
    expect(find.text(l10n.burglarySource), findsOneWidget);
  });

  testWidgets('is accessible', (tester) async {
    await pump(tester);
    await expectAccessible(tester);
  });
}
