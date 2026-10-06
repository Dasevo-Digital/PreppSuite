import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:preppsuite_flutter/features/downloads/application/download_folder.dart';
import 'package:preppsuite_flutter/features/downloads/application/relink_files.dart';
import 'package:preppsuite_flutter/features/knowledge/application/zim_store.dart';
import 'package:preppsuite_flutter/features/maps/application/offline_map_store.dart';

/// An update moves the app's container; the archives stay in it (#120).
///
/// On iOS the folder the downloads go to has a container id in its path,
/// and an update can give the app a new one. This plays that out with
/// the real download folder: the file is in the folder of this run, the
/// stored path names a container that does not exist.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a download remembered under an old container is found', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final folder = await const DownloadFolder().current();
      final stamp = DateTime.now().millisecondsSinceEpoch;
      final zim = File(p.join(folder.path, 'relink-$stamp.zim'))
        ..writeAsBytesSync(List.filled(4096, 7));
      final map = File(p.join(folder.path, 'relink-$stamp.pmtiles'))
        ..writeAsBytesSync(List.filled(2048, 3));
      addTearDown(() async {
        await const ZimStore().save(const [], selectedId: null);
        await const OfflineMapStore().clear();
        for (final file in [zim, map]) {
          if (await file.exists()) await file.delete();
        }
      });

      const old =
          '/private/var/mobile/Containers/Data/Application/'
          '00000000-0000-0000-0000-000000000000/Documents';
      await const ZimStore().save([
        StoredArchive(
          id: 'relink',
          location: '$old/${p.basename(zim.path)}',
          label: p.basename(zim.path),
        ),
      ], selectedId: 'relink');
      await const OfflineMapStore().save(
        location: '$old/${p.basename(map.path)}',
        label: p.basename(map.path),
      );

      expect(await FileRelinker().run(), 2);
      final archive = (await const ZimStore().library()).archives.single;
      expect(File(archive.location).existsSync(), isTrue);
      expect(archive.id, 'relink');
      final stored = await const OfflineMapStore().archive();
      expect(File(stored!.location).existsSync(), isTrue);
    });
  });
}
