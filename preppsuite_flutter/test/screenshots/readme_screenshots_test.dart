import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:preppsuite_flutter/app.dart' show appSeedColor;
import 'package:preppsuite_flutter/features/daylight/application/daylight_store.dart';
import 'package:preppsuite_flutter/features/daylight/presentation/daylight_screen.dart';
import 'package:preppsuite_flutter/features/energy/application/energy_range.dart';
import 'package:preppsuite_flutter/features/energy/application/energy_store.dart';
import 'package:preppsuite_flutter/features/energy/presentation/energy_screen.dart';
import 'package:preppsuite_flutter/features/home/presentation/radio_emergency_screen.dart';
import 'package:preppsuite_flutter/features/knowledge/presentation/article_reader_screen.dart';
import 'package:preppsuite_flutter/features/maps/application/offline_map_providers.dart';
import 'package:preppsuite_flutter/features/maps/application/pmtiles_archive.dart';
import 'package:preppsuite_flutter/features/maps/presentation/nearby_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/fixture_http_client.dart';
import '../features/maps/offline_poi_tile.dart';
import '../features/maps/pmtiles_fixture.dart';

/// Renders the screenshots the README shows.
///
/// Not part of the ordinary suite — run it on purpose:
///
///     PREPPSUITE_SCREENSHOTS=1 flutter test test/screenshots
///
/// Why rendered rather than photographed off a running app: these are the
/// app's own widgets, its own colour scheme and its own layout, with data
/// chosen to show what a screen is *for* rather than whatever happened to
/// be on the machine. And they can be made again after the next change to
/// the interface, which a screenshot taken by hand cannot.
///
/// The one thing that differs from a running app is the typeface: a test
/// renders with a blank placeholder font unless one is loaded, so the
/// bundled Noto Sans is loaded here. On a real machine the app uses
/// whatever the system offers.
void main() {
  final wanted = Platform.environment['PREPPSUITE_SCREENSHOTS'] == '1';

  late Directory output;
  late Directory workspace;

  setUpAll(() async {
    final text = FontLoader('Noto Sans')
      ..addFont(rootBundle.load('assets/fonts/NotoSans-Regular.ttf'));
    await text.load();

    // The icons too, or every one of them renders as an empty square. A
    // test renders with a blank placeholder font unless one is loaded,
    // and the icon font lives in the Flutter installation rather than in
    // this project — so it is looked for beside the `flutter` on the
    // path, and the run says so plainly if it is not there.
    final icons = File(
      '${_flutterRoot()}/bin/cache/artifacts/material_fonts/'
      'MaterialIcons-Regular.otf',
    );
    expect(
      icons.existsSync(),
      isTrue,
      reason: 'icon font not found at ${icons.path}',
    );
    final iconLoader = FontLoader('MaterialIcons')
      ..addFont(
        Future.value(ByteData.sublistView(icons.readAsBytesSync())),
      );
    await iconLoader.load();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    output = Directory('${Directory.current.path}/../docs/bilder')
      ..createSync(recursive: true);
    workspace = Directory.systemTemp.createTempSync('shots');
  });
  tearDown(() => workspace.deleteSync(recursive: true));

  /// A phone, at twice the resolution — the size a README image is
  /// looked at on a laptop.
  const size = Size(430, 932);
  const scale = 2.0;

  /// Renders [home] and writes it out as `<name>.png`.
  ///
  /// [wrap] puts something around the app where a screen needs a provider
  /// standing in — a function rather than a list of overrides, because
  /// `flutter_riverpod` does not export the type that list would have.
  Future<void> shoot(
    WidgetTester tester,
    String name,
    Widget home, {
    Widget Function(Widget child)? wrap,
  }) async {
    tester.view.physicalSize = size * scale;
    tester.view.devicePixelRatio = scale;
    addTearDown(tester.view.reset);

    final key = GlobalKey();
    final app = RepaintBoundary(
      key: key,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(
          colorSchemeSeed: appSeedColor,
          useMaterial3: true,
          fontFamily: 'Noto Sans',
        ),
        home: home,
      ),
    );
    await tester.pumpWidget(
      wrap == null ? ProviderScope(child: app) : wrap(app),
    );

    // Real file reads and a real isolate in the nearby search: neither
    // moves under the test binding's fake clock, so the turns alternate.
    for (var turn = 0; turn < 10; turn++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }

    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: scale);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File(
        '${output.path}/$name.png',
      ).writeAsBytesSync(bytes!.buffer.asUint8List());
      image.dispose();
    });
    stdout.writeln('  $name.png');
  }

  testWidgets('In der Nähe', (tester) async {
    // A slice of Braunschweig, in the tiles the map itself draws from.
    final file = File('${workspace.path}/area.pmtiles')
      ..writeAsBytesSync(
        buildBinaryArchive(
          tiles: {
            (14, 8671, 5391): poiTile(const [
              (
                subclass: 'pharmacy',
                name: 'Apotheke am Markt',
                x: 2048,
                y: 2048,
              ),
              (subclass: 'pharmacy', name: 'Löwen-Apotheke', x: 2200, y: 2100),
              (
                subclass: 'doctors',
                name: 'Praxis Dr. Reinecke',
                x: 2300,
                y: 2000,
              ),
              (subclass: 'hospital', name: 'Klinikum', x: 2600, y: 1800),
              (subclass: 'drinking_water', name: null, x: 2100, y: 2050),
              (
                subclass: 'supermarket',
                name: 'Markt am Bohlweg',
                x: 1900,
                y: 2200,
              ),
              (
                subclass: 'bakery',
                name: 'Bäckerei Steinecke',
                x: 2000,
                y: 2150,
              ),
              (
                subclass: 'fuel',
                name: 'Tankstelle Celler Straße',
                x: 2500,
                y: 2400,
              ),
              (
                subclass: 'charging_station',
                name: 'Ladesäule Schlossplatz',
                x: 2060,
                y: 2060,
              ),
              (
                subclass: 'fire_station',
                name: 'Feuerwache 1',
                x: 2700,
                y: 2300,
              ),
              (
                subclass: 'doityourself',
                name: 'Baumarkt Hamburger Straße',
                x: 2800,
                y: 2500,
              ),
            ]),
          },
          bounds: (9.0, 51.0, 12.0, 53.0),
        ),
      );

    PmTilesArchive? archive;
    await tester.runAsync(() async {
      archive = await PmTilesArchive.open(await FileByteRangeSource.open(file));
    });
    // Closed without waiting: awaiting it outside `runAsync` never
    // returns under the test binding's fake clock, and the handle goes
    // away with the temporary directory anyway.
    addTearDown(() => unawaited(archive?.close() ?? Future<void>.value()));

    await shoot(
      tester,
      'in-der-naehe',
      const NearbyScreen(
        centre: LatLng(52.2689, 10.5268),
        centreLabel: 'Kartenmitte',
      ),
      wrap: (child) => ProviderScope(
        overrides: [
          offlineMapProvider.overrideWith(
            () => _FixedMap(
              OfflineMapState(label: 'Niedersachsen', archive: archive),
            ),
          ),
        ],
        child: child,
      ),
    );
  }, skip: !wanted);

  testWidgets('Tageslicht und Mond', (tester) async {
    await const DaylightStore().save(
      const DaylightPlace(
        latitude: 52.2689,
        longitude: 10.5268,
        name: 'Braunschweig',
      ),
    );
    await shoot(
      tester,
      'tageslicht-und-mond',
      DaylightScreen(now: DateTime(2026, 12, 21, 12)),
    );
  }, skip: !wanted);

  testWidgets('Energie und Brennstoff', (tester) async {
    await const EnergyPlanStore().save(
      const EnergyPlan(
        reserves: [
          EnergyReserve(
            id: 'a',
            kind: EnergyKind.gas,
            label: 'Sechs Kartuschen',
            amount: 1380,
          ),
          EnergyReserve(
            id: 'b',
            kind: EnergyKind.electricity,
            label: 'Zwei Powerbanks',
            amount: 148,
          ),
          EnergyReserve(
            id: 'c',
            kind: EnergyKind.candles,
            label: '40 Teelichter à 4 h',
            amount: 160,
          ),
        ],
        draws: [
          EnergyDraw(
            id: 'd',
            kind: EnergyKind.gas,
            label: 'Gaskocher',
            perHour: 160,
            hoursPerDay: 1,
          ),
          EnergyDraw(
            id: 'e',
            kind: EnergyKind.electricity,
            label: 'Radio',
            perHour: 2,
            hoursPerDay: 5,
          ),
          EnergyDraw(
            id: 'f',
            kind: EnergyKind.candles,
            label: 'Abendlicht',
            perHour: 1,
            hoursPerDay: 6,
          ),
        ],
      ),
    );
    await shoot(tester, 'energie-und-brennstoff', const EnergyScreen());
  }, skip: !wanted);

  testWidgets('Artikel ohne Browser-Komponente', (tester) async {
    await shoot(
      tester,
      'artikel-einfache-ansicht',
      ArticleReaderScreen(
        title: 'Trinkwasser',
        uri: Uri.parse('http://127.0.0.1:8080/A/Trinkwasser'),
        client: FixtureHttpClient({
          'http://127.0.0.1:8080/A/Trinkwasser': _article,
        }),
      ),
    );
  }, skip: !wanted);

  testWidgets('Notfunk', (tester) async {
    await shoot(tester, 'notfunk', const RadioEmergencyScreen());
  }, skip: !wanted);
}

