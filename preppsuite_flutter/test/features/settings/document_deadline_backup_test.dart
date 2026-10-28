import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/knowledge/application/personal_document_store.dart';
import 'package:preppsuite_flutter/features/maps/application/pmtiles_archive.dart';
import 'package:preppsuite_flutter/features/settings/application/backup_files.dart';
import 'package:preppsuite_flutter/features/settings/application/backup_service.dart';
import 'package:preppsuite_flutter/local_db/database.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'deadline metadata survives an encrypted backup and file restoration',
    () async {
      final root = await Directory.systemTemp.createTemp('deadline-backup-');
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(() async {
        await db.close();
        await root.delete(recursive: true);
      });
      final original = File('${root.path}/Plan.md')..writeAsStringSync('Plan');
      const store = PersonalDocumentStore();
      final doc = (await store.add(
        location: original.path,
        label: 'Plan.md',
      )).single;
      await store.updateDeadline(
        doc.id,
        validUntil: DateTime(2028, 2, 29),
        remindOn: DateTime(2028, 1, 1),
        reviewedOn: DateTime(2026, 10, 28),
        originalLocation: 'Privatablage-Pruefung-730',
      );
      final candidates = await collectBackupFiles(db, householdId: 'home');
      final file = File('${root.path}/backup.preppsuite');
      final out = await file.open(mode: FileMode.write);
      await BackupService(db).writeBackup(
        out: out,
        householdId: 'home',
        passphrase: 'test-only-passphrase',
        files: candidates,
      );
      await out.close();
      expect(
        latin1.decode(await file.readAsBytes()),
        isNot(contains('Privatablage-Pruefung-730')),
      );
      final source = await FileByteRangeSource.open(file);
      addTearDown(source.close);
      final backup = (await BackupFile.read(source))!;
      final opened = (await BackupService(db)
          .open(backup, 'test-only-passphrase', householdId: 'home'))!;
      await store.remove(doc.id);
      final result = await restoreBackupFiles(
        reader: opened.file.reader!,
        key: opened.key,
        manifest: opened.files,
        selected: {opened.files.single.index},
        targets: BackupFileTargets(
          folder: () async => Directory('${root.path}/restored'),
          addPhotos: (_) async => 0,
          useMap: (_, _) async {},
          addArchive: (_, _, _) async {},
          addDocument: (location, label, entry) async {
            final restored = (await store.add(
              location: location,
              label: label,
            )).single;
            await store.restoreDeadline(
              restored,
              entry.meta['documentDeadline'],
            );
          },
        ),
      );
      expect(result.failed, isEmpty);
      final restored = (await store.load()).single;
      expect(restored.validUntil, DateTime(2028, 2, 29));
      expect(restored.remindOn, DateTime(2028, 1, 1));
      expect(restored.reviewedOn, DateTime(2026, 10, 28));
      expect(restored.originalLocation, 'Privatablage-Pruefung-730');
      expect(await File(restored.location).readAsString(), 'Plan');
    },
  );

  test('old backup metadata does not clear current deadlines or overwrite identity', () async {
    const store = PersonalDocumentStore();
    final d = (await store.add(location: '/docs/a.md', label: 'A.md')).single;
    await store.updateDeadline(
      d.id,
      validUntil: DateTime(2027),
      remindOn: null,
      reviewedOn: null,
      originalLocation: 'A',
    );
    await store.restoreDeadline(d, null);
    expect((await store.load()).single.validUntil, DateTime(2027));
    await store.restoreDeadline(d, {
      'id': 'other',
      'location': '/other',
      'label': 'Other',
      'validUntil': '2028-01-01',
      'originalLocation': 'B',
    });
    final kept = (await store.load()).single;
    expect(kept.id, d.id);
    expect(kept.location, d.location);
    expect(kept.label, d.label);
    expect(kept.validUntil, DateTime(2028));
  });
}
