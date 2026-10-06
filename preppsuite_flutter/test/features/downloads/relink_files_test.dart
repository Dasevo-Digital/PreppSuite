import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/downloads/application/relink_files.dart';
import 'package:preppsuite_flutter/features/knowledge/application/personal_document_store.dart';
import 'package:preppsuite_flutter/features/knowledge/application/zim_store.dart';
import 'package:preppsuite_flutter/features/maps/application/offline_map_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// After an update the files are where they were and the app has lost
/// the way to them (#120). What it can reach, it finds again.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory folder;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    folder = await Directory.systemTemp.createTemp('relink');
  });
  tearDown(() => folder.delete(recursive: true));

  File put(String name, int size) =>
      File('${folder.path}/$name')..writeAsBytesSync(List.filled(size, 1));

  FileRelinker relinker({Set<String> broken = const {}}) => FileRelinker(
    folders: () async => [folder],
    // What is "broken" does not open; every path in the folder does.
    opens: (location) async =>
        !broken.contains(location) && File(location).existsSync(),
    remember: (path, label) async => path,
  );

  test('the map and the archives are found again by name', () async {
    final map = put('karte.pmtiles', 10);
    final wiki = put('wikipedia_de.zim', 20);
    await const OfflineMapStore().save(
      location: '/old/container/Documents/karte.pmtiles',
      label: 'karte.pmtiles',
    );
    await const ZimStore().save(const [
      StoredArchive(
        id: 'wiki',
        location: '/old/container/Documents/wikipedia_de.zim',
        label: 'wikipedia_de.zim',
      ),
    ], selectedId: 'wiki');

    expect(await relinker().run(), 2);
    expect((await const OfflineMapStore().archive())!.location, map.path);
    final library = await const ZimStore().library();
    expect(library.archives.single.location, wiki.path);
    expect(library.archives.single.id, 'wiki', reason: 'the index stays');
    expect(library.selectedId, 'wiki');
  });

  test('a downloaded map is found by the name in its old path', () async {
    final map = put('map-1234.pmtiles', 10);
    put('other.pmtiles', 11);
    await const OfflineMapStore().save(
      location: '/old/container/Documents/map-1234.pmtiles',
      label: 'Niedersachsen',
    );
    expect(await relinker().run(), 1);
    expect((await const OfflineMapStore().archive())!.location, map.path);
  });

  test('a picked map is found as the one map file there is', () async {
    final map = put('karte.pmtiles', 10);
    await const OfflineMapStore().save(
      location: 'bookmark://gone',
      label: 'Niedersachsen',
    );
    expect(await relinker(broken: {'bookmark://gone'}).run(), 1);
    expect((await const OfflineMapStore().archive())!.location, map.path);
  });

  test('an archive named by its title is found by its size', () async {
    final gutenberg = put('gutenberg_de_all.zim', 33);
    put('other.zim', 34);
    await const ZimStore().save(const [
      StoredArchive(
        id: 'g',
        location: 'bookmark://gone',
        label: 'Projekt Gutenberg-Bibliothek',
        sizeBytes: 33,
      ),
    ], selectedId: null);

    expect(await relinker(broken: {'bookmark://gone'}).run(), 1);
    expect(
      (await const ZimStore().library()).archives.single.location,
      gutenberg.path,
    );
  });

  test('two files of the same size are not guessed between', () async {
    put('a.zim', 33);
    put('b.zim', 33);
    await const ZimStore().save(const [
      StoredArchive(
        id: 'g',
        location: 'bookmark://gone',
        label: 'Titel',
        sizeBytes: 33,
      ),
    ], selectedId: null);
    expect(await relinker(broken: {'bookmark://gone'}).run(), 0);
    expect(
      (await const ZimStore().library()).archives.single.location,
      'bookmark://gone',
    );
  });

  test('what opens, and what is not found, is left alone', () async {
    final working = put('working.zim', 5);
    await const ZimStore().save([
      StoredArchive(id: 'w', location: working.path, label: 'working.zim'),
      const StoredArchive(
        id: 'm',
        location: '/Volumes/Unplugged/missing.zim',
        label: 'missing.zim',
      ),
    ], selectedId: 'w');
    expect(await relinker().run(), 0);
    final locations = (await const ZimStore().library()).archives.map(
      (a) => a.location,
    );
    expect(locations, [working.path, '/Volumes/Unplugged/missing.zim']);
  });

  test('a document keeps its index when it is found again', () async {
    final pdf = put('police.pdf', 7);
    await const PersonalDocumentStore().add(
      location: '/old/container/Documents/police.pdf',
      label: 'police.pdf',
    );
    final id = (await const PersonalDocumentStore().load()).single.id;
    await const PersonalDocumentStore().updateIndex(
      id,
      status: 'ready',
      characters: 1200,
    );

    expect(await relinker().run(), 1);
    final document = (await const PersonalDocumentStore().load()).single;
    expect(document.location, pdf.path);
    expect(document.indexStatus, 'ready');
    expect(document.indexedCharacters, 1200);
  });
}
