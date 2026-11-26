import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:preppsuite_flutter/core/resource_limits.dart';
import 'package:preppsuite_flutter/features/sharing/application/device_snapshot.dart';
import 'package:preppsuite_flutter/features/sharing/application/household_file.dart';
import 'package:preppsuite_flutter/features/sharing/application/native_sync_folder.dart';
import 'package:preppsuite_flutter/features/sharing/application/shared_folder_sync_service.dart';
import 'package:preppsuite_flutter/features/sharing/application/sync_folder.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

import 'in_memory_sync_folder.dart';

/// A damaged or tampered device file costs that file, never the run
/// (#312, #399).
///
/// Three ways one file stopped every run on every device: a number too
/// large for a double (`1e400` reads as infinity, and `toInt()` throws), a
/// file past the 64 MiB a snapshot may have, and one that did not finish
/// arriving. The last two happen before any seal is checked, so a folder
/// without its key was enough.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const householdId = 'household-1';
  final identity = HouseholdFile(
    householdId: householdId,
    name: 'Familie',
    countryCode: 'DE',
    createdAt: DateTime.utc(2026),
  );

  Map<String, Object?> item(String clientId, {Object? sortOrder = 0}) => {
    'clientId': clientId,
    'householdId': householdId,
    'templateClientId': 'list',
    'title': clientId,
    'sortOrder': sortOrder,
    'updatedAt': DateTime.utc(2026, 3).toIso8601String(),
  };

  group('a number past what a double holds', () {
    test('reads as no number, not as an error', () {
      final json = jsonDecode('{"sortOrder": 1e400}') as Map<String, Object?>;
      final row = decodeChecklistItem({...item('line'), ...json});

      expect(row, isNotNull);
      expect(row!.sortOrder.value, 0);
    });

    test('in a required field costs the row', () {
      final json = jsonDecode(
        '{"amountCents": 1e400, "purchasePriceCents": -1e400}',
      ) as Map<String, Object?>;
      expect(
        decodeBudgetEntry({
          'clientId': 'b',
          'householdId': householdId,
          'label': 'Wasser',
          'currency': 'EUR',
          'category': 'water',
          'updatedAt': DateTime.utc(2026).toIso8601String(),
          ...json,
        }),
        isNull,
      );
      expect(
        decodePossession({
          'clientId': 'p',
          'householdId': householdId,
          'name': 'Radio',
          'updatedAt': DateTime.utc(2026).toIso8601String(),
          ...json,
        })!.purchasePriceCents.value,
        isNull,
      );
    });

    test('does not stop the run, and the other rows arrive', () async {
      final folder = InMemorySyncFolder()..householdFile = identity.encode();
      final phone = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(phone.close);
      final snapshot = DeviceSnapshot(
        deviceId: 'laptop',
        householdId: householdId,
        writtenAt: DateTime.utc(2026, 3),
        checklistItems: [item('good'), item('broken', sortOrder: 1)],
      ).encode();
      // As a tampered file would say it.
      folder.deviceFiles['laptop'] = snapshot.replaceFirst(
        '"sortOrder": 1',
        '"sortOrder": 1e400',
      );
      expect(folder.deviceFiles['laptop'], contains('1e400'));

      final result = await SharedFolderSyncService(
        database: phone,
        folder: folder,
        deviceId: 'phone',
        identity: identity,
      ).sync();

      expect(result.error, isNull);
      expect(result.received, 2);
    });
  });

  group('a version past what a date can be moved on from', () {
    test('costs the row', () {
      for (final stamp in [
        '+275760-09-13T00:00:00.000Z',
        '+012026-01-01T00:00:00.000Z',
        '-000001-01-01T00:00:00.000Z',
      ]) {
        expect(
          decodeChecklistItem({...item('line'), 'updatedAt': stamp}),
          isNull,
          reason: stamp,
        );
        expect(rowVersion(stamp), isNull, reason: stamp);
      }
    });

    test('anything a clock could say is taken', () {
      for (final stamp in [
        '1970-01-01T00:00:00.000Z',
        '2024-01-01T00:00:00.000Z',
        '9999-12-31T23:59:59.000Z',
      ]) {
        expect(rowVersion(stamp), isNotNull, reason: stamp);
      }
    });

    test('a row kept within the bound stays editable', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final latest = decodeChecklistItem({
        ...item('line'),
        'updatedAt': '9999-12-31T23:59:59.000Z',
      })!;
      await db.mergeIncomingRows(
        items: [
          (
            clientId: 'line',
            updatedAt: latest.updatedAt.value,
            companion: latest,
          ),
        ],
      );

      await db.upsertChecklistItem(
        latest.copyWith(
          isChecked: const Value(true),
          updatedAt: Value(DateTime.utc(2026, 4)),
          dirty: const Value(true),
        ),
      );

      final stored = (await db.watchChecklistItems('list').first).single;
      expect(stored.isChecked, isTrue);
    });
  });

  group('a file too large to be a snapshot', () {
    test('reads as missing from a desktop folder', () async {
      final root = Directory.systemTemp.createTempSync('preppsuite-large');
      addTearDown(() => root.deleteSync(recursive: true));
      final folder = IoSyncFolder(root.path);
      await folder.writeDeviceFile('other', '{}');
      final file = File(
        p.join(root.path, preppSuiteFolderName, 'devices', 'other.json'),
      );
      // Sparse: the size is what is checked, before anything is read.
      final open = file.openSync(mode: FileMode.write);
      open.setPositionSync(maxSnapshotBytes);
      open.writeByteSync(0x7d);
      open.closeSync();

      expect(await folder.readDeviceFile('other'), isNull);
    });

    test('reads as missing through the platform channel', () async {
      const channel = MethodChannel('preppsuite/storage');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(
        channel,
        (_) async => throw PlatformException(code: 'read-too-large'),
      );
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

      expect(
        await const NativeSyncFolder('content://tree').readDeviceFile('x'),
        isNull,
      );
    });

    test('does not stop the run', () async {
      final root = Directory.systemTemp.createTempSync('preppsuite-large');
      addTearDown(() => root.deleteSync(recursive: true));
      final folder = IoSyncFolder(root.path);
      await folder.writeHouseholdFile(identity.encode());
      await folder.writeDeviceFile('laptop', '{}');
      final open = File(
        p.join(root.path, preppSuiteFolderName, 'devices', 'laptop.json'),
      ).openSync(mode: FileMode.write);
      open.setPositionSync(maxSnapshotBytes);
      open.writeByteSync(0x7d);
      open.closeSync();
      final phone = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(phone.close);
      await phone.upsertChecklistItem(
        decodeChecklistItem(item('mine'))!.copyWith(dirty: const Value(true)),
      );

      final result = await SharedFolderSyncService(
        database: phone,
        folder: folder,
        deviceId: 'phone',
        identity: identity,
      ).sync();

      expect(result.error, isNot(SharedFolderSyncError.failed));
      expect(result.published, isTrue);
    });
  });
}
