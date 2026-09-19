import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/maps/presentation/map_zoom_buttons.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('zoom control cannot cover a wide map', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 300,
            child: Stack(
              children: [MapZoomButtons(controller: MapController())],
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(Card)), const Size(48, 97));
  });
}
