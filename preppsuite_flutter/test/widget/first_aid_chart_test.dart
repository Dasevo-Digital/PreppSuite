import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/first_aid/application/first_aid_providers.dart';
import 'package:preppsuite_flutter/features/first_aid/presentation/first_aid_chart.dart';
import 'package:preppsuite_flutter/features/first_aid/presentation/first_aid_drawings.dart';
import 'package:preppsuite_flutter/features/first_aid/presentation/first_aid_guide_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';

import 'accessibility.dart';

/// A guide's picture chart: small on the guide, full size behind the
/// magnifier, and only in the language it was drawn in.
void main() {
  Future<void> show(
    WidgetTester tester,
    String guideId, {
    Locale locale = const Locale('de'),
  }) async {
    tester.view.physicalSize = const Size(420, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          installedFirstAidPackProvider.overrideWith(
            (ref) async => InstalledFirstAidPack.none,
          ),
        ],
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: FirstAidGuideScreen(guideId: guideId),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a German guide shows its chart in place of the drawing', (
    tester,
  ) async {
    await show(tester, 'choking');

    expect(find.byType(FirstAidChartThumbnail), findsOneWidget);
    expect(find.byType(FirstAidDrawingView), findsNothing);
    expect(find.byIcon(Icons.zoom_in), findsOneWidget);
  });

  testWidgets('the magnifier opens the chart full screen', (tester) async {
    await show(tester, 'croup');

    await tester.tap(find.byTooltip('Bildtafel vergrößern'));
    await tester.pumpAndSettle();

    expect(find.byType(FirstAidChartScreen), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.text('Pseudokrupp'), findsOneWidget);
  });

  testWidgets('in English the drawing stays, and there is no chart', (
    tester,
  ) async {
    await show(tester, 'choking', locale: const Locale('en'));

    expect(find.byType(FirstAidChartThumbnail), findsNothing);
    expect(find.byType(FirstAidDrawingView), findsOneWidget);
  });

  testWidgets('a guide without a chart keeps its drawing', (tester) async {
    await show(tester, 'recovery-position');

    expect(find.byType(FirstAidChartThumbnail), findsNothing);
    expect(find.byType(FirstAidDrawingView), findsOneWidget);
  });

  testWidgets('a guide with a chart meets the accessibility guidelines', (
    tester,
  ) async {
    await show(tester, 'stroke');
    await expectAccessible(tester);
  });
}
