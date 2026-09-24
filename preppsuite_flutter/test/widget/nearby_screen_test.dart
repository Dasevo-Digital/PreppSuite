import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:preppsuite_flutter/core/geolocation_service.dart';
import 'package:preppsuite_flutter/features/maps/application/offline_map_providers.dart';
import 'package:preppsuite_flutter/features/maps/application/readable_position.dart';
import 'package:preppsuite_flutter/features/maps/application/pmtiles_archive.dart';
import 'package:preppsuite_flutter/features/maps/presentation/map_screen.dart';
import 'package:preppsuite_flutter/features/maps/presentation/nearby_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';

import '../features/maps/offline_poi_tile.dart';
import '../features/maps/pmtiles_fixture.dart';
import 'accessibility.dart';

/// Stands in for the controller that opens the archive, so the screen can
/// be shown with one already open — or with none at all.
class _FakeOfflineMap extends OfflineMapController {
  _FakeOfflineMap(this._state);

  final OfflineMapState _state;

  @override
  Future<OfflineMapState> build() async => _state;
}

/// A device that could not manage a fresh fix and handed over the last
/// one it had — the fallback that keeps this screen from timing out.
class _StaleGeolocation extends GeolocationService {
  _StaleGeolocation(this.age);

  final Duration age;

  @override
  Future<ReadablePosition> getCurrentFix() async => ReadablePosition(
    latitude: 52.2689,
    longitude: 10.5268,
    accuracyMetres: 30,
    takenAt: DateTime.now().subtract(age),
  );

  @override
  void close() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Braunschweig's town centre, which sits in 14/8671/5391.
  const centre = LatLng(52.2689, 10.5268);

  late Directory workspace;
  setUp(() => workspace = Directory.systemTemp.createTempSync('nearby'));
  tearDown(() => workspace.deleteSync(recursive: true));

