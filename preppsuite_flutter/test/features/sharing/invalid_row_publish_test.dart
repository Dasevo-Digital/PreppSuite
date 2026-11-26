import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/core/error_text.dart';
import 'package:preppsuite_flutter/features/inventory/application/inventory_numbers.dart';
import 'package:preppsuite_flutter/features/sharing/application/household_file.dart';
import 'package:preppsuite_flutter/features/sharing/application/shared_folder_sync_service.dart';
import 'package:preppsuite_flutter/features/sharing/application/snapshot_exchange.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

import 'in_memory_sync_folder.dart';

/// A stock row from an older version that holds a number nothing may send
/// -- kept and editable on purpose -- stopped every publish (#397). The
/// card said "failed, the next attempt runs on its own", every two
/// minutes, and nothing of this device reached the others.
void main() {
  const householdId = 'household-1';

  late InMemorySyncFolder folder;
  late AppDatabase phone;
  late AppDatabase laptop;

  final identity = HouseholdFile(
    householdId: householdId,
    name: 'Familie',
    countryCode: 'DE',
    createdAt: DateTime.utc(2026),
  );

  setUp(() {
    folder = InMemorySyncFolder()..householdFile = identity.encode();
    phone = AppDatabase.forTesting(NativeDatabase.memory());
    laptop = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await phone.close();
    await laptop.close();
  });

  SharedFolderSyncService serviceFor(AppDatabase db, String deviceId) =>
      SharedFolderSyncService(
        database: db,
        folder: folder,
        deviceId: deviceId,
        identity: identity,
      );

  InventoryItemsCompanion row(String clientId, String name, double quantity) =>
      InventoryItemsCompanion.insert(
        clientId: clientId,
        householdId: householdId,
        name: name,
        category: 'food',
        quantity: quantity,
        unit: 'kg',
        storageLocation: 'Keller',
        updatedAt: DateTime.utc(2026, 1, 1),
        dirty: const Value(true),
      );

  test(
    'the run says which row, and still takes in the others\' rows',
    () async {
      await laptop.upsertInventoryItem(row('water', 'Trinkwasser', 6));
      await serviceFor(laptop, 'laptop').sync();

      await phone.upsertInventoryItem(row('rice', 'Reis', -2));
      final result = await serviceFor(phone, 'phone').sync();

      expect(result.error, SharedFolderSyncError.invalidRows);
      final cause = result.cause;
      expect(cause, isA<InventoryNeedsCorrection>());
      expect((cause! as InventoryNeedsCorrection).names, ['Reis']);
      expect(folder.deviceFiles, isNot(contains('phone')));
      expect(
        [
          for (final item in await phone.inventoryItemsForSync(householdId))
            item.name,
        ],
        containsAll(['Trinkwasser', 'Reis']),
        reason: 'what the laptop wrote arrived all the same',
      );
    },
  );

  test('a deleted broken row stops nothing', () async {
    await phone.upsertInventoryItem(
      row('rice', 'Reis', -2).copyWith(deletedAt: Value(DateTime.utc(2026, 2))),
    );

    final result = await serviceFor(phone, 'phone').sync();

    expect(result.error, isNull);
    expect(result.published, isTrue);
  });

  test('every road that reads the household names the rows', () async {
    await phone.upsertInventoryItem(row('rice', 'Reis', -2));
    await phone.upsertInventoryItem(row('flour', 'Mehl', 1));
    await phone.upsertInventoryItem(
      row('oats', 'Haferflocken', 1).copyWith(minQuantity: const Value(-1)),
    );

    await expectLater(
      readHouseholdSnapshot(phone, deviceId: 'phone', householdId: householdId),
      throwsA(
        isA<InventoryNeedsCorrection>().having(
          (error) => error.names,
          'names',
          unorderedEquals(['Reis', 'Haferflocken']),
        ),
      ),
    );
  });

  group('in words', () {
    late AppLocalizations de;
    late AppLocalizations en;

    setUpAll(() async {
      de = await AppLocalizations.delegate.load(const Locale('de'));
      en = await AppLocalizations.delegate.load(const Locale('en'));
    });

    test('names the rows', () {
      const error = InventoryNeedsCorrection(['Reis', 'Nudeln']);
      expect(describeError(de, error), contains('Reis, Nudeln'));
      expect(describeError(en, error), contains('Reis, Nudeln'));
      expect(describeError(de, error), isNot(de.inventoryInvalidNumbers));
    });

    test('a long list is cut short', () {
      const error = InventoryNeedsCorrection(['A', 'B', 'C', 'D', 'E']);
      expect(error.shortList, 'A, B, C …');
    });

    test('is still the invalid stock it was', () {
      const InvalidInventoryNumbers error = InventoryNeedsCorrection(['Reis']);
      expect(error, isA<InvalidInventoryNumbers>());
    });
  });
}
