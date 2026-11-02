import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:preppsuite_flutter/features/downloads/application/download_folder.dart';
import 'package:preppsuite_flutter/features/downloads/application/download_providers.dart';
import 'package:preppsuite_flutter/features/first_aid/application/first_aid_providers.dart';
import 'package:preppsuite_flutter/features/maps/application/map_area_download.dart';
import 'package:preppsuite_flutter/features/maps/application/map_download_plan.dart';
import 'package:preppsuite_flutter/features/maps/application/map_download_providers.dart';
import 'package:preppsuite_flutter/features/maps/application/map_download_session.dart';
import 'package:preppsuite_flutter/features/maps/application/pmtiles_writer.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// What lives in the download folder follows it when the folder is
/// changed, not at the next start of the app (#246).
void main() {
  late Directory first;
  late Directory second;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    first = await Directory.systemTemp.createTemp('downloads_first');
    second = await Directory.systemTemp.createTemp('downloads_second');
    container = ProviderContainer();
  });
  tearDown(() async {
    container.dispose();
    await first.delete(recursive: true);
    await second.delete(recursive: true);
  });

  /// What the settings card does after the folder picker.
  Future<void> choose(Directory folder) async {
    await const DownloadFolder().use(folder.path);
    container.invalidate(downloadFolderProvider);
  }

  test('the first aid video pack goes to the folder chosen now', () async {
    await choose(first);
    final before = await container.read(firstAidLibraryProvider.future);
    expect(p.isWithin(first.path, before.folder.path), isTrue);

    await choose(second);
    final after = await container.read(firstAidLibraryProvider.future);
    expect(
      p.isWithin(second.path, after.folder.path),
      isTrue,
      reason: 'a pack fetched now lands where the app will look next time',
    );
  });

  test(
    'an unfinished map download is looked for in the folder in use',
    () async {
      final writer = await PmTilesWriter.create(first);
      await writer.add(6, 33, 20, utf8.encode('a tile'));
      await writer.close();
      await const MapDownloadSessionStore().write(
        first,
        MapDownloadSession(
          plan: MapDownloadPlan([
            MapDownloadStep(
              label: 'Hannover',
              area: const MapArea(
                minLongitude: 9.6,
                minLatitude: 52.3,
                maxLongitude: 9.9,
                maxLatitude: 52.45,
                maxZoom: 12,
              ),
            ),
          ]),
          targetPath: p.join(first.path, 'karte.pmtiles'),
          label: 'Hannover (12)',
          startedAt: DateTime(2026, 11, 2, 10),
        ),
      );

      await choose(first);
      expect(
        await container.read(unfinishedDownloadProvider.future),
        isNotNull,
      );

      await choose(second);
      expect(await container.read(unfinishedDownloadProvider.future), isNull);
    },
  );
}