/// Stands in for the controller that opens the map archive.
class _FixedMap extends OfflineMapController {
  _FixedMap(this._state);

  final OfflineMapState _state;

  @override
  Future<OfflineMapState> build() async => _state;
}

const _article = '''
<html><head><title>Trinkwasser</title></head><body>
<p><b>Trinkwasser</b> ist Wasser, das für den menschlichen Gebrauch
bestimmt ist und den Anforderungen der Trinkwasserverordnung genügt.</p>
<h2>Bedarf</h2>
<p>Das Bundesamt für Bevölkerungsschutz und Katastrophenhilfe empfiehlt,
je Person und Tag mit zwei Litern zu rechnen: anderthalb Liter zum
Trinken und einen halben Liter zum Kochen.</p>
<ul>
  <li>Erwachsene: 2 Liter am Tag</li>
  <li>Kinder bis zwölf: 1 Liter Getränke am Tag</li>
  <li>Haustiere: rund 60 ml je Kilogramm</li>
</ul>
<h2>Gewinnung</h2>
<p>Gewonnen wird es aus <a href="Grundwasser">Grundwasser</a>,
<a href="Quellwasser">Quellwasser</a> und aufbereitetem Oberflächenwasser.</p>
<h2>Grenzwerte</h2>
<p>Die Trinkwasserverordnung nennt für einzelne Stoffe Höchstwerte:</p>
<table>
  <tr><th>Stoff</th><th>Grenzwert</th></tr>
  <tr><td>Blei</td><td>0,010 mg/l</td></tr>
  <tr><td>Nitrat</td><td>50 mg/l</td></tr>
  <tr><td>Kupfer</td><td>2,0 mg/l</td></tr>
</table>
<h2>Lagerung</h2>
<p>Abgefülltes Wasser hält sich in dunkler, kühler Lagerung mehrere
Monate. Behälter aus lebensmittelechtem Kunststoff sind dafür
geeignet, Kanister aus dem Baumarkt nicht ohne Weiteres.</p>
</body></html>
''';

/// The Flutter installation this test is running under.
String _flutterRoot() {
  // `Platform.resolvedExecutable` is the Dart inside the SDK that ships
  // with Flutter: <root>/bin/cache/dart-sdk/bin/dart.
  var directory = Directory(Platform.resolvedExecutable).parent;
  for (var level = 0; level < 6; level++) {
    if (Directory('${directory.path}/bin/cache/artifacts').existsSync()) {
      return directory.path;
    }
    directory = directory.parent;
  }
  return '';
}
