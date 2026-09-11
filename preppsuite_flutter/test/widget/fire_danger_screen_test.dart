import 'dart:convert';
import 'dart:io' show gzip;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:preppsuite_flutter/features/warnings/application/fire_danger_client.dart';
import 'package:preppsuite_flutter/features/warnings/application/fire_danger_store.dart';
import 'package:preppsuite_flutter/features/warnings/presentation/fire_danger_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'accessibility.dart';

/// Watching the forest fire danger index.
///
/// The figures are Braunschweig as published on 2026-09-11: level 2
/// today, then 2 1 1 1 1 1. The days ahead are the reason this is a
/// screen — level 2 today with level 5 on Friday is a different week,
/// and both read as "2" if only today is shown.
void main() {
  /// The station list is Latin-1 on the wire, which is the one encoding
  /// question this feature has.
  final stations = latin1.encode(
    'Stationsindex; Höhe in m;Breite   ;Länge    ;Name        ;Bundesland\n'
    '          662;        81;    52.29;    10.45;Braunschweig;Niedersachsen\n'
    '           44;        44;    52.93;     8.24;Großenkneten;Niedersachsen\n'
    '        20098;      1019;    48.57;     8.23;Seebach     ;Baden-Württemberg\n',
  );

  List<int> forecastBody(String row) =>
      gzip.encode(utf8.encode('StationsID;Termin;a;b;c;d;e;f;g\n$row\n'));

  FireDangerClient client({
    String row = '662;20260911 04:14;2;2;1;1;1;1;1',
    bool forecastFails = false,
    bool stationsFail = false,
  }) => FireDangerClient(
    httpClient: MockClient.streaming((request, _) async {
      final path = request.url.path;
      if (path.endsWith('stations_list.txt')) {
        return stationsFail
            ? http.StreamedResponse(const Stream.empty(), 503)
            : http.StreamedResponse(Stream.value(stations), 200);
      }
      if (forecastFails) {
        return http.StreamedResponse(const Stream.empty(), 404);
      }
      return http.StreamedResponse(Stream.value(forecastBody(row)), 200);
    }),
  );

  Future<void> show(
    WidgetTester tester, {
    FireDangerClient? fire,
    DateTime? now,
  }) async {
    await tester.binding.setSurfaceSize(const Size(500, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: FireDangerScreen(
          client: fire ?? client(),
          now: now ?? DateTime(2026, 9, 11, 9),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> choose(WidgetTester tester, String name) async {
    await tester.tap(find.text('Station wählen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(name).last);
    await tester.pumpAndSettle();
  }

  testWidgets('nothing is shown until a station is chosen', (tester) async {
    await show(tester);

    expect(find.text('Noch keine Station gewählt'), findsOneWidget);
    // And it says what it is not before it says any level.
    expect(find.textContaining('keine Warnung'), findsWidgets);
    expect(find.textContaining('Betretungsverbot'), findsWidgets);
  });

  testWidgets('the DWD is named as the source', (tester) async {
    await show(tester);

    expect(find.textContaining('Deutscher Wetterdienst'), findsWidgets);
  });

  testWidgets('a chosen station shows today’s level in the DWD’s words', (
    tester,
  ) async {
    await show(tester);
    await choose(tester, 'Braunschweig');

    expect(find.text('Geringe Gefahr'), findsWidgets);
    // The number as well as the word, because the DWD's own signs say
    // "Stufe 2" and a colour alone is unreadable to many people.
    expect(find.text('Stufe 2 von 5'), findsOneWidget);
    expect(find.textContaining('Niedersachsen'), findsWidgets);
  });

  testWidgets('all seven days are listed, today first', (tester) async {
    await show(tester);
    await choose(tester, 'Braunschweig');

    expect(find.text('Heute'), findsOneWidget);
    expect(find.text('Morgen'), findsOneWidget);
    expect(find.text('In 6 Tagen'), findsOneWidget);
  });

  testWidgets('a rise later in the week is said out loud', (tester) async {
    await show(
      tester,
      fire: client(row: '662;20260911 04:14;2;2;3;5;4;2;1'),
    );
    await choose(tester, 'Braunschweig');

    expect(find.text('Steigt auf Stufe 5 in 3 Tagen'), findsOneWidget);
  });

  testWidgets('a rise tomorrow is said as tomorrow', (tester) async {
    await show(
      tester,
      fire: client(row: '662;20260911 04:14;1;4;1;1;1;1;1'),
    );
    await choose(tester, 'Braunschweig');

    expect(find.text('Steigt morgen auf Stufe 4'), findsOneWidget);
  });

  testWidgets('a week that only falls says nothing about a rise', (
    tester,
  ) async {
    await show(
      tester,
      fire: client(row: '662;20260911 04:14;4;3;2;1;1;1;1'),
    );
    await choose(tester, 'Braunschweig');

    expect(find.textContaining('Steigt'), findsNothing);
  });

  testWidgets('out of season the date is shown rather than passed off', (
    tester,
  ) async {
    // The DWD issues March to October. In January the newest row is
    // from last autumn, and showing its level as today's would be a
    // lie the rest of the screen cannot correct.
    await show(
      tester,
      fire: client(row: '662;20251030 04:14;3;3;2;2;1;1;1'),
      now: DateTime(2026, 1, 15),
    );
    await choose(tester, 'Braunschweig');

    expect(find.textContaining('nicht von heute'), findsOneWidget);
    expect(find.textContaining('Waldbrandsaison'), findsOneWidget);
  });

  testWidgets('a failed fetch keeps the last forecast and says so', (
    tester,
  ) async {
    await show(tester);
    await choose(tester, 'Braunschweig');
    expect(find.text('Stufe 2 von 5'), findsOneWidget);

    // A second screen over the same preferences, with the server down.
    // The key forces a fresh state; without one Flutter reuses the
    // element and `initState` never runs again.
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: FireDangerScreen(
          key: UniqueKey(),
          client: client(forecastFails: true),
          now: DateTime(2026, 9, 11, 9),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Letzter bekannter Stand'), findsOneWidget);
    expect(find.text('Stufe 2 von 5'), findsOneWidget);
  });

  testWidgets('the picker searches by place and by Bundesland', (
    tester,
  ) async {
    await show(tester);
    await tester.tap(find.text('Station wählen'));
    await tester.pumpAndSettle();

    expect(find.text('Großenkneten'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'baden');
    await tester.pumpAndSettle();
    expect(find.text('Seebach'), findsOneWidget);
    expect(find.text('Braunschweig'), findsNothing);
  });

  testWidgets('a picker that cannot reach the server does not crash', (
    tester,
  ) async {
    await show(tester, fire: client(stationsFail: true));
    await tester.tap(find.text('Station wählen'));
    await tester.pumpAndSettle();

    expect(find.textContaining('konnte nicht geladen werden'), findsWidgets);
  });

  testWidgets('the chosen station survives a restart', (tester) async {
    await show(tester);
    await choose(tester, 'Großenkneten');

    final stored = await const FireDangerStore().loadStation();
    expect(stored?.name, 'Großenkneten');
    expect(stored?.id, '44');
  });

  testWidgets('the fire danger screen meets the accessibility guidelines', (
    tester,
  ) async {
    await show(tester);
    await choose(tester, 'Braunschweig');
    await expectAccessible(tester);
  });

  testWidgets('the fire danger screen survives twice the font size', (
    tester,
  ) async {
    useLargeText(tester);
    await show(tester);
    await choose(tester, 'Braunschweig');
  });
}
