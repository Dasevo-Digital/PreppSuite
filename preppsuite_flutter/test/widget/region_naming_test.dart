import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/settings/presentation/additional_regions_card.dart';
import 'package:preppsuite_flutter/features/settings/presentation/my_region_card.dart';
import 'package:preppsuite_flutter/features/warnings/application/dwd_areas.dart';
import 'package:preppsuite_flutter/features/warnings/application/dwd_areas_provider.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_region_filter.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:preppsuite_flutter/model/household_profile.dart';

/// Whether a person can check that their region is the right one.
///
/// It used to print `031010000000` and nothing else, which is
/// unverifiable: that string is exactly as plausible as the key for
/// somewhere else entirely.
void main() {
  final areas = DwdAreas.parse('''
# name;district;state
Stadt Braunschweig;03101;NI
Stadt Worms;07319;RP
''');

  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [dwdAreasProvider.overrideWith((ref) async => areas)],
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: Builder(builder: (context) => child)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Widget myRegion(String? regionKey) => Builder(
    builder: (context) => MyRegionCard(
      profile: HouseholdProfile(
        id: 'h1',
        name: 'Test',
        countryCode: 'DE',
        regionKey: regionKey,
      ),
      l10n: AppLocalizations.of(context)!,
    ),
  );

  testWidgets('the household\'s own key is written out', (tester) async {
    await pump(tester, myRegion('031010000000'));

    expect(
      find.text('Stadt Braunschweig · Niedersachsen (031010000000)'),
      findsOneWidget,
    );
  });

  testWidgets('a key the table does not know says so', (tester) async {
    // Worth saying rather than passing over: a key that names no
    // district matches no warning either.
    await pump(tester, myRegion('099990000000'));

    expect(find.textContaining('099990000000'), findsOneWidget);
    expect(find.textContaining('Unbekannter Schlüssel'), findsOneWidget);
  });

  testWidgets('no region set still reads as no region set', (tester) async {
    await pump(tester, myRegion(null));

    expect(find.text('Keine Region festgelegt'), findsOneWidget);
  });

  testWidgets('an additional Kreis is named, not numbered', (tester) async {
    await pump(
      tester,
      Builder(
        builder: (context) => AdditionalRegionsCard(
          profile: HouseholdProfile(
            id: 'h1',
            name: 'Test',
            countryCode: 'DE',
            extraRegions: const [
              WarningRegion(kind: WarningRegionKind.kreis, value: '07319'),
            ],
          ),
          l10n: AppLocalizations.of(context)!,
        ),
      ),
    );

    expect(find.text('Stadt Worms · Rheinland-Pfalz (07319)'), findsOneWidget);
  });

  testWidgets('a Bundesland subscription keeps its own name', (tester) async {
    await pump(
      tester,
      Builder(
        builder: (context) => AdditionalRegionsCard(
          profile: HouseholdProfile(
            id: 'h1',
            name: 'Test',
            countryCode: 'DE',
            extraRegions: const [
              WarningRegion(
                kind: WarningRegionKind.bundesland,
                value: 'NI',
              ),
            ],
          ),
          l10n: AppLocalizations.of(context)!,
        ),
      ),
    );

    expect(find.text('Niedersachsen'), findsOneWidget);
  });

  testWidgets('a region key that could never match is refused', (
    tester,
  ) async {
    // Five letters passed the `length >= 5` test the region filter uses,
    // so typing a town's name switched filtering on and then matched
    // nothing at all.
    await pump(tester, myRegion('031010000000'));

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Worms');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();

    expect(find.textContaining('fünf oder zwölf Ziffern'), findsOneWidget);
  });

  testWidgets('the name follows the field while it is being typed', (
    tester,
  ) async {
    await pump(tester, myRegion(null));

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '07319');
    await tester.pumpAndSettle();

    expect(
      find.text('Stadt Worms · Rheinland-Pfalz'),
      findsOneWidget,
    );
  });
}
