import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/core/app_database_providers.dart';
import 'package:preppsuite_flutter/features/checklists/application/built_in_templates.dart';
import 'package:preppsuite_flutter/features/checklists/application/checklist_seeder.dart';
import 'package:preppsuite_flutter/features/household/application/household_providers.dart';
import 'package:preppsuite_flutter/local_db/database.dart';
import 'package:preppsuite_flutter/model/household_profile.dart';
import 'package:preppsuite_flutter/model/household_profile_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The built-in checklists and a move into another household (#397).
///
/// On first setup the gate writes the lists for the profile the form has
/// just made, without waiting, and joining a folder moves that profile a
/// moment later. Side by side, the lists written after the re-stamp stayed
/// under the old id: a tick on them never left the device, "x of y" did
/// not count them, and "delete household" left them behind.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const mine = HouseholdProfile(id: 'mine', name: 'Wohnung', countryCode: 'DE');
  const theirs = 'theirs';

  late AppDatabase db;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await const HouseholdProfileStore().save(mine);
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

  test('a move waits for the lists under way and takes all of them', () async {
    final seeding = seed(mine.id);
    final moved = profiles().moveInto(mine, theirs);
    await Future.wait([seeding, moved]);

    expect(await rowsUnder(mine.id), 0, reason: 'nothing left behind');
    expect(await rowsUnder(theirs), shipped);
    expect(
      await db.dirtyChecklistItems(theirs),
      isNotEmpty,
      reason: 'and they go out under the new household',
    );
  });

  test('lists asked for the old household after the move write nothing, '
      'and the new household gets its own', () async {
    final moved = profiles().moveInto(mine, theirs);
    final late = seed(mine.id);
    await Future.wait([moved, late]);

    expect(await rowsUnder(mine.id), 0);
    expect(await rowsUnder(theirs), 0, reason: 'the gate seeds this one');

    await seed(theirs);
    expect(await rowsUnder(theirs), shipped);
    expect(await rowsUnder(mine.id), 0);
  });

  test('a failed run does not hold up the next move', () async {
    final failing = profiles().forHousehold(
      mine.id,
      () async => throw StateError('disk full'),
    );
    await expectLater(failing, throwsStateError);

    final moved = await profiles().moveInto(mine, theirs);
    expect(moved.id, theirs);
  });
}
