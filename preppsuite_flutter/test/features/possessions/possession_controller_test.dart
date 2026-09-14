import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/possessions/application/possession_controller.dart';
import 'package:preppsuite_flutter/features/sharing/application/device_snapshot.dart';
import 'package:preppsuite_flutter/features/sharing/application/snapshot_exchange.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

/// Against a real database, because the parts worth checking are the ones
/// drift and the merge do: a tombstone that survives a sync, a row that
/// reaches the other device, and a photo path that does not.
void main() {
  const householdId = 'household-1';

  AppDatabase open() {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    return db;
  }

  PossessionController controllerFor(AppDatabase db) =>
      PossessionController(database: db, householdId: householdId);

  test('an entry needs nothing but a name', () async {
    final db = open();
    await controllerFor(db).save(const PossessionDraft(name: 'Waschmaschine'));

    final stored = (await db.watchPossessions(householdId).first).single;
    expect(stored.name, 'Waschmaschine');
    expect(stored.room, isNull);
    expect(stored.purchasePriceCents, isNull);
  });

  test('blank fields are stored as absent, not as empty strings', () async {
    // Otherwise the PDF prints a column of nothing and the room grouping
    // gains a group called "".
    final db = open();
    await controllerFor(db).save(
      const PossessionDraft(name: 'Fahrrad', room: '   ', serialNumber: ''),
    );

    final stored = (await db.watchPossessions(householdId).first).single;
    expect(stored.room, isNull);
    expect(stored.serialNumber, isNull);
  });

  test('deleting leaves a tombstone rather than removing the row', () async {
    // A hard delete would come straight back at the next merge, because
    // the other device still has the row and no reason to think it went.
    final db = open();
    final controller = controllerFor(db);
    await controller.save(const PossessionDraft(name: 'Fernseher'));
    final stored = (await db.watchPossessions(householdId).first).single;

    await controller.remove(stored);

    expect(await db.watchPossessions(householdId).first, isEmpty);
    final forSync = await db.possessionsForSync(householdId);
    expect(forSync.single.deletedAt, isNotNull);
  });

  test('an edit brings a deleted entry back', () async {
    final db = open();
    final controller = controllerFor(db);
    await controller.save(const PossessionDraft(name: 'Fernseher'));
    final stored = (await db.watchPossessions(householdId).first).single;
    await controller.remove(stored);

    await controller.save(
      const PossessionDraft(name: 'Fernseher'),
      existing: stored,
    );

    expect(await db.watchPossessions(householdId).first, hasLength(1));
  });

  group('grouping and totals', () {
    List<Possession> rows(List<(String, String?, int?, String?)> entries) => [
      for (final (name, room, cents, currency) in entries)
        Possession(
          clientId: name,
          householdId: householdId,
          name: name,
          room: room,
          purchasePriceCents: cents,
          currency: currency,
          updatedAt: DateTime.utc(2026, 9, 14),
          dirty: false,
        ),
    ];

    test('entries are grouped by the room they are in', () {
      final grouped = byRoom(
        rows([
          ('Sofa', 'Wohnzimmer', null, null),
          ('Bohrmaschine', 'Keller', null, null),
          ('Fernseher', 'Wohnzimmer', null, null),
        ]),
      );
      expect(grouped.keys, ['Wohnzimmer', 'Keller']);
      expect(grouped['Wohnzimmer']!.map((r) => r.name), ['Sofa', 'Fernseher']);
    });

    test('entries with no room keep their own group', () {
      final grouped = byRoom(rows([('Anhaenger', null, null, null)]));
      expect(grouped.keys, [null]);
    });

    test('totals are per currency and never added across them', () {
      // Euros plus francs is a number that is wrong in a way nobody
      // notices, which is worse than two numbers.
      final totals = totalCentsByCurrency(
        rows([
          ('Sofa', null, 120000, 'EUR'),
          ('Uhr', null, 50000, 'CHF'),
          ('Regal', null, 8000, 'EUR'),
        ]),
      );
      expect(totals, {'EUR': 128000, 'CHF': 50000});
    });

    test('what has no price is counted and named', () {
      final data = rows([
        ('Sofa', null, 120000, 'EUR'),
        ('Regal', null, null, null),
        ('Lampe', null, null, null),
      ]);
      expect(totalCentsByCurrency(data), {'EUR': 120000});
      expect(withoutPrice(data), 2);
    });
  });

  group('through a snapshot', () {
    test('an entry reaches the other device', () async {
      final a = open();
      final b = open();
      await PossessionController(
        database: a,
        householdId: householdId,
      ).save(
        const PossessionDraft(
          name: 'Waschmaschine',
          room: 'Keller',
          serialNumber: 'WM-4711',
          purchasePriceCents: 59900,
          currency: 'EUR',
        ),
      );

      final snapshot = await readHouseholdSnapshot(
        a,
        deviceId: 'device-a',
        householdId: householdId,
      );
      expect(await applyHouseholdSnapshot(b, snapshot), 1);

      final arrived = (await b.watchPossessions(householdId).first).single;
      expect(arrived.name, 'Waschmaschine');
      expect(arrived.serialNumber, 'WM-4711');
      expect(arrived.purchasePriceCents, 59900);
      expect(arrived.currency, 'EUR');
    });

    test('the photo stays behind', () async {
      // The path names a file in this device's documents directory. On
      // the other device it would resolve to nothing, which is worse
      // than no path at all.
      final a = open();
      final b = open();
      await PossessionController(database: a, householdId: householdId).save(
        const PossessionDraft(name: 'Fahrrad', photoPath: 'photos/abc.jpg'),
      );

      final snapshot = await readHouseholdSnapshot(
        a,
        deviceId: 'device-a',
        householdId: householdId,
      );
      await applyHouseholdSnapshot(b, snapshot);

      expect(
        (await b.watchPossessions(householdId).first).single.photoPath,
        isNull,
      );
    });

    test('a deletion reaches the other device too', () async {
      final a = open();
      final b = open();
      final controller = PossessionController(
        database: a,
        householdId: householdId,
      );
      await controller.save(const PossessionDraft(name: 'Fernseher'));
      var snapshot = await readHouseholdSnapshot(
        a,
        deviceId: 'device-a',
        householdId: householdId,
      );
      await applyHouseholdSnapshot(b, snapshot);

      await controller.remove(
        (await a.watchPossessions(householdId).first).single,
      );
      snapshot = await readHouseholdSnapshot(
        a,
        deviceId: 'device-a',
        householdId: householdId,
      );
      await applyHouseholdSnapshot(b, snapshot);

      expect(await b.watchPossessions(householdId).first, isEmpty);
    });

    test('applying the same snapshot twice changes nothing', () async {
      final a = open();
      final b = open();
      await PossessionController(
        database: a,
        householdId: householdId,
      ).save(const PossessionDraft(name: 'Sofa'));

      final snapshot = await readHouseholdSnapshot(
        a,
        deviceId: 'device-a',
        householdId: householdId,
      );
      expect(await applyHouseholdSnapshot(b, snapshot), 1);
      expect(await applyHouseholdSnapshot(b, snapshot), 0);
    });

    test('a snapshot written before this table existed still reads', () async {
      // An older device publishes a file with no `possessions` key at
      // all. It has to stay readable, or one device on an old version
      // stops the whole household from syncing.
      final b = open();
      final old = await readHouseholdSnapshot(
        open(),
        deviceId: 'device-a',
        householdId: householdId,
      );
      final withoutKey = old.encode().replaceAll('"possessions": [],', '');

      final decoded = DeviceSnapshot.decode(withoutKey);
      expect(decoded, isNotNull);
      expect(decoded!.possessions, isEmpty);
      expect(await applyHouseholdSnapshot(b, decoded), 0);
    });
  });
}
