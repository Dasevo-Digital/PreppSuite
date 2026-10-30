import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/core/locale_provider.dart';
import 'package:preppsuite_flutter/core/notifications_provider.dart';
import 'package:preppsuite_flutter/core/theme_provider.dart';
import 'package:preppsuite_flutter/features/daylight/application/daylight_store.dart';
import 'package:preppsuite_flutter/features/energy/application/energy_range.dart';
import 'package:preppsuite_flutter/features/energy/application/energy_store.dart';
import 'package:preppsuite_flutter/features/energy/application/outage_food_safety.dart';
import 'package:preppsuite_flutter/features/energy/application/outage_store.dart';
import 'package:preppsuite_flutter/features/first_aid/application/first_aid_providers.dart';
import 'package:preppsuite_flutter/features/home/application/check_in.dart';
import 'package:preppsuite_flutter/features/home/application/drill_progress_store.dart';
import 'package:preppsuite_flutter/features/inventory/application/charge_reminder_provider.dart';
import 'package:preppsuite_flutter/features/inventory/application/expiry_reminder_provider.dart';
import 'package:preppsuite_flutter/features/knowledge/application/article_viewer_choice.dart';
import 'package:preppsuite_flutter/features/knowledge/application/knowledge_bookmark_store.dart';
import 'package:preppsuite_flutter/features/maps/application/map_source_preference.dart';
import 'package:preppsuite_flutter/features/maps/application/map_source_store.dart';
import 'package:preppsuite_flutter/features/maps/application/personal_place.dart';
import 'package:preppsuite_flutter/features/maps/application/tile_source.dart';
import 'package:preppsuite_flutter/features/preparedness/application/preparedness_hub_store.dart';
import 'package:preppsuite_flutter/features/sharing/application/carried_settings.dart';
import 'package:preppsuite_flutter/features/warnings/application/air_quality_client.dart';
import 'package:preppsuite_flutter/features/warnings/application/air_quality_store.dart';
import 'package:preppsuite_flutter/features/warnings/application/fire_danger_client.dart';
import 'package:preppsuite_flutter/features/warnings/application/fire_danger_store.dart';
import 'package:preppsuite_flutter/features/warnings/application/heavy_rain_hazard.dart';
import 'package:preppsuite_flutter/features/warnings/application/pegel_client.dart';
import 'package:preppsuite_flutter/features/warnings/application/pegel_store.dart';
import 'package:preppsuite_flutter/features/warnings/application/radiation_client.dart';
import 'package:preppsuite_flutter/features/warnings/application/radiation_store.dart';
import 'package:preppsuite_flutter/features/warnings/application/road_closure_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Every carried setting, written the way the app writes it (#236).
///
/// The table in `carried_settings.dart` names a kind for each key, and the
/// stores decide on their own how they keep it. Twice they disagreed: the
/// expiry lead times and then the energy plan and the bookmarks were kept
/// as one string and listed as something else, so reading them failed and
/// they travelled nowhere, not even into a backup. The tests beside this
/// one never noticed, because they put values in by hand in the shape the
/// table expects. This one goes through the real stores instead.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('everything the stores write comes back out for the backup', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final at = DateTime.utc(2026, 10, 30, 9);

    await const RoadClosureStore().save(['A2']);
    await const PegelStore().saveStation(
      const PegelStation(uuid: 'p1', name: 'Dresden', water: 'Elbe'),
    );
    await const RadiationStore().saveStation(
      const RadiationStation(id: '091620001', name: 'Station'),
    );
    await const AirQualityStore().saveStation(
      const AirQualityStation(id: '1', name: 'Station'),
    );
    await const FireDangerStore().saveStation(
      const FireDangerStation(id: '1', name: 'Station'),
    );
    await const DaylightStore().save(
      const DaylightPlace(latitude: 52.27, longitude: 10.52, name: 'Hier'),
    );
    await const EnergyPlanStore().save(
      const EnergyPlan(
        reserves: [
          EnergyReserve(
            id: 'r1',
            kind: EnergyKind.electricity,
            label: 'Powerbank',
            amount: 100,
          ),
        ],
        draws: [
          EnergyDraw(
            id: 'd1',
            kind: EnergyKind.electricity,
            label: 'Router',
            perHour: 12,
            hoursPerDay: 24,
          ),
        ],
      ),
    );
    await const OutageClockStore().save(
      OutageClock(startedAt: at, freezerFill: FreezerFill.half),
    );
    await const DrillProgressStore().save({'water'});
    await const DrillProgressStore().markCompleted('outage', at);
    await const PreparednessHubStore().save(const PreparednessHubData());
    await const PersonalPlaceStore().save(const [
      PersonalPlace(id: 'p1', label: 'Brunnen', latitude: 52, longitude: 10),
    ]);
    await const CheckInContactStore().save(const [
      CheckInContact(name: 'Nachbarin', phone: '0'),
    ]);
    await const HeavyRainStore().save(
      HeavyRainHazard(
        latitude: 52,
        longitude: 10,
        checkedAt: at,
        covered: true,
      ),
    );
    await container.read(expiryLeadDaysProvider.notifier).setLeadDays(const [
      30,
      1,
    ]);
    await container.read(chargeReminderDaysProvider.notifier).setDays(30);
    await const MapSourceStore().useProvider(MapTileProvider.values.last);
    await container
        .read(mapSourceProvider.notifier)
        .use(MapSourcePreference.values.last);
    await const FirstAidPackUrlStore().write('https://example.org/pack.zip');
    await const ArticleViewerChoiceStore().save(
      ArticleViewerChoice.values.last,
    );
    await const KnowledgeBookmarkStore().toggle(
      KnowledgeBookmark(
        archiveId: 'a',
        entryUrl: 'A/Erste_Hilfe',
        title: 'Erste Hilfe',
        createdAt: at,
      ),
    );
    await container
        .read(themeModeProvider.notifier)
        .setThemeMode(
          ThemeMode.dark,
        );
    await container
        .read(localeOverrideProvider.notifier)
        .setLocale(const Locale('en'));
    // Off asks the system for nothing; on would ask for permission.
    await container
        .read(notificationsEnabledProvider.notifier)
        .setEnabled(
          false,
        );

    final backup = await readCarriedSettings(forBackup: true);

    // A key missing here is written in a shape its kind cannot read. A key
    // added to the table without a line above fails here as well: write it
    // through its store, then this test says whether it travels.
    expect(
      carriedSettings.keys.where((key) => !backup.containsKey(key)),
      isEmpty,
    );
  });

  test(
    'a backup brings each of them back the way its store reads it',
    () async {
      await const EnergyPlanStore().save(
        const EnergyPlan(
          draws: [
            EnergyDraw(
              id: 'd1',
              kind: EnergyKind.electricity,
              label: 'Router',
              perHour: 12,
              hoursPerDay: 24,
            ),
          ],
        ),
      );
      await const KnowledgeBookmarkStore().toggle(
        KnowledgeBookmark(
          archiveId: 'a',
          entryUrl: 'A/Erste_Hilfe',
          title: 'Erste Hilfe',
          createdAt: DateTime.utc(2026, 10, 30),
        ),
      );
      final backup = await readCarriedSettings(forBackup: true);

      SharedPreferences.setMockInitialValues({});
      await restoreBackupSettings(backup);

      final plan = await const EnergyPlanStore().load();
      expect(plan.draws.single.label, 'Router');
      final marks = await const KnowledgeBookmarkStore().load();
      expect(marks.single.title, 'Erste Hilfe');
    },
  );
}
