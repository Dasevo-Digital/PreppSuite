import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/core/app_database_providers.dart';
import 'package:preppsuite_flutter/core/theme_provider.dart';
import 'package:preppsuite_flutter/features/daylight/application/daylight_store.dart';
import 'package:preppsuite_flutter/features/home/application/check_in.dart';
import 'package:preppsuite_flutter/features/inventory/application/charge_reminder_provider.dart';
import 'package:preppsuite_flutter/features/inventory/application/expiry_reminder_planner.dart';
import 'package:preppsuite_flutter/features/inventory/application/expiry_reminder_provider.dart';
import 'package:preppsuite_flutter/features/knowledge/application/personal_document_store.dart';
import 'package:preppsuite_flutter/features/maps/application/personal_place.dart';
import 'package:preppsuite_flutter/features/preparedness/application/preparedness_hub_store.dart';
import 'package:preppsuite_flutter/features/settings/presentation/reset_card.dart';
import 'package:preppsuite_flutter/features/sharing/application/carried_settings.dart';
import 'package:preppsuite_flutter/features/sharing/application/settings_sync_store.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:preppsuite_flutter/local_db/database.dart';
import 'package:preppsuite_flutter/model/household_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The two resets in the settings, and what each leaves behind (#247).
void main() {
  const profile = HouseholdProfile(
    id: 'household-1',
    name: 'Zuhause',
    countryCode: 'DE',
  );
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
  });
  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<void> show(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(600, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => ResetCard(
                profile: profile,
                l10n: AppLocalizations.of(context)!,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> reset(WidgetTester tester, String which) async {
    await tester.tap(find.text(which));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Zurücksetzen'));
    await tester.pumpAndSettle();
  }

  testWidgets('deleting the household takes what it kept beside the '
      'database, and leaves how the device is set up', (tester) async {
    await const PreparednessHubStore().save(const PreparednessHubData());
    await const PersonalPlaceStore().save(const [
      PersonalPlace(id: 'p1', label: 'Treffpunkt', latitude: 52, longitude: 10),
    ]);
    await const CheckInContactStore().save(const [
      CheckInContact(name: 'Nachbarin', phone: '01712345678'),
    ]);
    await const DaylightStore().save(
      const DaylightPlace(latitude: 52.27, longitude: 10.52, name: 'Hier'),
    );
    await const PersonalDocumentStore().add(
      location: '/dokumente/reisepass.pdf',
      label: 'Reisepass',
    );
    await const SettingsSyncStore().save({
      'chargeReminderDays': (value: 30, at: DateTime.utc(2026, 10, 1)),
    });
    await container
        .read(themeModeProvider.notifier)
        .setThemeMode(
          ThemeMode.dark,
        );
    expect(
      (await readCarriedSettings(forBackup: true)).keys,
      containsAll(['preparednessHubV1', 'personalMapPlaces.v1']),
    );

    await show(tester);
    await reset(tester, 'Haushalt und lokale Daten löschen');

    expect(await const PersonalPlaceStore().load(), isEmpty);
    expect(await const CheckInContactStore().load(), isEmpty);
    expect(await const DaylightStore().load(), isNull);
    expect(await const PersonalDocumentStore().load(), isEmpty);
    // Kept, the base would read every old value as deleted here at the
    // first exchange in another household, and send that on.
    expect(await const SettingsSyncStore().load(), isEmpty);

    final left = await readCarriedSettings(forBackup: true);
    expect(
      left.keys.where(
        (key) => carriedSettings[key]!.when != CarriedWhen.setupOnly,
      ),
      isEmpty,
      reason: 'nothing of the household outlives it on this device',
    );
    expect(left['themeModeOverride'], isNotNull);
  });

  testWidgets('resetting the settings reaches the running app, not only '
      'the next start', (tester) async {
    await container.read(expiryLeadDaysProvider.notifier).setLeadDays(const [
      14,
    ]);
    await container.read(chargeReminderDaysProvider.notifier).setDays(30);

    await show(tester);
    await reset(tester, 'App-Einstellungen zurücksetzen');

    expect(container.read(expiryLeadDaysProvider), defaultExpiryLeadDays);
    expect(
      container.read(chargeReminderDaysProvider),
      defaultChargeReminderDays,
    );
  });
}
