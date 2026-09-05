import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_region_filter.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_region_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  const store = WarningRegionStore();

  test('nothing stored yet reads back as null', () async {
    // Distinct from "Germany with no region": the worker must be able to
    // tell "not set up" from "set up without a region".
    expect(await store.load(), isNull);
  });

  test('a full filter round-trips', () async {
    await store.save(
      const WarningRegionFilter(
        countryCode: 'DE',
        ownRegionKey: '053340000000',
        extraRegions: [
          WarningRegion(kind: WarningRegionKind.kreis, value: '09162'),
          WarningRegion(kind: WarningRegionKind.bundesland, value: 'BY'),
        ],
      ),
    );

    final loaded = await store.load();

    expect(loaded!.countryCode, 'DE');
    expect(loaded.ownRegionKey, '053340000000');
    expect(loaded.ownKreisSchluessel, '05334');
    expect(loaded.extraRegions, hasLength(2));
    expect(loaded.extraRegions.first.value, '09162');
  });

  test('clearing the region does not leave the old one behind', () async {
    // Someone who removes their region must stop being filtered by it,
    // not keep the previous value forever.
    await store.save(
      const WarningRegionFilter(countryCode: 'DE', ownRegionKey: '05334000'),
    );
    await store.save(const WarningRegionFilter(countryCode: 'DE'));

    final loaded = await store.load();

    expect(loaded!.ownRegionKey, isNull);
    expect(loaded.hasAnyRegion, isFalse);
  });

  test('an unparseable stored region is skipped, not crashed on', () async {
    SharedPreferences.setMockInitialValues({
      'warningCountryCode': 'DE',
      'warningExtraRegions': ['kreis:09162', 'nonsense'],
    });

    final loaded = await store.load();

    expect(loaded!.extraRegions, hasLength(1));
  });
}
