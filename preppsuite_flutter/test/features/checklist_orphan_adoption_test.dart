import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/checklists/application/built_in_templates.dart';
import 'package:preppsuite_flutter/features/checklists/application/checklist_seeder.dart';
import 'package:preppsuite_flutter/features/sharing/application/snapshot_exchange.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

/// Built-in checklist rows an older version left under another household's
/// id (#397): written by the seeder beside a move, or for a profile that was
/// then forgotten.
///
/// Each built-in id is in a database once, so the seeder found the list,
/// skipped it as existing, and it never became the household's own. It was
/// shown all the same; its ticks went out to nobody, "x of y" did not count
/// it, and "delete household" left it behind.
void main() {
  const mine = 'mine';
  const stale = 'household-before';

  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  final shipped =
      builtInTemplates.length +
      builtInTemplates.fold<int>(0, (sum, t) => sum + t.items.length);

  Future<List<ChecklistTemplate>> templatesUnder(String id) async =>
      (await db.select(db.checklistTemplates).get())
          .where((row) => row.householdId == id)
          .toList();

  Future<List<ChecklistItem>> linesUnder(String id) async =>
      (await db.select(db.checklistItems).get())
          .where((row) => row.householdId == id)
          .toList();

  /// The first built-in line in [on] (this test's database if left out),
  /// ticked at [at].
  Future<ChecklistItem> tick(DateTime at, {AppDatabase? on}) async {
    final database = on ?? db;
    final first = builtInTemplates.first.items.first.clientId;
    Future<ChecklistItem> line() async =>
        (await database.select(database.checklistItems).get()).singleWhere(
          (row) => row.clientId == first,
        );
    await database.upsertChecklistItem(
      (await line())
          .toCompanion(true)
          .copyWith(
            isChecked: const Value(true),
            updatedAt: Value(at),
            dirty: const Value(true),
          ),
    );
    return line();
  }

  test('are taken over, with the version they have', () async {
    await ChecklistSeeder(db).seed(stale);
    final ticked = await tick(DateTime.utc(2026, 5, 1, 12));
    await db.markHouseholdPublished(stale);

    await ChecklistSeeder(db).seed(mine);

    expect(await templatesUnder(stale), isEmpty);
    expect(await linesUnder(stale), isEmpty);
    expect(
      (await templatesUnder(mine)).length + (await linesUnder(mine)).length,
      shipped,
    );
    final adopted = (await linesUnder(
      mine,
    )).singleWhere((row) => row.clientId == ticked.clientId);
    expect(adopted.isChecked, isTrue);
    expect(adopted.updatedAt, ticked.updatedAt, reason: 'not an edit');
    expect(
      (await db.dirtyChecklistItems(mine)).map((row) => row.clientId),
      contains(ticked.clientId),
      reason: 'the tick goes out at last',
    );
    expect(
      await db.watchAllChecklistItems(mine).first,
      hasLength(shipped - builtInTemplates.length),
      reason: '"x of y" counts them',
    );
  });

  test('only the built-in ones', () async {
    await db.upsertChecklistTemplate(
      ChecklistTemplatesCompanion.insert(
        clientId: 'own-list',
        householdId: const Value(stale),
        title: 'Garten',
        category: 'custom',
        updatedAt: DateTime.utc(2026),
        dirty: const Value(true),
      ),
    );
    await db.upsertChecklistItem(
      ChecklistItemsCompanion.insert(
        clientId: 'own-line',
        householdId: const Value(stale),
        templateClientId: 'own-list',
        title: 'Regentonne',
        updatedAt: DateTime.utc(2026),
        dirty: const Value(true),
      ),
    );

    await ChecklistSeeder(db).seed(mine);

    expect((await templatesUnder(stale)).single.clientId, 'own-list');
    expect((await linesUnder(stale)).single.clientId, 'own-line');
  });

  test('a second run changes nothing', () async {
    await ChecklistSeeder(db).seed(stale);
    await tick(DateTime.utc(2026, 5, 1, 12));
    await ChecklistSeeder(db).seed(mine);
    Future<List<(String, DateTime, String?)>> state() async => [
      for (final row in await db.select(db.checklistItems).get())
        (row.clientId, row.updatedAt, row.householdId),
    ];
    final before = await state();

    await ChecklistSeeder(db).seed(mine);

    expect(
      await db.adoptChecklistRows(
        mine,
        templates: ChecklistSeeder.builtInTemplateIds,
        items: ChecklistSeeder.builtInItemIds,
      ),
      0,
    );
    expect(await state(), before);
  });

  test('a copy nobody touched loses to an edit made elsewhere', () async {
    // The other device ticked the line last year. Had taking it over been
    // an edit, stamped today, the untouched copy here would have won and
    // un-ticked it on every device.
    final elsewhere = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(elsewhere.close);
    await ChecklistSeeder(elsewhere).seed(mine);
    final tickedThere = await tick(DateTime.utc(2025, 6, 1), on: elsewhere);

    // Here the lists lie under an earlier id, untouched, and are taken
    // over today.
    await ChecklistSeeder(db).seed(stale);
    await ChecklistSeeder(db).seed(mine);
    await applyHouseholdSnapshot(
      db,
      await readHouseholdSnapshot(
        elsewhere,
        deviceId: 'elsewhere',
        householdId: mine,
      ),
    );

    final line = (await linesUnder(
      mine,
    )).singleWhere((row) => row.clientId == tickedThere.clientId);
    expect(line.isChecked, isTrue);
  });
}
