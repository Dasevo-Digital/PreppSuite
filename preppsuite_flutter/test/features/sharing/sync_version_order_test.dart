import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/sharing/application/household_file.dart';
import 'package:preppsuite_flutter/features/sharing/application/shared_folder_sync_service.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

import 'in_memory_sync_folder.dart';

const householdId = 'shared-household';
final time = DateTime.utc(2026, 1, 1);
final identity = HouseholdFile(
  householdId: householdId,
  name: 'Test',
  countryCode: 'DE',
  createdAt: time,
);

Future<void> writeAll(AppDatabase db, String label, DateTime version) async {
  await db.upsertInventoryItem(
    InventoryItemsCompanion.insert(
      clientId: 'inventory',
      householdId: householdId,
      name: label,
      category: 'water',
      quantity: 1,
      unit: 'L',
      storageLocation: '',
      updatedAt: version,
      dirty: const Value(true),
    ),
  );
  await db.upsertChecklistTemplate(
    ChecklistTemplatesCompanion.insert(
      clientId: 'template',
      householdId: const Value(householdId),
      title: label,
      category: 'water',
      updatedAt: version,
      dirty: const Value(true),
    ),
  );
  await db.upsertChecklistItem(
    ChecklistItemsCompanion.insert(
      clientId: 'item',
      householdId: const Value(householdId),
      templateClientId: 'template',
      title: label,
      updatedAt: version,
      dirty: const Value(true),
    ),
  );
  await db.upsertBudgetEntry(
    BudgetEntriesCompanion.insert(
      clientId: 'budget',
      householdId: householdId,
      label: label,
      amountCents: 100,
      currency: 'EUR',
      category: 'water',
      updatedAt: version,
      dirty: const Value(true),
    ),
  );
  await db.upsertHouseholdPlan(
    HouseholdPlansCompanion.insert(
      clientId: householdId,
      householdId: householdId,
      notes: Value(label),
      updatedAt: version,
      dirty: const Value(true),
    ),
  );
  await db.upsertHouseholdMember(
    HouseholdMembersCompanion.insert(
      clientId: 'member',
      householdId: householdId,
      name: label,
      updatedAt: version,
      dirty: const Value(true),
    ),
  );
}

Future<void> expectAll(AppDatabase db, String label) async {
  for (final (table, column) in [
    ('inventory_items', 'name'),
    ('checklist_templates', 'title'),
    ('checklist_items', 'title'),
    ('budget_entries', 'label'),
    ('household_plans', 'notes'),
    ('household_members', 'name'),
  ]) {
    final row = await db
        .customSelect('SELECT $column, dirty FROM $table')
        .getSingle();
    expect(row.read<String>(column), label, reason: table);
    expect(row.read<bool>('dirty'), isFalse, reason: '$table was published');
  }
}

void main() {
  late AppDatabase left;
  late AppDatabase right;
  late InMemorySyncFolder folder;
  setUp(() {
    left = AppDatabase.forTesting(NativeDatabase.memory());
    right = AppDatabase.forTesting(NativeDatabase.memory());
    folder = InMemorySyncFolder()..householdFile = identity.encode();
  });
  tearDown(() async {
    await left.close();
    await right.close();
  });
  Future<void> sync(AppDatabase db, String device) async {
    final result = await SharedFolderSyncService(
      database: db,
      folder: folder,
      deviceId: device,
      identity: identity,
    ).sync();
    expect(result.succeeded, isTrue);
  }

  for (final higherFirst in [false, true]) {
    test(
      'all six tables converge on ties, higher first: $higherFirst',
      () async {
        await writeAll(left, higherFirst ? 'Z' : 'A', time);
        await writeAll(right, higherFirst ? 'A' : 'Z', time);
        for (var i = 0; i < 3; i++) {
          await sync(left, 'left');
          await sync(right, 'right');
        }
        await expectAll(left, 'Z');
        await expectAll(right, 'Z');
        final writes = folder.deviceWrites;
        await sync(left, 'left');
        await sync(right, 'right');
        expect(
          folder.deviceWrites,
          writes,
          reason: 'identical replay must be quiet',
        );
      },
    );
  }

  test('all six tables advance local versions within one second', () async {
    await writeAll(left, 'Z', time);
    await sync(left, 'left');
    await sync(right, 'right');
    // A sorts before Z, so only an increased version can make this win.
    await writeAll(left, 'A', time.add(const Duration(milliseconds: 100)));
    await sync(left, 'left');
    await sync(right, 'right');
    await expectAll(left, 'A');
    await expectAll(right, 'A');
  });
}
