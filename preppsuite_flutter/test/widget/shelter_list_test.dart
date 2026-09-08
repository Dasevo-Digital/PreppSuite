import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:preppsuite_flutter/features/shelters/application/shelter_classification.dart';
import 'package:preppsuite_flutter/features/shelters/presentation/shelter_list.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';

import 'accessibility.dart';

/// The shelters used to exist only as markers on a map, which for a screen
/// reader is an empty rectangle. What is checked here is that the list says
/// everything the markers said and the two things they could not: how far,
/// and which way.
void main() {
  const hannover = LatLng(52.3759, 9.7320);

  ClassifiedShelter shelter({
    required String id,
    required String name,
    required double lat,
    required double lon,
    ShelterConfidence confidence = ShelterConfidence.yellow,
    String source = 'OpenStreetMap',
  }) => ClassifiedShelter(
    id: id,
    name: name,
    lat: lat,
    lon: lon,
    confidence: confidence,
    sourceLabel: source,
  );

  /// 500 m due north, and 3 km due east — far enough apart to tell the
  /// ordering from the input order.
  final near = shelter(
    id: 'a',
    name: 'Hochbunker Nordstadt',
    lat: 52.3759 + 0.0045,
    lon: 9.7320,
    confidence: ShelterConfidence.green,
  );
  final far = shelter(
    id: 'b',
    name: 'Stollen Ost',
    lat: 52.3759,
    lon: 9.7320 + 0.0442,
    confidence: ShelterConfidence.red,
    source: 'WWBOTA/DLBOTA',
  );

  Future<List<ClassifiedShelter>> show(
    WidgetTester tester, {
    required List<ClassifiedShelter> shelters,
    LatLng? center = hannover,
  }) async {
    final shown = <ClassifiedShelter>[];
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => SingleChildScrollView(
              child: ShelterList(
                shelters: shelters,
                center: center,
                l10n: AppLocalizations.of(context)!,
                colorFor: (_) => Colors.green,
                onShow: shown.add,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return shown;
  }

  testWidgets('every shelter is named, with how far and which way', (
    tester,
  ) async {
    await show(tester, shelters: [near]);

    expect(find.text('Hochbunker Nordstadt'), findsOneWidget);
    expect(
      find.text('500 m nördlich · Grün · OpenStreetMap'),
      findsOneWidget,
    );
  });

  testWidgets('the nearest one comes first, whatever order they arrive in', (
    tester,
  ) async {
    // The two sources are concatenated in the order they answered, which
    // for a list of places to walk to is no order at all.
    await show(tester, shelters: [far, near]);

    final titles = tester
        .widgetList<ListTile>(find.byType(ListTile))
        .map((tile) => (tile.title! as Text).data)
        .toList();
    expect(titles, ['Hochbunker Nordstadt', 'Stollen Ost']);
  });

  testWidgets('a distance over a kilometre is given in kilometres', (
    tester,
  ) async {
    await show(tester, shelters: [far]);

    expect(find.textContaining('3.0 km östlich'), findsOneWidget);
  });

  testWidgets('the grade is a word, not only the colour of the shield', (
    tester,
  ) async {
    // Three shields differing in nothing but green, amber and red are
    // three identical shields to anyone who cannot tell those apart.
    await show(tester, shelters: [near, far]);

    expect(find.textContaining('Grün'), findsOneWidget);
    expect(find.textContaining('Rot'), findsOneWidget);
  });

  testWidgets('tapping an entry asks for it on the map', (tester) async {
    final shown = await show(tester, shelters: [near, far]);

    await tester.tap(find.text('Stollen Ost'));
    await tester.pumpAndSettle();

    expect(shown.single.id, 'b');
  });

  testWidgets('nothing found says so instead of showing an empty list', (
    tester,
  ) async {
    await show(tester, shelters: []);

    expect(find.textContaining('In diesem Umkreis nichts'), findsOneWidget);
  });

  testWidgets('without a location there is nothing to measure from', (
    tester,
  ) async {
    // The distances would all be measured from the middle of Germany,
    // which is not where anybody is.
    await show(tester, shelters: [near], center: null);

    expect(find.byType(ListTile), findsNothing);
    expect(find.text('Hochbunker Nordstadt'), findsNothing);
  });

  testWidgets('the list meets the accessibility guidelines', (tester) async {
    await show(tester, shelters: [near, far]);
    await expectAccessible(tester);
  });
}
