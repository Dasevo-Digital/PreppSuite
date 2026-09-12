import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/core/portable_data.dart';
import 'package:preppsuite_flutter/features/downloads/application/download_folder.dart';
import 'package:preppsuite_flutter/features/knowledge/application/zim_store.dart';
import 'package:preppsuite_flutter/features/maps/application/offline_map_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

/// What the relative-path rule actually buys, checked through the stores
/// that use it rather than through the helper they call.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory monday;
  late Directory tuesday;
  late Directory workspace;
  late SharedPreferencesStorePlatform platformStore;

  setUp(() {
    workspace = Directory.systemTemp.createTempSync('stores');
    // The same stick, seen as two different places on two machines.
    monday = Directory('${workspace.path}/E')..createSync();
    tuesday = Directory('${workspace.path}/F')..createSync();
    SharedPreferences.setMockInitialValues({});
    platformStore = SharedPreferencesStorePlatform.instance;
  });
  tearDown(() {
    SharedPreferencesStorePlatform.instance = platformStore;
    resetPortableData();
    workspace.deleteSync(recursive: true);
  });

  /// Runs [body] as a carried copy whose data folder is [where], keeping
  /// the settings in memory so both runs see the same stored values —
  /// which on a real stick they would, because it is one file on it.
  Future<T> carriedIn<T>(Directory where, Future<T> Function() body) async {
    resetPortableData();
    await startPortableData(
      environment: {portableEnvironmentVariable: where.path},
    );
    // The portable store would write into the folder; for this test the
    // in-memory one stands in, so that what was saved on Monday is still
    // there on Tuesday without a file having to survive.
    SharedPreferencesStorePlatform.instance = platformStore;
    return body();
  }

  String join(Directory root, List<String> parts) =>
      [root.path, ...parts].join(Platform.pathSeparator);

  test(
    'a map archive on the stick survives the stick changing letter',
    () async {
      await carriedIn(monday, () async {
        await const OfflineMapStore().save(
          location: join(monday, ['Archive', 'niedersachsen.pmtiles']),
          label: 'Niedersachsen',
        );
      });

      final found = await carriedIn(
        tuesday,
        () => const OfflineMapStore().archive(),
      );

      expect(
        found!.location,
        join(tuesday, ['Archive', 'niedersachsen.pmtiles']),
      );
      expect(found.label, 'Niedersachsen');
    },
  );

  test('a knowledge archive on the stick does too', () async {
    await carriedIn(monday, () async {
      await const ZimStore().save([
        StoredArchive(
          id: 'a',
          location: join(monday, ['Archive', 'wikipedia.zim']),
          label: 'Wikipedia',
        ),
      ], selectedId: 'a');
    });

    final library = await carriedIn(tuesday, () => const ZimStore().library());

    expect(
      library.archives.single.location,
      join(tuesday, ['Archive', 'wikipedia.zim']),
    );
  });

  test('an archive on the machine keeps its absolute path', () async {
    final elsewhere = Directory('${workspace.path}/rechner')..createSync();

    await carriedIn(monday, () async {
      await const OfflineMapStore().save(
        location: join(elsewhere, ['karte.pmtiles']),
        label: 'Karte',
      );
    });

    final found = await carriedIn(
      tuesday,
      () => const OfflineMapStore().archive(),
    );

    // Unchanged: a file on the machine's own disk is exactly as findable
    // as it ever was, and rewriting it relative to a stick would be wrong.
    expect(found!.location, join(elsewhere, ['karte.pmtiles']));
  });

  test('downloads go onto the disk the copy is carried on', () async {
    final folder = await carriedIn(
      monday,
      () => const DownloadFolder().defaultFolder(),
    );

    // Never ~/Downloads: on a machine that is not yours that is somebody
    // else's folder, and on a public one possibly wiped at logout.
    expect(folder.path, join(monday, ['Archive']));
  });
}
