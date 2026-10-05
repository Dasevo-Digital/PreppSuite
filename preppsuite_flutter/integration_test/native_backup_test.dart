import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:preppsuite_flutter/core/local_database_encryption.dart';
import 'package:preppsuite_flutter/core/photo_vault.dart';
import 'package:preppsuite_flutter/features/downloads/application/download_folder.dart';
import 'package:preppsuite_flutter/features/inventory/application/inventory_photo_service.dart';
import 'package:preppsuite_flutter/features/knowledge/application/zim_store.dart';
import 'package:preppsuite_flutter/features/maps/application/offline_map_store.dart';
import 'package:preppsuite_flutter/features/maps/application/pmtiles_archive.dart';
import 'package:preppsuite_flutter/features/settings/application/backup_files.dart';
import 'package:preppsuite_flutter/features/settings/application/backup_service.dart';
import 'package:preppsuite_flutter/features/transfer/application/handover_photos.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

/// A full backup on a real device (#114): the photo sealed with this
/// installation's own key, the archives in the platform's own download
/// folder, and the files written back where a download would put them.
///
/// The unit suite proves the container. What only a device can say is
/// whether the app's real folders, its key store and the storage bridge
/// let every part of the round trip happen.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('photo, map and archive go out and come back', (tester) async {
    await tester.runAsync(() async {
      await LocalDatabaseEncryption.instance.initializeOrMarkUnavailable();

      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final folder = await const DownloadFolder().current();
      final work = await Directory(
        p.join(
          folder.path,
          'backup-test-${DateTime.now().millisecondsSinceEpoch}',
        ),
      ).create(recursive: true);
      addTearDown(() => work.delete(recursive: true));

      // A photo as the app keeps it: sealed, in its own folder.
      final photoBytes = Uint8List.fromList(List.generate(70000, (i) => i % 7));
      final photos = await const InventoryPhotoService().photosDirectory();
      final photo = File(p.join(photos.path, 'backup-test-photo.jpg'));
      await const PhotoVault().write(photo, photoBytes);
      addTearDown(() async {
        if (await photo.exists()) await photo.delete();
      });
      await db.upsertInventoryItem(
        InventoryItemsCompanion.insert(
          clientId: 'water',
          householdId: 'home',
          name: 'Trinkwasser',
          category: 'water',
          quantity: 12,
          unit: 'l',
          storageLocation: 'Keller',
          updatedAt: DateTime.utc(2026, 10, 5),
          photoPath: Value(photo.path),
          dirty: const Value(true),
        ),
      );

      final archiveBytes = Uint8List.fromList(
        List.generate(3 * 1024 * 1024 + 17, (i) => (i * 13) % 256),
      );
      final archive = File(p.join(work.path, 'test_archive.zim'))
        ..writeAsBytesSync(archiveBytes);
      final map = File(p.join(work.path, 'test_map.pmtiles'))
        ..writeAsBytesSync(archiveBytes.sublist(0, 500000));
      await const ZimStore().save([
        StoredArchive(
          id: 'backuptest',
          location: archive.path,
          label: 'test_archive.zim',
        ),
      ], selectedId: 'backuptest');
      await const OfflineMapStore().save(
        location: map.path,
        label: 'test_map.pmtiles',
      );

      addTearDown(() async {
        await const ZimStore().save(const [], selectedId: null);
        await const OfflineMapStore().clear();
      });

      // Documents a previous run of the app left behind are not this
      // test's business.
      final candidates = [
        for (final candidate in await collectBackupFiles(
          db,
          householdId: 'home',
        ))
          if (candidate.entry.kind != BackupFileKind.document) candidate,
      ];
      expect(candidates.map((c) => c.entry.kind), [
        BackupFileKind.photo,
        BackupFileKind.map,
        BackupFileKind.archive,
      ]);

      final backup = File(p.join(work.path, 'sicherung.preppsuite'));
      final out = await backup.open(mode: FileMode.write);
      final unreadable = await BackupService(db).writeBackup(
        out: out,
        householdId: 'home',
        passphrase: 'secret-123',
        files: candidates,
      );
      await out.close();
      expect(unreadable, isEmpty);

      // The device loses everything but the backup.
      await archive.delete();
      await map.delete();
      await photo.delete();

      final source = await FileByteRangeSource.open(backup);
      addTearDown(source.close);
      final file = await BackupFile.read(source);
      final target = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(target.close);
      final opened = await BackupService(
        target,
      ).open(file!, 'secret-123', householdId: 'home');
      expect(opened, isNotNull);
      expect(await BackupService(target).restoreOpened(opened!), 1);

      final restoredInto = Directory(p.join(work.path, 'zurueck'));
      final archives = <String>[];
      final maps = <String>[];
      final result = await restoreBackupFiles(
        reader: file.reader!,
        key: opened.key,
        manifest: opened.files,
        selected: {for (final entry in opened.files) entry.index},
        targets: BackupFileTargets(
          folder: () async => restoredInto,
          addPhotos: (taken) => applyHouseholdPhotos(
            target,
            householdId: 'home',
            photos: taken,
          ),
          addDocument: (location, label, entry) async {},
          useMap: (location, label) async => maps.add(location),
          addArchive: (location, label, entry) async => archives.add(location),
        ),
      );
      expect(result.failed, isEmpty);
      expect(result.restored, 3);

      final item = (await target.watchInventoryItems('home').first).single;
      final restoredPhoto = File(
        InventoryPhotoService.resolvePhotoPath(item.photoPath!),
      );
      addTearDown(() async {
        if (await restoredPhoto.exists()) await restoredPhoto.delete();
      });
      expect(await const PhotoVault().read(restoredPhoto), photoBytes);
      expect(await File(archives.single).readAsBytes(), archiveBytes);
      expect(
        await File(maps.single).readAsBytes(),
        archiveBytes.sublist(0, 500000),
      );
    });
  });
}
