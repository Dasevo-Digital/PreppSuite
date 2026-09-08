import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/maps/presentation/map_download_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'accessibility.dart';

/// The area picker. What matters is that it names a tile count before
/// anything is fetched — that number is the only warning somebody gets
/// before committing a phone to a download.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> show(WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
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

  testWidgets('counts the tiles for the visible area', (tester) async {
    await show(tester);

    expect(find.text('Kartenausschnitt laden'), findsOneWidget);
    expect(find.text('Detailstufe'), findsOneWidget);
    expect(find.textContaining('Kacheln'), findsWidgets);

    // Free and key-less is the default; the other one needs an account.
    expect(
      find.text('OpenFreeMap (frei, ohne Schlüssel)'),
      findsOneWidget,
    );

    // The public server is credited and the restraint is spelled out
    // rather than left to the tile limit alone.
    expect(find.textContaining('öffentlichen Server'), findsOneWidget);
  });

  testWidgets('offers a place to search for, not only the viewport', (
    tester,
  ) async {
    await show(tester);

    expect(find.text('Ort, Kreis, Bundesland oder Land'), findsOneWidget);

    // Until something is searched for, the area is what is on screen,
    // and the screen says which of the two it is.
    expect(find.text('Sichtbarer Ausschnitt'), findsOneWidget);

    // The level was picked for the area rather than left at a default.
    expect(
      find.text('Höchste Stufe, die für dieses Gebiet noch geht.'),
      findsOneWidget,
    );
  });

  testWidgets('the download button is there and enabled for a small area', (
    tester,
  ) async {
    await show(tester);

    final button = find.widgetWithText(FilledButton, 'Karte herunterladen');
    expect(button, findsOneWidget);
    expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
  });

  testWidgets('the map download screen meets the accessibility guidelines', (
    tester,
  ) async {
    await show(tester);
    await expectAccessible(tester);
  });
}
