import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/sharing/application/carried_settings.dart';
import 'package:preppsuite_flutter/features/warnings/application/fire_danger_client.dart';
import 'package:preppsuite_flutter/features/warnings/application/fire_danger_level.dart';
import 'package:preppsuite_flutter/features/warnings/application/fire_danger_store.dart';
import 'package:preppsuite_flutter/features/warnings/application/radiation_client.dart';
import 'package:preppsuite_flutter/features/warnings/application/radiation_level.dart';
import 'package:preppsuite_flutter/features/warnings/application/radiation_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A station that arrives from elsewhere does not inherit the reading of
/// the one it replaces (#239).
///
/// The stores drop the kept reading when the station is changed here.
/// Sync, a handover and a backup write the setting past them, and until
/// 2.7.9 the old station's value then stood under the new name whenever
/// the screen was offline.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('the radiation probe', () async {
    const store = RadiationStore();
    const here = RadiationStation(id: '031010001', name: 'Hier');
    const there = RadiationStation(id: '091620001', name: 'Dort');
    await store.saveStation(here);
    await store.saveReading(
      here,
      RadiationReading(
        stationName: here.name,
        microsievertsPerHour: 0.31,
        measuredAt: DateTime.utc(2026, 10, 30, 8),
      ),
    );

    await applyCarriedSettings({
      'radiationStation': jsonEncode(there.toJson()),
    });

    final station = (await store.loadStation())!;
    expect(station.id, there.id);
    expect(await store.loadReading(station), isNull);
    expect((await store.loadReading(here))!.microsievertsPerHour, 0.31);
  });

  test('the fire danger station', () async {
    const store = FireDangerStore();
    const here = FireDangerStation(id: '662', name: 'Braunschweig');
    const there = FireDangerStation(id: '44', name: 'Großenkneten');
    await store.saveStation(here);
    await store.saveForecast(
      here,
      FireDangerForecast(
        stationName: here.name,
        issuedFor: DateTime(2026, 9, 11),
        days: const [FireDangerLevel.high],
      ),
    );

    await restoreBackupSettings({
      'fireDangerStation': jsonEncode(there.toJson()),
    });

    final station = (await store.loadStation())!;
    expect(station.id, there.id);
    expect(await store.loadForecast(station), isNull);
    expect((await store.loadForecast(here))!.days.single, FireDangerLevel.high);
  });
}
