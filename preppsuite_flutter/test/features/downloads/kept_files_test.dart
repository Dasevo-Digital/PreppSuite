import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/core/platform_storage.dart';
import 'package:preppsuite_flutter/features/downloads/application/kept_files.dart';
import 'package:preppsuite_flutter/features/knowledge/application/personal_document_store.dart';
import 'package:preppsuite_flutter/features/knowledge/application/zim_store.dart';
import 'package:preppsuite_flutter/features/maps/application/offline_map_store.dart';
import 'package:preppsuite_flutter/features/settings/presentation/backup_flow.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Android keeps 128 lasting grants up to version 10 and 512 after, and
/// past that drops the oldest without a word, often the shared folder's
/// (#410). Every pick took one and none was ever given back.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<MethodCall> calls;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    calls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(nativeStorageChannel, (call) async {
          calls.add(call);
          return call.method == 'release' ? true : null;
        });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(nativeStorageChannel, null);
  });

  const first =
      'content://com.example.documents/document/primary%3Akarte.pmtiles';
  const second =
      'content://com.example.documents/document/primary%3Aneu.pmtiles';

  List<String> released() => [
    for (final call in calls)
      if (call.method == 'release') (call.arguments as Map)['uri'] as String,
  ];

  test('a backup picked to restore takes no lasting grant', () async {
    if (!usesNativeStoragePicker) return;
    expect(await pickBackup(dialogTitle: 'Sicherung'), isNull);
    final pick = calls.single;
    expect(pick.method, 'pickFile');
    expect((pick.arguments as Map)['keep'], isFalse);
  });

  test('a map replaced or forgotten gives its grant back', () async {
    const store = OfflineMapStore();
    await store.save(location: first, label: 'Karte');
    expect(released(), isEmpty);
    await store.save(location: second, label: 'Neu');
    expect(released(), [first]);
    await store.clear();
    expect(released(), [first, second]);
  });

  test('a file still remembered elsewhere keeps its grant', () async {
    await const ZimStore().save(const [
      StoredArchive(id: 'a', location: first, label: 'Archiv'),
    ], selectedId: 'a');
    await const PersonalDocumentStore().add(location: second, label: 'x.pdf');
    await const OfflineMapStore().save(location: first, label: 'Karte');
    await const OfflineMapStore().save(location: second, label: 'Karte');
    await const OfflineMapStore().clear();
    expect(released(), isEmpty);
  });

  test('an archive that leaves the library gives its grant back', () async {
    const store = ZimStore();
    await store.save(const [
      StoredArchive(id: 'a', location: first, label: 'A'),
      StoredArchive(id: 'b', location: second, label: 'B'),
    ], selectedId: 'a');
    await store.save(const [
      StoredArchive(id: 'b', location: second, label: 'B'),
    ], selectedId: 'b');
    expect(released(), [first]);
  });

  test('a document removed, moved or forgotten gives its grant back', () async {
    const store = PersonalDocumentStore();
    final added = await store.add(location: first, label: 'a.pdf');
    await store.relocate(added.single.id, second);
    expect(released(), [first]);
    await store.relocate(added.single.id, second);
    expect(released(), [first], reason: 'the same handle is still in use');

    final other = await store.add(location: first, label: 'b.pdf');
    await store.remove(other.last.id);
    expect(released(), [first, first]);
    await store.clear();
    expect(released(), [first, first, second]);
  });

  test('a path is never sent across', () async {
    const store = OfflineMapStore();
    await store.save(location: '/maps/karte.pmtiles', label: 'Karte');
    await store.save(location: 'bookmark://karte', label: 'Karte');
    await store.clear();
    await releaseUnkeptFiles(['/maps/karte.pmtiles', 'bookmark://karte']);
    expect(calls, isEmpty);
  });
}
