import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:preppsuite_flutter/features/inventory/presentation/water_treatment_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';

import 'accessibility.dart';

/// The app counted litres and put "Wasserfilter oder Entkeimungsmittel" on
/// a shopping list without ever saying what those do. This screen is the
/// answer; these tests hold the two things about it that matter.
void main() {
  Future<void> show(
    WidgetTester tester, {
    Locale locale = const Locale('de'),
  }) => tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const WaterTreatmentScreen(),
    ),
  );

  testWidgets('says what no method fixes, before any method', (tester) async {
    // Boiling a bucket from a flooded street is a way of feeling safer
    // while drinking the same chemicals. That has to come first, not as a
    // footnote under an instruction that sounds reassuring.
    await show(tester);

    final chemistry = tester.getTopLeft(
      find.text('Kein Verfahren hilft gegen Chemie'),
    );
    final boiling = tester.getTopLeft(find.text('Abkochen'));

    expect(chemistry.dy, lessThan(boiling.dy));
  });

  testWidgets('names the limits, not only the methods', (tester) async {
    await show(tester);

    // Chlorine against Cryptosporidium is the one somebody gets wrong
    // with a tablet in their hand. Below the fold on a test-sized window,
    // so the list has to be taken there.
    await tester.scrollUntilVisible(
      find.textContaining('Cryptosporidium'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('Cryptosporidium'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.textContaining('Quellen:'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('Quellen:'), findsOneWidget);
  });

  testWidgets('survives twice the system font size', (tester) async {
    useLargeText(tester);
    await show(tester);

    expect(tester.takeException(), isNull);
  });

  testWidgets('and exists in English too', (tester) async {
    await show(tester, locale: const Locale('en'));

    expect(find.text('Making water drinkable'), findsOneWidget);
    expect(find.text('Boiling'), findsOneWidget);
  });
}
