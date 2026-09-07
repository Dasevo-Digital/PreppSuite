import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/maps/application/map_source_preference.dart';
import 'package:preppsuite_flutter/features/maps/application/offline_map_providers.dart';
import 'package:preppsuite_flutter/features/maps/application/pmtiles_archive.dart';
import 'package:preppsuite_flutter/features/maps/presentation/map_source_bar.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/maps/pmtiles_fixture.dart';

class _FixedOfflineMap extends OfflineMapController {
  _FixedOfflineMap(this.fixed);

  final OfflineMapState fixed;

  @override
  Future<OfflineMapState> build() async => fixed;
}

class _FixedSource extends MapSourceController {
  _FixedSource(this.fixed);

  final MapSourcePreference fixed;

  @override
  MapSourcePreference build() => fixed;
}

/// The line under the map that says which map it is.
///
/// Offline and online look identical until somebody pans past the edge of
/// an extract, and by then they are looking at nothing — so this is the
/// one thing the map screen has to get right.
///
/// Tested without the map itself: the vector renderer keeps working for as
/// long as it is given, and a widget test never stops giving.
void main() {
  late Directory workspace;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    workspace = Directory.systemTemp.createTempSync('preppsuite-source-bar');
  });

  tearDown(() => workspace.deleteSync(recursive: true));

  /// Opening the archive is real file I/O, and a widget test's clock does
  /// not run it: without `runAsync` the future never completes and the
  /// test hangs rather than failing.
  Future<OfflineMapState> openArchive(WidgetTester tester, String label) async {
    final file = File('${workspace.path}/extract.pmtiles')
      ..writeAsBytesSync(
        buildArchive(minZoom: 0, maxZoom: 12, tiles: {(0, 0, 0): 'world'}),
      );
    final archive = await tester.runAsync(
      () async => PmTilesArchive.open(await FileByteRangeSource.open(file)),
    );
    addTearDown(() => tester.runAsync(archive!.close));
    return OfflineMapState(label: label, archive: archive);
  }

  Future<void> show(
    WidgetTester tester, {
    required OfflineMapState state,
    MapSourcePreference preference = MapSourcePreference.offline,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          offlineMapProvider.overrideWith(() => _FixedOfflineMap(state)),
          mapSourceProvider.overrideWith(() => _FixedSource(preference)),
        ],
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => MapSourceBar(
                state: state,
                l10n: AppLocalizations.of(context)!,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('without an archive it says the tiles need a connection', (
    tester,
  ) async {
    await show(tester, state: const OfflineMapState());

    expect(
      find.textContaining('Noch keine Karte auf dem Gerät'),
      findsOneWidget,
    );

    // The offline half of the switch has nothing to switch to.
    final button = tester.widget<SegmentedButton<MapSourcePreference>>(
      find.byType(SegmentedButton<MapSourcePreference>),
    );
    expect(
      button.segments
          .firstWhere((s) => s.value == MapSourcePreference.offline)
          .enabled,
      isFalse,
    );
    expect(button.selected, {MapSourcePreference.online});
  });

  testWidgets('with an archive it names the file and its zoom range', (
    tester,
  ) async {
    await show(
      tester,
      state: await openArchive(tester, 'Niedersachsen, Stufe 12'),
    );

    expect(
      find.text('Gezeichnet aus Niedersachsen, Stufe 12, Stufe 0 bis 12.'),
      findsOneWidget,
    );
  });

  testWidgets('switched to online it says so even with an archive open', (
    tester,
  ) async {
    await show(
      tester,
      state: await openArchive(tester, 'Niedersachsen, Stufe 12'),
      preference: MapSourcePreference.online,
    );

    expect(find.textContaining('kommen von OpenStreetMap'), findsOneWidget);
    expect(find.textContaining('Gezeichnet aus'), findsNothing);
  });
}
