import 'package:shared_preferences/shared_preferences.dart';

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
class WarningRegionStore {
  const WarningRegionStore();

  Future<void> save(WarningRegionFilter filter) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_countryKey, filter.countryCode);

    final region = filter.ownRegionKey;
    if (region == null || region.isEmpty) {
      await prefs.remove(_regionKey);
    } else {
      await prefs.setString(_regionKey, region);
    }

    await prefs.setStringList(_extraRegionsKey, [
      for (final extra in filter.extraRegions) extra.encode(),
    ]);
  }

  /// The stored filter, or null if the app has never known a household.
  ///
  /// Null rather than a default: polling a country nobody asked about
  /// would mean traffic against a public API for warnings no one will
  /// read.
  Future<WarningRegionFilter?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final country = prefs.getString(_countryKey);
    if (country == null || country.isEmpty) return null;

    return WarningRegionFilter(
      countryCode: country,
      ownRegionKey: prefs.getString(_regionKey),
      extraRegions: [
        for (final encoded in prefs.getStringList(_extraRegionsKey) ?? const [])
          ?WarningRegion.decode(encoded),
      ],
    );
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_countryKey);
    await prefs.remove(_regionKey);
    await prefs.remove(_extraRegionsKey);
  }
}
