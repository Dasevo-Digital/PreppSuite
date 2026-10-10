import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/knowledge/application/catalogue_presence.dart';
import 'package:preppsuite_flutter/features/knowledge/application/kiwix_catalogue.dart';
import 'package:preppsuite_flutter/features/knowledge/application/zim_store.dart';

/// Whether an archive in the library is already here (#37).
void main() {
  KiwixEntry entry({
    String name = 'wikipedia_de_all',
    String flavour = 'maxi',
    String file = 'wikipedia_de_all_maxi_2026-10.zim',
    String title = 'Wikipedia',
  }) => KiwixEntry(
    id: name,
    name: name,
    title: title,
    summary: '',
    language: 'deu',
    flavour: flavour,
    size: 1,
    articleCount: 1,
    hasFullTextIndex: true,
    downloadUrl: Uri.parse('https://download.kiwix.org/zim/wikipedia/$file'),
    illustrationPath: null,
  );

  StoredArchive stored({
    String location = '/Daten/Wissen/wikipedia_de_all_maxi_2026-10.zim',
    String label = 'Wikipedia',
    String? title = 'Wikipedia',
    String? fileName,
  }) => StoredArchive(
    id: 'a',
    location: location,
    label: label,
    title: title,
    fileName: fileName,
  );

  test('the same file is this build', () {
    expect(presenceOf(entry(), [stored()]), CataloguePresence.sameBuild);
  });

  test('an older build of the same flavour is another build', () {
    expect(
      presenceOf(entry(), [
        stored(location: '/Wissen/wikipedia_de_all_maxi_2026-01.zim'),
      ]),
      CataloguePresence.otherBuild,
    );
  });

  test('another flavour is not this archive', () {
    expect(
      presenceOf(entry(), [
        stored(location: '/Wissen/wikipedia_de_all_mini_2026-10.zim'),
      ]),
      CataloguePresence.absent,
    );
  });

  test('an archive without a flavour finds its older build', () {
    expect(
      presenceOf(
        entry(
          name: 'ifixit_de_all',
          flavour: '',
          file: 'ifixit_de_all_2026-03.zim',
          title: 'iFixit in German',
        ),
        [
          stored(
            location: '/Wissen/ifixit_de_all_2025-11.zim',
            title: 'iFixit in German',
          ),
        ],
      ),
      CataloguePresence.otherBuild,
    );
  });

  test('a shorter name does not claim a longer one', () {
    expect(
      presenceOf(
        entry(
          name: 'wikipedia_de',
          flavour: '',
          file: 'wikipedia_de_2026-10.zim',
        ),
        [stored()],
      ),
      CataloguePresence.absent,
    );
  });

  test('a Mac bookmark is recognised by the file name kept for it', () {
    expect(
      presenceOf(entry(), [
        stored(
          location: 'bookmark://BFDD0E14',
          fileName: 'wikipedia_de_all_maxi_2026-10.zim',
        ),
      ]),
      CataloguePresence.sameBuild,
    );
  });

  test(
    'a bookmark from before file names were kept falls back to its title',
    () {
      expect(
        presenceOf(entry(), [stored(location: 'bookmark://BFDD0E14')]),
        CataloguePresence.otherBuild,
      );
    },
  );

  test('an Android document URI names its file', () {
    expect(
      presenceOf(entry(), [
        stored(
          location:
              'content://com.android.externalstorage.documents/document/'
              'primary%3ADownload%2Fwikipedia_de_all_maxi_2026-10.zim',
        ),
      ]),
      CataloguePresence.sameBuild,
    );
  });

  test('nothing of it here', () {
    expect(
      presenceOf(entry(), [
        stored(
          location: '/Wissen/klexikon_de_all_maxi_2026-08.zim',
          label: 'Klexikon',
          title: 'Klexikon',
        ),
      ]),
      CataloguePresence.absent,
    );
  });

  test('the file name survives being stored', () {
    final archive = stored(
      location: 'bookmark://BFDD0E14',
      fileName: 'wikipedia_de_all_maxi_2026-10.zim',
    );
    final back = StoredArchive.fromJson(archive.toJson())!;

    expect(back.fileName, 'wikipedia_de_all_maxi_2026-10.zim');
  });
}
