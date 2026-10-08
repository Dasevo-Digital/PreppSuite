import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/maps/application/pmtiles_archive.dart';
import 'package:preppsuite_flutter/features/settings/application/backup_container.dart';
import 'package:preppsuite_flutter/features/settings/application/backup_files.dart';
import 'package:preppsuite_flutter/features/settings/application/backup_service.dart';
import 'package:preppsuite_flutter/features/transfer/application/handover_photos.dart';
import 'package:preppsuite_flutter/local_db/database.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Format 3: a backup that carries the files beside the rows (#114).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  late Directory temp;
  late AppDatabase source;
  late AppDatabase target;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('backup3');
    source = AppDatabase.forTesting(NativeDatabase.memory());
    target = AppDatabase.forTesting(NativeDatabase.memory());
    await source.upsertInventoryItem(
      InventoryItemsCompanion.insert(
        clientId: 'water',
        householdId: 'home',
        name: 'Trinkwasser',
        category: 'water',
        quantity: 12,
        unit: 'l',
        storageLocation: 'Keller',
        updatedAt: DateTime.utc(2026, 9, 8),
        dirty: const Value(true),
      ),
    );
  });

  tearDown(() async {
    await source.close();
    await target.close();
    await temp.delete(recursive: true);
  });

  // Larger than one chunk, so the chunking is exercised and not only the
  // single-chunk case.
  final archiveBytes = Uint8List.fromList(
    List.generate(backupChunkSize * 2 + 4321, (i) => (i * 31) % 251),
  );
  final photoBytes = Uint8List.fromList(utf8.encode('JPEG-' * 1000));
  final documentBytes = Uint8List.fromList(
    utf8.encode('Versicherungsschein Nummer 4711 ' * 2000),
  );

  List<BackupCandidate> candidates() => [
    BackupCandidate(
      entry: BackupFileEntry(
        index: 0,
        kind: BackupFileKind.photo,
        label: 'b3f0.jpg',
        size: photoBytes.length,
        meta: const {'owner': 'inventory', 'clientId': 'water'},
      ),
      open: () async => MemoryByteRangeSource(photoBytes),
    ),
    BackupCandidate(
      entry: BackupFileEntry(
        index: 1,
        kind: BackupFileKind.document,
        label: 'police.pdf',
        size: documentBytes.length,
        meta: const {'indexed': true},
      ),
      open: () async => MemoryByteRangeSource(documentBytes),
    ),
    BackupCandidate(
      entry: BackupFileEntry(
        index: 2,
        kind: BackupFileKind.archive,
        label: 'wikipedia_de_test.zim',
        size: archiveBytes.length,
        meta: const {'selected': true},
      ),
      open: () async => MemoryByteRangeSource(archiveBytes),
    ),
  ];

  Future<File> write({List<BackupCandidate>? files}) async {
    final file = File('${temp.path}/sicherung.preppsuite');
    final out = await file.open(mode: FileMode.write);
    await BackupService(source).writeBackup(
      out: out,
      householdId: 'home',
      passphrase: 'secret-123',
      files: files ?? candidates(),
    );
    await out.close();
    return file;
  }

  Future<OpenedBackup?> open(File file, [String pass = 'secret-123']) async {
    final backup = await BackupFile.read(await FileByteRangeSource.open(file));
    return BackupService(target).open(backup!, pass, householdId: 'home');
  }

  ({
    BackupFileTargets targets,
    List<HandoverPhoto> photos,
    List<String> documents,
    List<String> archives,
  })
  targetsInto(Directory folder) {
    final photos = <HandoverPhoto>[];
    final documents = <String>[];
    final archives = <String>[];
    return (
      targets: BackupFileTargets(
        folder: () async => folder,
        addPhotos: (taken) async {
          photos.addAll(taken);
          return taken.length;
        },
        addDocument: (location, label, entry) async => documents.add(location),
        useMap: (location, label) async {},
        addArchive: (location, label, entry) async => archives.add(location),
      ),
      photos: photos,
      documents: documents,
      archives: archives,
    );
  }

  test('rows and files come back, byte for byte', () async {
    final file = await write();
    final opened = await open(file);
    expect(opened, isNotNull);
    expect(opened!.files.map((e) => e.label), [
      'b3f0.jpg',
      'police.pdf',
      'wikipedia_de_test.zim',
    ]);

    expect(await BackupService(target).restoreOpened(opened), 1);

    final folder = Directory('${temp.path}/ziel');
    final into = targetsInto(folder);
    final result = await restoreBackupFiles(
      reader: opened.file.reader!,
      key: opened.key,
      manifest: opened.files,
      selected: {0, 1, 2},
      targets: into.targets,
    );

    expect(result.failed, isEmpty);
    expect(result.restored, 3);
    expect(into.photos.single.bytes, photoBytes);
    expect(into.photos.single.clientId, 'water');
    expect(await File(into.documents.single).readAsBytes(), documentBytes);
    expect(
      into.documents.single,
      contains(restoredDocumentsFolder),
      reason: 'the household papers go into a folder of their own',
    );
    expect(await File(into.archives.single).readAsBytes(), archiveBytes);
    expect(
      folder.listSync(recursive: true).whereType<File>().map((f) => f.path),
      everyElement(isNot(endsWith('.part'))),
    );
  });

  test('private files are encrypted, public ones are not', () async {
    final bytes = await (await write()).readAsBytes();
    final text = latin1.decode(bytes);
    expect(text.contains('Versicherungsschein'), isFalse);
    expect(text.contains('JPEG-JPEG'), isFalse);
    // Which files a household keeps is in the encrypted list only.
    expect(text.contains('police.pdf'), isFalse);
    expect(text.contains('wikipedia_de_test'), isFalse);
  });

  test('a wrong passphrase opens nothing', () async {
    expect(await open(await write(), 'wrong-pass'), isNull);
  });

  test('an altered archive is refused, not restored', () async {
    final file = await write();
    final bytes = await file.readAsBytes();
    // Somewhere in the middle of the archive's plain bytes.
    final marker = archiveBytes.sublist(backupChunkSize, backupChunkSize + 64);
    final at = _indexOf(bytes, marker);
    expect(at, greaterThan(0));
    bytes[at + 10] ^= 0xff;
    await file.writeAsBytes(bytes);

    final opened = (await open(file))!;
    final folder = Directory('${temp.path}/ziel');
    final into = targetsInto(folder);
    final result = await restoreBackupFiles(
      reader: opened.file.reader!,
      key: opened.key,
      manifest: opened.files,
      selected: {2},
      targets: into.targets,
    );
    expect(result.failed, ['wikipedia_de_test.zim']);
    expect(into.archives, isEmpty);
    expect(folder.listSync(recursive: true).whereType<File>(), isEmpty);
  });

  test('what was not asked for is skipped, not written', () async {
    final opened = (await open(await write()))!;
    final into = targetsInto(Directory('${temp.path}/ziel'));
    final result = await restoreBackupFiles(
      reader: opened.file.reader!,
      key: opened.key,
      manifest: opened.files,
      selected: {0},
      targets: into.targets,
    );
    expect(result.restored, 1);
    expect(into.archives, isEmpty);
    expect(into.documents, isEmpty);
  });

  test('a file of the same name and size already there is used', () async {
    final opened = (await open(await write()))!;
    final folder = Directory('${temp.path}/ziel')..createSync();
    final existing = File('${folder.path}/wikipedia_de_test.zim')
      ..writeAsBytesSync(archiveBytes);
    final modified = existing.lastModifiedSync();

    final into = targetsInto(folder);
    await restoreBackupFiles(
      reader: opened.file.reader!,
      key: opened.key,
      manifest: opened.files,
      selected: {2},
      targets: into.targets,
    );
    expect(into.archives.single, existing.path);
    expect(existing.lastModifiedSync(), modified);
  });

  // What restoring must never do is write over a file that is already
  // there and is not the one in the backup (#132).
  test(
    'a different file of the same name is kept, the restore goes beside it',
    () async {
      final opened = (await open(await write()))!;
      final folder = Directory('${temp.path}/ziel')..createSync();
      final mine = Uint8List.fromList(utf8.encode('meine eigene Datei'));
      final existing = File('${folder.path}/wikipedia_de_test.zim')
        ..writeAsBytesSync(mine);

      final into = targetsInto(folder);
      final result = await restoreBackupFiles(
        reader: opened.file.reader!,
        key: opened.key,
        manifest: opened.files,
        selected: {2},
        targets: into.targets,
      );
      expect(result.restored, 1);
      expect(existing.readAsBytesSync(), mine);
      expect(into.archives.single, '${folder.path}/wikipedia_de_test (2).zim');
      expect(File(into.archives.single).readAsBytesSync(), archiveBytes);
    },
  );

  test('a cancelled restore leaves no half file behind', () async {
    final opened = (await open(await write()))!;
    final folder = Directory('${temp.path}/ziel');
    final cancellation = BackupCancellation();
    final into = targetsInto(folder);
    await expectLater(
      restoreBackupFiles(
        reader: opened.file.reader!,
        key: opened.key,
        manifest: opened.files,
        selected: {2},
        targets: into.targets,
        cancellation: cancellation,
        // After the first chunk of the archive, which has three.
        onBytes: (entry, bytes) => cancellation.cancel(),
      ),
      throwsA(isA<BackupCancelled>()),
    );
    expect(into.archives, isEmpty);
    expect(
      folder.listSync().map((e) => e.path.split('/').last),
      isNot(contains(endsWith('.part'))),
    );
    expect(File('${folder.path}/wikipedia_de_test.zim').existsSync(), isFalse);
  });

  test(
    'a file the app cannot take into use is named, the rest come back',
    () async {
      final opened = (await open(await write()))!;
      final into = targetsInto(Directory('${temp.path}/ziel'));
      final refusing = BackupFileTargets(
        folder: into.targets.folder,
        addPhotos: into.targets.addPhotos,
        addDocument: into.targets.addDocument,
        useMap: into.targets.useMap,
        addArchive: (location, label, entry) async =>
            throw const FormatException('not a ZIM file'),
      );
      final result = await restoreBackupFiles(
        reader: opened.file.reader!,
        key: opened.key,
        manifest: opened.files,
        selected: {0, 1, 2},
        targets: refusing,
      );
      expect(result.restored, 2);
      expect(result.failed, ['wikipedia_de_test.zim']);
      expect(into.photos, hasLength(1));
      expect(into.documents, hasLength(1));
    },
  );

  test(
    'documents go into their own folder, the map is taken into use',
    () async {
      final mapBytes = Uint8List.fromList(utf8.encode('PMTiles' * 300));
      final files = [
        ...candidates(),
        BackupCandidate(
          entry: BackupFileEntry(
            index: 3,
            kind: BackupFileKind.map,
            label: 'Niedersachsen.pmtiles',
            size: mapBytes.length,
          ),
          open: () async => MemoryByteRangeSource(mapBytes),
        ),
      ];
      final opened = (await open(await write(files: files)))!;
      final folder = Directory('${temp.path}/ziel');
      final maps = <(String, String)>[];
      final into = targetsInto(folder);
      final result = await restoreBackupFiles(
        reader: opened.file.reader!,
        key: opened.key,
        manifest: opened.files,
        selected: {1, 3},
        targets: BackupFileTargets(
          folder: into.targets.folder,
          addPhotos: into.targets.addPhotos,
          addDocument: into.targets.addDocument,
          useMap: (location, label) async => maps.add((location, label)),
          addArchive: into.targets.addArchive,
        ),
      );
      expect(result.restored, 2);
      expect(
        into.documents.single,
        '${folder.path}/$restoredDocumentsFolder/police.pdf',
      );
      expect(maps.single.$2, 'Niedersachsen.pmtiles');
      expect(File(maps.single.$1).readAsBytesSync(), mapBytes);
    },
  );

  test(
    'a picture whose row it belongs to is unknown is not guessed at',
    () async {
      final files = candidates()
        ..[0] = BackupCandidate(
          entry: BackupFileEntry(
            index: 0,
            kind: BackupFileKind.photo,
            label: 'b3f0.jpg',
            size: photoBytes.length,
            meta: const {'owner': 'inventory'},
          ),
          open: () async => MemoryByteRangeSource(photoBytes),
        );
      final opened = (await open(await write(files: files)))!;
      final into = targetsInto(Directory('${temp.path}/ziel'));
      final result = await restoreBackupFiles(
        reader: opened.file.reader!,
        key: opened.key,
        manifest: opened.files,
        selected: {0},
        targets: into.targets,
      );
      expect(into.photos, isEmpty);
      expect(result.failed, ['b3f0.jpg']);
    },
  );

  test('a file that could not be read is listed as missing', () async {
    final files = candidates()
      ..[1] = BackupCandidate(
        entry: candidates()[1].entry,
        open: () async => throw const FileSystemException('unplugged'),
      );
    final file = File('${temp.path}/sicherung.preppsuite');
    final out = await file.open(mode: FileMode.write);
    final unreadable = await BackupService(source).writeBackup(
      out: out,
      householdId: 'home',
      passphrase: 'secret-123',
      files: files,
    );
    await out.close();
    expect(unreadable, ['police.pdf']);

    final opened = (await open(file))!;
    final into = targetsInto(Directory('${temp.path}/ziel'));
    final result = await restoreBackupFiles(
      reader: opened.file.reader!,
      key: opened.key,
      manifest: opened.files,
      selected: {0, 1, 2},
      targets: into.targets,
    );
    expect(result.restored, 2);
    expect(result.failed, ['police.pdf']);
  });

  test('a format 2 backup still opens through the same road', () async {
    final raw = await BackupService(
      source,
    ).exportHousehold('home', 'secret-123');
    final file = File('${temp.path}/alt.json')..writeAsStringSync(raw);
    final opened = await open(file);
    expect(opened, isNotNull);
    expect(opened!.files, isEmpty);
    expect(opened.file.reader, isNull);
    expect(await BackupService(target).restoreOpened(opened), 1);
  });

  test('a cancelled write stops between chunks', () async {
    final cancellation = BackupCancellation();
    final file = File('${temp.path}/sicherung.preppsuite');
    final out = await file.open(mode: FileMode.write);
    await expectLater(
      BackupService(source).writeBackup(
        out: out,
        householdId: 'home',
        passphrase: 'secret-123',
        files: candidates(),
        cancellation: cancellation,
        onFile: (entry) {
          if (entry.kind == BackupFileKind.archive) cancellation.cancel();
        },
      ),
      throwsA(isA<BackupCancelled>()),
    );
    await out.close();
  });
}

int _indexOf(List<int> haystack, List<int> needle) {
  outer:
  for (var i = 0; i <= haystack.length - needle.length; i++) {
    for (var j = 0; j < needle.length; j++) {
      if (haystack[i + j] != needle[j]) continue outer;
    }
    return i;
  }
  return -1;
}
