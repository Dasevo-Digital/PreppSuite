import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:preppsuite_flutter/core/feature_activity.dart';
import 'package:preppsuite_flutter/features/maps/application/map_source_preference.dart';
import 'package:preppsuite_flutter/features/maps/application/offline_map_providers.dart';
import 'package:preppsuite_flutter/features/maps/presentation/base_map_layer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NoOfflineMap extends OfflineMapController {
  @override
  Future<OfflineMapState> build() async => const OfflineMapState();
}

class _Online extends MapSourceController {
  @override
  MapSourcePreference build() => MapSourcePreference.online;
}

/// How long a map that is no longer on screen keeps its renderer.
///
/// It used to be dropped the instant the tab lost focus, which made
/// every return to the map a cold start — the parsed-tile cache went
/// with it. Measured on a 1.9 GB country extract, reading and decoding a
/// screenful of 48 tiles is 117 ms, and that was being repeated for
/// nothing every time somebody looked at another tab and came back.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  /// The map inside a switchable [FeatureActivity], the way `HomeShell`
  /// puts it there.
  Future<void> show(WidgetTester tester, ValueNotifier<bool> active) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          offlineMapProvider.overrideWith(_NoOfflineMap.new),
          mapSourceProvider.overrideWith(_Online.new),
        ],
        child: MaterialApp(
          home: ValueListenableBuilder<bool>(
            valueListenable: active,
            builder: (context, value, _) => FeatureActivity(
              active: value,
              child: FlutterMap(
                options: const MapOptions(
                  initialCenter: LatLng(52.2689, 10.5268),
                  initialZoom: 10,
                ),
                children: const [BaseMapLayer()],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }

  bool rendererPresent() => find.byType(TileLayer).evaluate().isNotEmpty;

  testWidgets('the map on screen has its renderer', (tester) async {
    final active = ValueNotifier(true);
    addTearDown(active.dispose);
    await show(tester, active);

    expect(rendererPresent(), isTrue);
  });

  testWidgets('leaving the tab does not drop it straight away', (
    tester,
  ) async {
    final active = ValueNotifier(true);
    addTearDown(active.dispose);
    await show(tester, active);

    active.value = false;
    await tester.pump();

    expect(rendererPresent(), isTrue);
  });

  testWidgets('coming straight back keeps the warm renderer', (tester) async {
    final active = ValueNotifier(true);
    addTearDown(active.dispose);
    await show(tester, active);

    active.value = false;
    await tester.pump(const Duration(seconds: 5));
    active.value = true;
    await tester.pump();

    expect(rendererPresent(), isTrue);
  });

  testWidgets('staying away long enough gives the memory back', (
    tester,
  ) async {
    final active = ValueNotifier(true);
    addTearDown(active.dispose);
    await show(tester, active);

    active.value = false;
    await tester.pump();
    // Past the grace period. There are two map destinations and their
    // caches are 48 MiB each on desktop, so this has to actually happen.
    await tester.pump(BaseMapLayer.releaseGrace + const Duration(seconds: 1));

    expect(rendererPresent(), isFalse);
  });

  testWidgets('and returning after that rebuilds it', (tester) async {
    final active = ValueNotifier(true);
    addTearDown(active.dispose);
    await show(tester, active);

    active.value = false;
    await tester.pump();
    await tester.pump(BaseMapLayer.releaseGrace + const Duration(seconds: 1));
    expect(rendererPresent(), isFalse);

    active.value = true;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(rendererPresent(), isTrue);
  });
}
