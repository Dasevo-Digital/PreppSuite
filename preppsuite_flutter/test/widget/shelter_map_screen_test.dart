import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/maps/application/map_source_preference.dart';
import 'package:preppsuite_flutter/features/maps/application/offline_map_providers.dart';
import 'package:preppsuite_flutter/features/shelters/presentation/shelter_map_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';

class _NoOfflineMap extends OfflineMapController {
  @override
  Future<OfflineMapState> build() async => const OfflineMapState();
}

class _OnlineMapSource extends MapSourceController {
  @override
  MapSourcePreference build() => MapSourcePreference.online;
}

/// On a phone the map used to be fixed above the only scrollable portion,
/// together with a full-height legend. This checks that the page itself now
/// scrolls, its first view keeps the legend compact, and all of the guide is
/// still reachable when it is needed.
void main() {
  Future<void> show(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          offlineMapProvider.overrideWith(_NoOfflineMap.new),
          mapSourceProvider.overrideWith(_OnlineMapSource.new),
        ],
        child: const MaterialApp(
          locale: Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ShelterMapScreen(),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('keeps the map compact and all controls in one scroll view', (
    tester,
  ) async {
    await show(tester);

    expect(find.byType(ListView), findsOneWidget);
    expect(
      tester.getSize(find.byType(FlutterMap)).height,
      lessThanOrEqualTo(240),
    );
    expect(
      find.textContaining(
        'offiziell als nutzbarer Schutzraum bestätigt',
        findRichText: true,
      ),
      findsNothing,
    );

    await tester.tap(find.byType(ExpansionTile));
    await tester.pumpAndSettle();
    expect(
      find.textContaining(
        'offiziell als nutzbarer Schutzraum bestätigt',
        findRichText: true,
        skipOffstage: false,
      ),
      findsOneWidget,
    );

    final locationButton = find.text('Standort direkt untersuchen');
    await tester.dragUntilVisible(
      locationButton,
      find.byType(ListView),
      const Offset(0, -250),
    );
    expect(locationButton, findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
