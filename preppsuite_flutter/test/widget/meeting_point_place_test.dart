import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:preppsuite_flutter/core/app_database_providers.dart';
import 'package:preppsuite_flutter/features/household/application/household_plan_controller.dart';
import 'package:preppsuite_flutter/core/geolocation_service.dart';
import 'package:preppsuite_flutter/features/household/application/meeting_point_places.dart';
import 'package:preppsuite_flutter/features/household/presentation/household_plan_screen.dart';
import 'package:preppsuite_flutter/features/household/presentation/meeting_point_way.dart';
import 'package:preppsuite_flutter/features/maps/application/map_source_preference.dart';
import 'package:preppsuite_flutter/features/maps/application/offline_map_providers.dart';
import 'package:preppsuite_flutter/features/maps/application/personal_place.dart';
import 'package:preppsuite_flutter/features/maps/presentation/place_picker_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:preppsuite_flutter/local_db/database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NoOfflineMap extends OfflineMapController {
  @override
  Future<OfflineMapState> build() async => const OfflineMapState();
}

class _FixedSource extends MapSourceController {
  @override
  MapSourcePreference build() => MapSourcePreference.offline;
}

/// The device's own places, in memory: the real store sits behind the
/// encrypted preferences, which a widget test's clock does not turn.
class _MemoryStore extends PersonalPlaceStore {
  _MemoryStore([List<PersonalPlace> places = const []]) : places = [...places];

  List<PersonalPlace> places;

  @override
  Future<List<PersonalPlace>> load() async => [...places];

  @override
  Future<void> save(List<PersonalPlace> places) async =>
      this.places = [...places];
}

class _FixedPosition extends GeolocationService {
  _FixedPosition(this.here);

  final LatLng here;

  @override
  Future<LatLng> getCurrentLatLng() async => here;
}

Widget _app(Widget home, {List overrides = const []}) => ProviderScope(
  overrides: [
    offlineMapProvider.overrideWith(_NoOfflineMap.new),
    mapSourceProvider.overrideWith(_FixedSource.new),
    ...overrides.cast(),
  ],
  child: MaterialApp(
    locale: const Locale('de'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  ),
);

/// The meeting points on the map, on this device only (#204).
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('in the household plan', () {
    late AppDatabase db;

    setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
    tearDown(() => db.close());

    late _MemoryStore store;

    Future<void> pump(
      WidgetTester tester, [
      List<PersonalPlace> places = const [],
    ]) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      store = _MemoryStore(places);
      await tester.pumpWidget(
        _app(
          const HouseholdPlanScreen(householdId: 'h'),
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            // A plain value: a drift stream needs the event loop to turn.
            householdPlanProvider('h')
                .overrideWith((ref) => Stream.value(null)),
            meetingPointStoreProvider.overrideWithValue(
              MeetingPointPlaces(store),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('each meeting point offers to be put on the map', (
      tester,
    ) async {
      await pump(tester);

      expect(find.text('Ort auf der Karte festlegen'), findsNWidgets(2));
    });

    testWidgets('a point on the map shows where it is, that it stays on '
        'this device, and comes off again', (tester) async {
      await pump(tester, const [
        PersonalPlace(
          id: 'meetingPoint.near',
          label: 'Vor der Garage',
          latitude: 52.2689,
          longitude: 10.5268,
        ),
      ]);

      expect(find.text('52.26890, 10.52680'), findsOneWidget);
      expect(find.textContaining('Nur auf diesem Gerät'), findsOneWidget);
      expect(find.text('Ort auf der Karte festlegen'), findsOneWidget);

      await tester.tap(find.byTooltip('Von der Karte nehmen'));
      await tester.pumpAndSettle();

      expect(find.text('52.26890, 10.52680'), findsNothing);
      expect(store.places, isEmpty);
    });
  });

  testWidgets('the picker hands back the point where the device is', (
    tester,
  ) async {
    LatLng? chosen;
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async =>
                chosen = await Navigator.of(context).push<LatLng>(
                  MaterialPageRoute(
                    builder: (_) => PlacePickerScreen(
                      title: 'Treffpunkt',
                      geolocation: _FixedPosition(
                        const LatLng(52.2689, 10.5268),
                      ),
                    ),
                  ),
                ),
            child: const Text('öffnen'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('öffnen'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.byTooltip('Mein Standort'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Diesen Punkt nehmen'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(chosen, const LatLng(52.2689, 10.5268));
  });

  testWidgets('the way there is a distance and a direction', (tester) async {
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: MeetingPointWayButton(
            place: const PersonalPlace(
              id: 'meetingPoint.near',
              label: 'Vor der Garage',
              latitude: 52.27,
              longitude: 10.52,
            ),
            geolocation: _FixedPosition(const LatLng(52.26, 10.52)),
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Wie weit, welche Richtung'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Vor der Garage'), findsOneWidget);
    expect(find.text('1,1 km nördlich'), findsOneWidget);
    expect(find.text('52.27000, 10.52000'), findsOneWidget);
  });
}
