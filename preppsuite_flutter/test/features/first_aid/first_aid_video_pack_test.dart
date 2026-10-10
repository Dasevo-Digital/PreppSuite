import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/first_aid/application/first_aid_video_pack.dart';

/// A pack description is a document fetched from an address somebody
/// typed, or a zip off a stick somebody was handed. Both are untrusted
/// input, and both are usually something else entirely -- a captive
/// portal's login page, the wrong zip.
void main() {
  late Directory temp;
  late FirstAidVideoLibrary library;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('first-aid-pack');
    library = FirstAidVideoLibrary(Directory('${temp.path}/ErsteHilfe'));
  });

  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  String manifest({
    String file = 'cpr.mp4',
    int format = 1,
    String? url = 'https://example.invalid/cpr.mp4',
    int? bytes = 1234,
  }) => jsonEncode({
    'format': format,
    'name': 'Erste Hilfe – Videos',
    'language': 'de',
    'videos': [
      {
        'id': 'cpr-1',
        'guide': 'cpr-adult',
        'title': 'Herzdruckmassage',
        'file': file,
        'credit': 'Jemand',
        'licence': 'CC BY-SA 4.0',
        'url': ?url,
        'bytes': ?bytes,
        'seconds': 95,
      },
    ],
  });

  group('reading a description', () {
    test('a well-formed one comes back whole', () {
      final pack = FirstAidVideoPack.parse(manifest());
      expect(pack.name, 'Erste Hilfe – Videos');
      expect(pack.videos.single.guideId, 'cpr-adult');
      expect(pack.videos.single.length, const Duration(seconds: 95));
      expect(pack.totalBytes, 1234);
    });

    test('who made it and who checked it come along (#58)', () {
      final decoded = jsonDecode(manifest()) as Map<String, Object?>;
      final pack = FirstAidVideoPack.parse(
        jsonEncode({
          ...decoded,
          'publisher': 'Ortsverein Musterstadt',
          'reviewedBy': 'Notfallsanitäterin, Oktober 2026',
          'about': 'Eigene Aufnahmen, CC BY 4.0.',
        }),
      );

      expect(pack.publisher, 'Ortsverein Musterstadt');
      expect(pack.reviewedBy, 'Notfallsanitäterin, Oktober 2026');
      expect(pack.about, 'Eigene Aufnahmen, CC BY 4.0.');
      final again = FirstAidVideoPack.parse(pack.toJsonString());
      expect(again.reviewedBy, pack.reviewedBy);
    });

    test('a pack that does not say stays without, not invented', () {
      final pack = FirstAidVideoPack.parse(manifest());

      expect(pack.publisher, isNull);
      expect(pack.reviewedBy, isNull);
    });

    test('a login page is refused with a sentence, not a stack trace', () {
      expect(
        () => FirstAidVideoPack.parse('<html><body>Sign in</body></html>'),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            'That is not a pack description.',
          ),
        ),
      );
    });

    test('a newer format says so rather than being half-read', () {
      expect(
        () => FirstAidVideoPack.parse(manifest(format: 99)),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('newer version'),
          ),
        ),
      );
    });

    test('a description with nothing usable in it is refused', () {
      expect(
        () => FirstAidVideoPack.parse(
          jsonEncode({'format': 1, 'videos': <Object>[]}),
        ),
        throwsA(isA<FormatException>()),
      );
    });

    group('a file name that is a path', () {
      test('is dropped rather than written anywhere', () {
        // The whole reason file names are checked: a manifest comes from
        // the network, and one naming ../../ would be a way to write
        // outside the pack folder.
        expect(
          () => FirstAidVideoPack.parse(manifest(file: '../../evil.mp4')),
          throwsA(isA<FormatException>()),
        );
      });

      test('and one bad line does not cost the whole pack', () {
        final two = jsonEncode({
          'format': 1,
          'videos': [
            {
              'id': 'bad',
              'guide': 'cpr-adult',
              'title': 'x',
              'file': '/etc/passwd',
              'credit': '',
              'licence': '',
            },
            {
              'id': 'good',
              'guide': 'cpr-adult',
              'title': 'y',
              'file': 'good.mp4',
              'credit': '',
              'licence': '',
            },
          ],
        });
        expect(FirstAidVideoPack.parse(two).videos.single.id, 'good');
      });
    });
  });

  group('where a file is fetched from', () {
    test('an absolute address is used as it stands', () {
      final pack = FirstAidVideoPack.parse(manifest());
      expect(
        pack.resolve(pack.videos.single).toString(),
        'https://example.invalid/cpr.mp4',
      );
    });

    test('a relative one is resolved against the description itself', () {
      // So a manifest does not repeat the same host on every line, and
      // so a pack can be moved to another mirror by moving the folder.
      final pack = FirstAidVideoPack.parse(
        manifest(url: 'cpr.mp4'),
        from: Uri.parse('https://example.invalid/pakete/paket.json'),
      );
      expect(
        pack.resolve(pack.videos.single).toString(),
        'https://example.invalid/pakete/cpr.mp4',
      );
    });

    test('a video with no address at all resolves to nothing', () {
      final pack = FirstAidVideoPack.parse(manifest(url: null));
      expect(pack.resolve(pack.videos.single), isNull);
    });
  });

  test('a description survives being written out and read back', () {
    final pack = FirstAidVideoPack.parse(manifest());
    final again = FirstAidVideoPack.parse(pack.toJsonString());
    expect(again.videos.single.id, pack.videos.single.id);
    expect(again.videos.single.licence, 'CC BY-SA 4.0');
  });

  group('checking what arrived', () {
    late FirstAidVideo video;

    setUp(() async {
      await library.folder.create(recursive: true);
      video = FirstAidVideoPack.parse(manifest(bytes: 5)).videos.single;
    });

    test('a file of the wrong length is refused and deleted', () async {
      await library.fileFor(video).writeAsBytes([1, 2, 3]);
      expect(await library.verify(video), contains('size'));
      // Deleted, because a short file kept under its final name is a
      // file the app would later try to play.
      expect(await library.fileFor(video).exists(), isFalse);
    });

    test(
      'a file of the right length passes when no checksum is given',
      () async {
        await library.fileFor(video).writeAsBytes([1, 2, 3, 4, 5]);
        expect(await library.verify(video), isNull);
      },
    );

    test('a checksum that does not match is refused and deleted', () async {
      final withDigest = FirstAidVideoPack.parse(
        jsonEncode({
          'format': 1,
          'videos': [
            {
              'id': 'x',
              'guide': 'cpr-adult',
              'title': 'x',
              'file': 'x.mp4',
              'credit': '',
              'licence': '',
              'sha256': 'f' * 64,
            },
          ],
        }),
      ).videos.single;
      await library.fileFor(withDigest).writeAsBytes([1, 2, 3]);
      expect(await library.verify(withDigest), contains('checksum'));
      expect(await library.fileFor(withDigest).exists(), isFalse);
    });

    test('the right checksum passes', () async {
      // sha256 of the three bytes 01 02 03.
      const digest =
          '039058c6f2c0cb492c533b0a4d14ef77cc0f78abccced5287d84a1a2011cfb81';
      final withDigest = FirstAidVideoPack.parse(
        jsonEncode({
          'format': 1,
          'videos': [
            {
              'id': 'x',
              'guide': 'cpr-adult',
              'title': 'x',
              'file': 'x.mp4',
              'credit': '',
              'licence': '',
              'bytes': 3,
              'sha256': digest,
            },
          ],
        }),
      ).videos.single;
      await library.fileFor(withDigest).writeAsBytes([1, 2, 3]);
      expect(await library.verify(withDigest), isNull);
      expect(await library.fileFor(withDigest).exists(), isTrue);
    });

    test('a file that is not there says so instead of throwing', () async {
      expect(await library.verify(video), contains('not there'));
    });
  });

  group('what is installed', () {
    test('nothing, before anything has been installed', () async {
      expect(await library.installed(), isNull);
    });

    test(
      'a description that cannot be read reads as nothing installed',
      () async {
        // The screen has to open either way, and the remedy is the same.
        await library.folder.create(recursive: true);
        await library.manifestFile.writeAsString('not json at all');
        expect(await library.installed(), isNull);
      },
    );

    test('only the files that actually arrived count as present', () async {
      final pack = FirstAidVideoPack.parse(
        jsonEncode({
          'format': 1,
          'videos': [
            {
              'id': 'a',
              'guide': 'cpr-adult',
              'title': 'a',
              'file': 'a.mp4',
              'credit': '',
              'licence': '',
            },
            {
              'id': 'b',
              'guide': 'cpr-adult',
              'title': 'b',
              'file': 'b.mp4',
              'credit': '',
              'licence': '',
            },
          ],
        }),
      );
      await library.writeManifest(pack);
      await library.fileFor(pack.videos.first).writeAsBytes([0]);
      expect((await library.present(pack)).map((v) => v.id), ['a']);
    });

    test('deleting takes the files and the description together', () async {
      final pack = FirstAidVideoPack.parse(manifest());
      await library.writeManifest(pack);
      await library.fileFor(pack.videos.single).writeAsBytes([0, 0, 0]);
      expect(await library.bytesOnDisk(), greaterThan(0));
      await library.removeAll();
      expect(await library.folder.exists(), isFalse);
      expect(await library.installed(), isNull);
    });
  });

  group('a pack off a memory stick', () {
    Future<String> writeZip(Map<String, List<int>> entries) async {
      final archive = Archive();
      entries.forEach((name, bytes) {
        archive.add(ArchiveFile.bytes(name, bytes));
      });
      final path = '${temp.path}/pack.zip';
      await File(path).writeAsBytes(ZipEncoder().encodeBytes(archive));
      return path;
    }

    test('is unpacked and becomes the installed pack', () async {
      final path = await writeZip({
        firstAidPackFileName: utf8.encode(manifest(url: null, bytes: 3)),
        'cpr.mp4': [1, 2, 3],
      });
      expect(await library.importZip(path), isNull);

      final installed = await library.installed();
      expect(installed?.videos.single.id, 'cpr-1');
      expect(await library.fileFor(installed!.videos.single).exists(), isTrue);
    });

    test('a zip with no description in it is refused', () async {
      final path = await writeZip({
        'holiday.jpg': [1, 2, 3],
      });
      expect(await library.importZip(path), contains(firstAidPackFileName));
      expect(await library.installed(), isNull);
    });

    test('something that is not a zip is refused', () async {
      // It does not throw: the decoder looks for a central directory,
      // fails to find one and returns an empty archive. Without the
      // emptiness check this was answered with "that zip holds no
      // paket.json", which calls a holiday photo a zip.
      final path = '${temp.path}/not-a-zip.bin';
      await File(path).writeAsBytes(List.filled(64, 7));
      expect(await library.importZip(path), 'That file is not a pack.');
    });

    test('an empty zip is refused the same way', () async {
      final path = await writeZip({});
      expect(await library.importZip(path), 'That file is not a pack.');
    });

    test('an entry the description does not mention is not written', () async {
      // This is what keeps a crafted zip from putting a file into the
      // folder under a name nothing ever checked.
      final path = await writeZip({
        firstAidPackFileName: utf8.encode(manifest(url: null, bytes: 3)),
        'cpr.mp4': [1, 2, 3],
        'stowaway.sh': utf8.encode('rm -rf /'),
      });
      expect(await library.importZip(path), isNull);
      expect(
        await File('${library.folder.path}/stowaway.sh').exists(),
        isFalse,
      );
    });
  });
}
