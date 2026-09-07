import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/maps/application/map_source_preference.dart';
import 'package:preppsuite_flutter/features/maps/application/offline_map_providers.dart';
import 'package:preppsuite_flutter/features/maps/presentation/map_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  });
}
