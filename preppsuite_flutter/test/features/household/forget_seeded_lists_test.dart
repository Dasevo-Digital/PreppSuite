import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/core/app_database_providers.dart';
import 'package:preppsuite_flutter/features/checklists/application/built_in_templates.dart';
import 'package:preppsuite_flutter/features/checklists/application/checklist_controller.dart';
import 'package:preppsuite_flutter/features/checklists/application/checklist_seeder.dart';
import 'package:preppsuite_flutter/features/household/application/household_providers.dart';
import 'package:preppsuite_flutter/local_db/database.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A join during first setup that fails forgets the profile it made (#397).
///
/// The gate had already written the built-in lists for that profile. Left
/// under the forgotten id, the next profile's run skipped every list as
/// existing: they were shown, as built-in lists are in every household,
/// but never counted, never published and not deleted with the household.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    await container.read(householdProfileProvider.future);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  HouseholdProfileController profiles() =>
      container.read(householdProfileProvider.notifier);

  /// What the gate does once a profile is there.
  Future<void> seed(String householdId) => profiles().forHousehold(
    householdId,
    () => ChecklistSeeder(db).seed(householdId),
  );

  Future<String> setUpProfile() async =>
      (await profiles().create(name: 'Wohnung', countryCode: 'DE')).id;

  Future<int> rowsUnder(String householdId) async =>
      (await db.select(db.checklistTemplates).get())
          .where((row) => row.householdId == householdId)
          .length +
      (await db.select(db.checklistItems).get())
          .where((row) => row.householdId == householdId)
          .length;

  final shipped =
      builtInTemplates.length +
      builtInTemplates.fold<int>(0, (sum, t) => sum + t.items.length);

  test('the next profile gets the built-in lists as its own', () async {
    final forgotten = await setUpProfile();
    await seed(forgotten);
    expect(await rowsUnder(forgotten), shipped);

    await profiles().forget();
    expect(await rowsUnder(forgotten), 0);

    final next = await setUpProfile();
    await seed(next);

    expect(await rowsUnder(next), shipped);
    expect(await db.dirtyChecklistItems(next), isNotEmpty);
  });

  test('a line somebody changed is not lost, nor its list', () async {
    final forgotten = await setUpProfile();
    await seed(forgotten);
    final line = (await db.watchAllChecklistItems(forgotten).first).first;
    await ChecklistController(db, forgotten).toggleItem(line);
    final listLength =
        (await db.watchChecklistItems(line.templateClientId).first).length;

    await profiles().forget();

    final kept = await db.watchChecklistItems(line.templateClientId).first;
    expect(kept, hasLength(listLength), reason: 'the whole list stays');
    expect(
      kept.singleWhere((row) => row.clientId == line.clientId).isChecked,
      isTrue,
    );
    expect(
      await db.checklistTemplateByClientId(line.templateClientId),
      isNotNull,
    );
    expect(await rowsUnder(forgotten), listLength + 1);
  });

  test('lists still being written finish before they are taken back', () async {
    final forgotten = await setUpProfile();
    final seeding = seed(forgotten);
    final forgetting = profiles().forget();
    await Future.wait([seeding, forgetting]);

    expect(await rowsUnder(forgotten), 0);
    expect(container.read(householdProfileProvider).value, isNull);
  });
}
