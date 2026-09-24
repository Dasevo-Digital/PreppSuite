import '../../../core/private_preferences.dart';
import 'warning_region_filter.dart';

const _countryKey = 'warningCountryCode';
const _regionKey = 'warningRegionKey';
const _extraRegionsKey = 'warningExtraRegions';

/// Persists which regions this device follows, so the background worker can
/// read them.
///
/// The worker runs in its own isolate with no session, no Riverpod and no
/// household fetched from anywhere — preferences are the only thing both
/// sides can see. Written whenever the app knows the household; read once
/// per background poll.
///
/// Encrypted like the profile it copies: which district somebody watches
/// is where they live. The worker can read it because the device key is
/// what opens it, and the worker asks the platform for that key before it
/// touches anything (see `warning_background_worker.dart`).
class WarningRegionStore {
  const WarningRegionStore();

  Future<void> save(WarningRegionFilter filter) async {
    const store = PrivatePreferences();
    await store.setString(_countryKey, filter.countryCode);

    final region = filter.ownRegionKey;
    if (region == null || region.isEmpty) {
      await store.remove(_regionKey);
    } else {
      await store.setString(_regionKey, region);
    }

    await store.setStringList(_extraRegionsKey, [
      for (final extra in filter.extraRegions) extra.encode(),
    ]);
  }

  /// The stored filter, or null if the app has never known a household.
  ///
  /// Null rather than a default: polling a country nobody asked about
  /// would mean traffic against a public API for warnings no one will
  /// read.
  Future<WarningRegionFilter?> load() async {
    const store = PrivatePreferences();
    final country = await store.getString(_countryKey);
    if (country == null || country.isEmpty) return null;

    return WarningRegionFilter(
      countryCode: country,
      ownRegionKey: await store.getString(_regionKey),
      extraRegions: [
        for (final encoded
            in await store.getStringList(_extraRegionsKey) ?? const [])
          ?WarningRegion.decode(encoded),
      ],
    );
  }

  Future<void> clear() async {
    const store = PrivatePreferences();
    await store.remove(_countryKey);
    await store.remove(_regionKey);
    await store.remove(_extraRegionsKey);
  }
}
