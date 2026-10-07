import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/first_aid/application/defibrillators.dart';
import 'package:preppsuite_flutter/features/maps/application/map_source_preference.dart';
import 'package:preppsuite_flutter/features/maps/application/offline_map_providers.dart';
import 'package:preppsuite_flutter/features/maps/presentation/map_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'accessibility.dart';

class _NoOfflineMap extends OfflineMapController {
  @override
  Future<OfflineMapState> build() async => const OfflineMapState();
}

class _FixedSource extends MapSourceController {
  @override
  MapSourcePreference build() => MapSourcePreference.offline;
}

/// The map as a destination of its own — the download and the user's own
/// position reachable from the map rather than from the settings.
///
/// Only the network case is driven here: an open archive puts the vector
/// renderer on screen, and it keeps working for as long as a widget test
/// will pump. What that case shows is covered in `map_source_bar_test`.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> show(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          offlineMapProvider.overrideWith(_NoOfflineMap.new),
          mapSourceProvider.overrideWith(_FixedSource.new),
        ],
        child: const MaterialApp(
          locale: Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MapScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('without an archive it says the tiles need a connection', (
    tester,
  ) async {
    await show(tester);

    expect(
      find.textContaining('Noch keine Karte auf dem Gerät'),
      findsOneWidget,
    );
  });

  testWidgets('the download and the location are reachable from the map', (
    tester,
  ) async {
    await show(tester);

    expect(find.byTooltip('Karte herunterladen'), findsOneWidget);
    expect(find.byTooltip('Mein Standort'), findsOneWidget);
    // Beside it and not the same thing: one centres the map, the other
    // hands you the coordinates to read out.
    expect(find.byTooltip('Standort weitergeben'), findsOneWidget);
  });

  testWidgets('saved defibrillators are on the map and can be hidden', (
    tester,
  ) async {
    // #117: the archive has no layer for them; the last search does.
    await tester.runAsync(
      () => const DefibrillatorStore().save(
        DefibrillatorSearch(
          latitude: 52.2689,
          longitude: 10.5268,
          checkedAt: DateTime(2026, 10, 7),
          found: const [
            Defibrillator(
              id: 1,
              latitude: 52.2733,
              longitude: 10.5254,
              tags: {'defibrillator:location': 'Neben Raum 143'},
            ),
          ],
        ),
      ),
    );
    await show(tester);
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();

    expect(find.byTooltip('Defibrillatoren ausblenden'), findsOneWidget);
    expect(find.bySemanticsLabel('Neben Raum 143'), findsOneWidget);

    await tester.tap(find.byTooltip('Defibrillatoren ausblenden'));
    await tester.pump();
    expect(find.byTooltip('Defibrillatoren einblenden'), findsOneWidget);
    expect(find.bySemanticsLabel('Neben Raum 143'), findsNothing);
  });

  testWidgets('the map meets the accessibility guidelines', (
    tester,
  ) async {
    await show(tester);
    await expectAccessible(
      tester,
      // No archive here, so the source bar's "offline" segment is disabled
      // and Material greys its label. `map_source_bar_test` checks the
      // contrast of that bar with an archive open, where it is live.
      contrastExemption: 'the disabled map-source segment',
    );
  });

  testWidgets('the map survives twice the font size', (tester) async {
    useLargeText(tester);
    await show(tester);
  });
}