  /// Builds an archive and shows the screen against it.
  ///
  /// Everything real happens inside [WidgetTester.runAsync]: under the
  /// test binding's fake clock a file read never completes and neither
  /// does an isolate, so opening the archive outside it hangs the test
  /// rather than failing it. The frames are pumped between turns of it,
  /// because `pumpAndSettle` never settles while a progress bar is on
  /// screen.
  Future<void> show(
    WidgetTester tester, {
    required List<TestPoi> points,
    int maxZoom = 14,
    LatLng? at = centre,
    NavigatorObserver? observer,
    bool withArchive = true,
    GeolocationService? geolocation,
  }) async {
    PmTilesArchive? archive;
    await tester.runAsync(() async {
      if (!withArchive) return;
      final file = File('${workspace.path}/area.pmtiles')
        ..writeAsBytesSync(
          buildBinaryArchive(
            tiles: {(14, 8671, 5391): poiTile(points)},
            maxZoom: maxZoom,
            bounds: (9.0, 51.0, 12.0, 53.0),
          ),
        );
      archive = await PmTilesArchive.open(await FileByteRangeSource.open(file));
    });
    // Closed without waiting: the handle is going away with the temp
    // directory either way, and awaiting it outside `runAsync` would hang
    // the teardown for the same reason the setup has to be inside one.
    addTearDown(() => unawaited(archive?.close() ?? Future<void>.value()));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          offlineMapProvider.overrideWith(
            () => _FakeOfflineMap(
              archive == null
                  ? const OfflineMapState()
                  : OfflineMapState(label: 'Niedersachsen', archive: archive),
            ),
          ),
        ],
        child: MaterialApp(
          navigatorObservers: [?observer],
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: NearbyScreen(
            centre: at,
            centreLabel: at == null ? null : 'Kartenmitte',
            geolocation: geolocation,
          ),
        ),
      ),
    );
    for (var turn = 0; turn < 12; turn++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
  }

  testWidgets('a pharmacy in the archive is found without any network', (
    tester,
  ) async {
    await show(
      tester,
      points: [
        (subclass: 'pharmacy', name: 'Apotheke am Markt', x: 2048, y: 2048),
      ],
    );

    expect(find.text('Apotheke am Markt'), findsOneWidget);
    expect(find.text('Gesundheit · 1'), findsOneWidget);
  });

  testWidgets('a nameless point is shown by what it is', (tester) async {
    await show(
      tester,
      points: [
        (subclass: 'drinking_water', name: null, x: 2048, y: 2048),
      ],
    );

    expect(find.text('Trinkwasser'), findsOneWidget);
  });

  testWidgets('a filling station and a charging point are told apart', (
    tester,
  ) async {
    await show(
      tester,
      points: [
        (subclass: 'fuel', name: null, x: 2048, y: 2048),
        (subclass: 'charging_station', name: null, x: 2060, y: 2048),
      ],
    );

    // One group, two different answers — which is the whole reason the
    // search keys on the OpenStreetMap subclass rather than the schema's
    // coarser class.
    expect(find.text('Tankstelle'), findsOneWidget);
    expect(find.text('Ladesäule'), findsOneWidget);
  });

  testWidgets('tapping a point opens the map on it', (tester) async {
    // "400 m nordwestlich" says how far and which way, not where. The
    // archive the map draws from is the same one this list was read out
    // of, so the answer stays available with nothing to ask.
    final routes = _PushedRoutes();
    await show(
      tester,
      points: [
        (subclass: 'drinking_water', name: 'Brunnen am Ring', x: 2048, y: 2048),
      ],
      observer: routes,
    );

    await tester.tap(find.text('Brunnen am Ring'));

    // Deliberately not pumped: building the real map starts tile and
    // animation timers that never finish under the test clock. What is
    // being checked is which screen was asked for and with what, and the
    // route knows that before it is ever mounted.
    final route = routes.last as MaterialPageRoute<void>;
    final map =
        route.builder(tester.element(find.byType(NearbyScreen))) as MapScreen;

    expect(map.focusLabel, 'Brunnen am Ring');
    expect(map.focus, isNotNull);

    // The point it opens on is the one that was tapped, not the centre
    // the search started from.
    expect(map.focus!.latitude, closeTo(centre.latitude, 0.05));
    expect(map.focus!.longitude, closeTo(centre.longitude, 0.05));
  });

  testWidgets('the caveats are on the screen, not in a help text', (
    tester,
  ) async {
    await show(
      tester,
      points: [
        (subclass: 'pharmacy', name: 'Apotheke', x: 2048, y: 2048),
      ],
    );

    expect(find.textContaining('was heruntergeladen wurde'), findsOneWidget);
    expect(find.textContaining('Buswartehäuschen'), findsOneWidget);
  });

  testWidgets('with no archive it says so and offers the download', (
    tester,
  ) async {
    await show(tester, points: const [], withArchive: false);

    expect(find.text('Keine Karte heruntergeladen'), findsOneWidget);
    expect(find.text('Karte herunterladen'), findsOneWidget);
  });

  testWidgets('an archive that stops above zoom 14 explains itself', (
    tester,
  ) async {
    await show(
      tester,
      points: [(subclass: 'pharmacy', name: 'Apotheke', x: 2048, y: 2048)],
      maxZoom: 12,
    );

    expect(find.text('Die Karte reicht nicht tief genug'), findsOneWidget);
    expect(find.text('Apotheke'), findsNothing);
  });

  testWidgets('a point outside the download is not read as an empty area', (
    tester,
  ) async {
    await show(
      tester,
      points: [
        (subclass: 'pharmacy', name: 'Apotheke', x: 2048, y: 2048),
      ],
      // Munich; the archive declares 9-12 E, 51-53 N.
      at: const LatLng(48.1372, 11.5756),
    );

    expect(find.text('Außerhalb der heruntergeladenen Gegend'), findsOneWidget);
    expect(find.text('Nichts gefunden.'), findsNothing);
  });

  testWidgets('without a point it asks for one rather than searching', (
    tester,
  ) async {
    await show(
      tester,
      points: [
        (subclass: 'pharmacy', name: 'Apotheke', x: 2048, y: 2048),
      ],
      at: null,
    );

    expect(find.text('Noch kein Punkt gewählt'), findsOneWidget);
  });

  testWidgets('is accessible', (tester) async {
    await show(
      tester,
      points: [
        (subclass: 'pharmacy', name: 'Apotheke am Markt', x: 2048, y: 2048),
        (subclass: 'drinking_water', name: null, x: 2060, y: 2048),
      ],
    );

    await expectAccessible(tester);
  });

  testWidgets('says when the answer came from an old position', (
    tester,
  ) async {
    // The screen falls back to the last known fix rather than timing out.
    // A list of the nearest pharmacies is an answer to "from where", and
    // it was quietly answering from a place somebody may have left.
    await show(
      tester,
      points: [
        (subclass: 'pharmacy', name: 'Apotheke am Markt', x: 2048, y: 2048),
      ],
      at: null,
      geolocation: _StaleGeolocation(const Duration(minutes: 11)),
    );

    await tester.tap(find.byTooltip('Meinen Standort verwenden'));
    for (var turn = 0; turn < 12; turn++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }

    expect(find.textContaining('letzten bekannten Position'), findsOneWidget);
  });
}

/// Remembers what was pushed, so a route can be inspected without being
/// built into the tree.
class _PushedRoutes extends NavigatorObserver {
  final _routes = <Route<dynamic>>[];

  Route<dynamic> get last => _routes.last;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _routes.add(route);
}
