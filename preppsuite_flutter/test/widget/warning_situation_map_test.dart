import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/maps/application/map_source_preference.dart';
import 'package:preppsuite_flutter/features/maps/application/offline_map_providers.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_providers.dart';
import 'package:preppsuite_flutter/features/warnings/presentation/warning_situation_map_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:preppsuite_flutter/local_db/database.dart';
import 'package:preppsuite_flutter/model/household_profile.dart';

class _NoOfflineMap extends OfflineMapController {
  @override
  Future<OfflineMapState> build() async => const OfflineMapState();
}

class _OnlineMapSource extends MapSourceController {
  @override
  MapSourcePreference build() => MapSourcePreference.online;
}

/// The map answers "what is active around me". This checks the question it
/// gained afterwards: what applies at one particular spot, which is what
/// somebody looking at three overlapping outlines actually wants to know.
void main() {
  final now = DateTime.utc(2026, 9, 18, 12);

  Warning warning({
    required String id,
    required String headline,
    required String polygons,
    String? instruction,
  }) => Warning(
    source: 'bbk',
    externalId: id,
    countryCode: 'DE',
    severity: 'severe',
    eventType: 'storm',
    headline: headline,
    instruction: instruction,
    polygonsJson: polygons,
    effective: now,
    sent: now,
    updatedAt: now,
    notified: false,
  );

  // A square over the north, and one over the south, touching nowhere.
  const north = '["52.6,10.0 53.0,10.0 53.0,11.0 52.6,11.0"]';
  const south = '["52.0,10.0 52.4,10.0 52.4,11.0 52.0,11.0"]';

  /// A tap on the map is answered only after the double-tap window has
  /// passed, and that window is a timer rather than an animation:
  /// `pumpAndSettle` alone returns before it fires and sees nothing.
  Future<void> tapMap(WidgetTester tester, Offset position) async {
    await tester.tapAt(position);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
  }

  Future<void> show(WidgetTester tester, List<Warning> warnings) async {
    await tester.binding.setSurfaceSize(const Size(600, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          offlineMapProvider.overrideWith(_NoOfflineMap.new),
          mapSourceProvider.overrideWith(_OnlineMapSource.new),
          activeWarningsProvider.overrideWith((ref) => Stream.value(warnings)),
        ],
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const WarningSituationMapScreen(
            profile: HouseholdProfile(
              id: 'home',
              name: 'Zuhause',
              countryCode: 'DE',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('says that the map can be asked', (tester) async {
    await show(tester, [
      warning(id: 'one', headline: 'Sturmböen', polygons: north),
    ]);

    expect(
      find.text('Tippe in die Karte, um zu sehen, was an einer Stelle gilt.'),
      findsOneWidget,
    );
    expect(find.byType(FlutterMap), findsOneWidget);
  });

  testWidgets('a tap answers with the warning covering that spot', (
    tester,
  ) async {
    await show(tester, [
      warning(
        id: 'north',
        headline: 'Sturmböen im Norden',
        polygons: north,
        instruction: 'Bleib im Haus.',
      ),
      warning(
        id: 'south',
        headline: 'Hochwasser im Sueden',
        polygons: south,
        instruction: 'Meide Uferwege.',
      ),
    ]);

    // Both squares are on the map, so the camera holds both; the upper
    // quarter of it is the northern one.
    final map = tester.getRect(find.byType(FlutterMap));
    await tapMap(tester, Offset(map.center.dx, map.top + map.height * 0.15));

    // Both headlines are in the list below the map either way, so the
    // answer has to be read inside the sheet.
    Finder inSheet(String text) => find.descendant(
      of: find.byType(BottomSheet),
      matching: find.text(text),
    );

    expect(find.text('An dieser Stelle'), findsOneWidget);
    expect(inSheet('Sturmböen im Norden'), findsOneWidget);
    expect(inSheet('Hochwasser im Sueden'), findsNothing);
    // What to do is the point of the question, so the instruction is in
    // the answer and not only the headline.
    expect(inSheet('Bleib im Haus.'), findsOneWidget);
    expect(find.text('Meide Uferwege.'), findsNothing);
  });

  testWidgets('a tap on open country says so instead of staying silent', (
    tester,
  ) async {
    await show(tester, [
      warning(id: 'north', headline: 'Sturmböen', polygons: north),
    ]);

    final map = tester.getRect(find.byType(FlutterMap));
    // Far to the side of a camera fitted to the single square.
    await tapMap(tester, Offset(map.left + 2, map.center.dy));

    expect(
      find.text('Hier liegt keine der angezeigten Warnflächen.'),
      findsOneWidget,
    );
  });
}
