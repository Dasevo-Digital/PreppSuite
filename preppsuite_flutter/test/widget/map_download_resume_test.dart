import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/maps/application/map_area_download.dart';
import 'package:preppsuite_flutter/features/maps/application/map_download_plan.dart';
import 'package:preppsuite_flutter/features/maps/application/map_download_providers.dart';
import 'package:preppsuite_flutter/features/maps/application/map_download_session.dart';
import 'package:preppsuite_flutter/features/maps/presentation/map_download_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'accessibility.dart';

/// What somebody sees on opening the screen after the app was closed
/// part-way through a country.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final session = MapDownloadSession(
    plan: MapDownloadPlan([
      MapDownloadStep(
        label: 'Deutschland',
        area: const MapArea(
          minLongitude: 5.8663,
          minLatitude: 47.2701,
          maxLongitude: 15.0419,
          maxLatitude: 55.0992,
          maxZoom: 12,
        ),
      ),
    ]),
    targetPath: '/tmp/karte.pmtiles',
    label: 'Hannover (14)',
    startedAt: DateTime(2026, 9, 6),
  );

  Future<void> show(
    WidgetTester tester, {
    ({MapDownloadSession session, int stored})? unfinished,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          unfinishedDownloadProvider.overrideWith((ref) async => unfinished),
        ],
        child: const MaterialApp(
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

  testWidgets('an interrupted download is offered again', (tester) async {
    await show(tester, unfinished: (session: session, stored: 8123));

    expect(find.text('Unterbrochener Download'), findsOneWidget);
    expect(
      find.text(
        'Hannover (14) — 8123 von ${session.plan.tileCount} Kacheln sind '
        'schon da.',
      ),
      findsOneWidget,
    );
    expect(find.text('Fortsetzen'), findsOneWidget);
    expect(find.text('Verwerfen'), findsOneWidget);

    // Starting something else has to stay possible, so the chooser is
    // still there underneath.
    expect(find.text('Ort, Kreis, Bundesland oder Land'), findsOneWidget);
    expect(find.text('Karte herunterladen'), findsOneWidget);
  });

  testWidgets('with nothing unfinished the screen is as before', (
    tester,
  ) async {
    await show(tester);

    expect(find.text('Unterbrochener Download'), findsNothing);
    expect(find.text('Fortsetzen'), findsNothing);
    expect(find.text('Sichtbarer Ausschnitt'), findsOneWidget);
  });

  testWidgets('the resume offer meets the accessibility guidelines', (
    tester,
  ) async {
    await show(tester, unfinished: (session: session, stored: 8123));
    await expectAccessible(tester);
  });

  testWidgets('the resume offer survives twice the font size', (
    tester,
  ) async {
    useLargeText(tester);
    await show(tester, unfinished: (session: session, stored: 8123));
  });
}
