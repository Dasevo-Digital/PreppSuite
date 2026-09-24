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
/// together with a full-height legend. The map attribution's information
/// affordance already explains its source, so the page now keeps the map and
/// the actions in the one scroll view without repeating a large guide above it.
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

  testWidgets('keeps the map compact without a duplicate marker guide', (
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
    expect(find.byType(ExpansionTile), findsNothing);

    final locationButton = find.text('Standort direkt untersuchen');
    await tester.dragUntilVisible(
      locationButton,
      find.byType(ListView),
      const Offset(0, -250),
    );
    expect(locationButton, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('explains the marker colours behind the info button', (
    tester,
  ) async {
    // Off the page, not out of the app. Three colours where red means
    // "not released, historic or for information only" are not
    // self-explanatory, and the sentence saying this map replaces no
    // official instruction had nowhere left to stand.
    await show(tester);

    await tester.tap(find.byIcon(Icons.info_outline));
    await tester.pumpAndSettle();

    expect(
      find.textContaining(
        'offiziell als nutzbarer Schutzraum bestätigt',
        findRichText: true,
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        'nicht freigegeben, historisch oder nur Infozweck',
        findRichText: true,
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining('ersetzt keine behördliche Warnung'),
      findsOneWidget,
    );
  });
}
