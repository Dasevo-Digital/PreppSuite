import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/core/locale_provider.dart';
import 'package:preppsuite_flutter/core/settings_arrival.dart';
import 'package:preppsuite_flutter/core/theme_provider.dart';
import 'package:preppsuite_flutter/features/first_aid/application/first_aid_providers.dart';
import 'package:preppsuite_flutter/features/inventory/application/charge_reminder_provider.dart';
import 'package:preppsuite_flutter/features/inventory/application/expiry_reminder_planner.dart';
import 'package:preppsuite_flutter/features/inventory/application/expiry_reminder_provider.dart';
import 'package:preppsuite_flutter/features/sharing/application/carried_settings.dart';
import 'package:preppsuite_flutter/features/sharing/application/settings_sync_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Settings written here from elsewhere reach the running app (#237).
void main() {
  final monday = DateTime.utc(2026, 10, 26, 9);
  final tuesday = DateTime.utc(2026, 10, 27, 9);

  /// The app as it runs: these controllers read their value once.
  Future<ProviderContainer> running(Map<String, Object> stored) async {
    SharedPreferences.setMockInitialValues(stored);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container
      ..listen(expiryLeadDaysProvider, (_, _) {})
      ..listen(chargeReminderDaysProvider, (_, _) {})
      ..listen(themeModeProvider, (_, _) {})
      ..listen(localeOverrideProvider, (_, _) {})
      ..listen(firstAidPackUrlProvider, (_, _) {});
    await pumpEventQueue();
    return container;
  }

  test(
    'lead times from another device are what a toggle starts from',
    () async {
      final app = await running({'expiryLeadDays': '7'});
      expect(app.read(expiryLeadDaysProvider), [7]);
      final prefs = await SharedPreferences.getInstance();
      await readSyncedSettings(preferences: prefs, now: monday);

      final applied = await applySyncedSettings(
        {'expiryLeadDays': (value: '30,1', at: tuesday)},
        preferences: prefs,
        now: tuesday,
      );
      await pumpEventQueue();

      expect(applied, 1);
      expect(app.read(expiryLeadDaysProvider), [30, 1]);
      // Until 2.7.8 this toggle started from [7] and wrote "14,7" back,
      // which the next sync then carried into the household.
      await app.read(expiryLeadDaysProvider.notifier).toggle(14);
      expect(prefs.getString('expiryLeadDays'), '30,14,1');
    },
  );

  test(
    'lead times removed on another device fall back to the default',
    () async {
      final app = await running({'expiryLeadDays': '7'});
      final prefs = await SharedPreferences.getInstance();
      await readSyncedSettings(preferences: prefs, now: monday);

      await applySyncedSettings(
        {'expiryLeadDays': (value: null, at: tuesday)},
        preferences: prefs,
        now: tuesday,
      );
      await pumpEventQueue();

      expect(prefs.containsKey('expiryLeadDays'), isFalse);
      expect(app.read(expiryLeadDaysProvider), defaultExpiryLeadDays);
    },
  );

  test('a restored backup is in use without a restart', () async {
    final app = await running({});

    await restoreBackupSettings({
      'chargeReminderDays': 30,
      'firstAidPackUrl': 'https://example.org/pack.zip',
    });
    await pumpEventQueue();

    expect(app.read(chargeReminderDaysProvider), 30);
    expect(
      await app.read(firstAidPackUrlProvider.future),
      'https://example.org/pack.zip',
    );
  });

  test('a household joined brings its look and language at once', () async {
    final app = await running({});

    await applyCarriedSettings({
      'themeModeOverride': 'dark',
      'localeOverride': 'en',
    });
    await pumpEventQueue();

    expect(app.read(themeModeProvider), ThemeMode.dark);
    expect(app.read(localeOverrideProvider), const Locale('en'));
  });

  test('nothing written, nothing announced', () async {
    final app = await running({});
    app.listen(settingsArrivalProvider, (_, _) {});

    await applyCarriedSettings({'notASetting': 1, 'chargeReminderDays': -1});
    await applySyncedSettings({});
    await pumpEventQueue();

    expect(app.read(settingsArrivalProvider), 0);
  });
}
