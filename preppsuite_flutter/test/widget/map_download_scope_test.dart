import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/maps/application/place_search.dart';
import 'package:preppsuite_flutter/features/maps/presentation/map_download_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/fixture_http_client.dart';

import 'accessibility.dart';

/// Searching a town and then choosing how far out to download — the path
/// that turns "a whole country" from impossible into a number.
void main() {
  String fixture(String name) =>
      File('test/fixtures/nominatim_$name.json').readAsStringSync();

  String url(String query, int limit) =>
      'https://nominatim.openstreetmap.org/search'
      '?format=jsonv2&q=$query&limit=$limit&addressdetails=1'
      '&accept-language=de';

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> show(WidgetTester tester) async {
    final client = PlaceSearchClient(
      httpClient: FixtureHttpClient({
        url('Hannover', 8): fixture('hannover'),
        url('Niedersachsen', 1): fixture('niedersachsen'),
        url('Deutschland', 1): fixture('deutschland'),
      }),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [placeSearchProvider.overrideWithValue(client)],
        child: const MaterialApp(
          locale: Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MapDownloadScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  /// Searches, picks the first hit, and waits out the two geocoder calls
  /// the screen spaces a second apart.
  Future<void> chooseHannover(WidgetTester tester) async {
    await tester.enterText(find.byType(TextField).first, 'Hannover');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Both hits are called "Hannover" — the city and an island off
    // Chile — so the row is what to tap, not the name.
    await tester.tap(find.byType(ListTile).first);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 2));
  }

  testWidgets('a searched town becomes the area', (tester) async {
    await show(tester);
    await chooseHannover(tester);

    expect(find.textContaining('Hannover · city'), findsOneWidget);
    expect(find.text('Sichtbarer Ausschnitt'), findsNothing);
    expect(find.text('Nur der Ort'), findsOneWidget);
  });

  testWidgets('the whole country is on offer once the rings resolve', (
    tester,
  ) async {
    await show(tester);
    await chooseHannover(tester);

    expect(find.text('Mit Bundesland'), findsOneWidget);
    expect(find.text('Ganzes Land'), findsOneWidget);

    await tester.tap(find.text('Ganzes Land'));
    await tester.pump();

    // The staggered plan, ring by ring: the whole planet at the levels
    // where one tile fills a window, then the country coarse, then the
    // state at full detail. 341 + 20,498 + 64,560 tiles.
    expect(find.text('Welt: Stufe 0 bis 4, 341 Kacheln'), findsOneWidget);
    expect(
      find.text('Deutschland: Stufe 5 bis 12, 20498 Kacheln'),
      findsOneWidget,
    );
    expect(
      find.text('Niedersachsen: Stufe 13 bis 14, 64560 Kacheln'),
      findsOneWidget,
    );
    expect(find.textContaining('85399 Kacheln'), findsOneWidget);

    // And it is downloadable, which is the whole claim.
    final button = find.widgetWithText(FilledButton, 'Karte herunterladen');
    expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
  });

  testWidgets('the download scope meets the accessibility guidelines', (
    tester,
  ) async {
    await show(tester);
    await expectAccessible(tester);
  });

  testWidgets('the download scope survives twice the font size', (
    tester,
  ) async {
    useLargeText(tester);
    await show(tester);
  });
}
