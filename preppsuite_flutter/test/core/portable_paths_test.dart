import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/core/portable_data.dart';
import 'package:preppsuite_flutter/core/portable_paths.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory workspace;
  late SharedPreferencesStorePlatform platformStore;

  setUp(() {
    workspace = Directory.systemTemp.createTempSync('paths');
    platformStore = SharedPreferencesStorePlatform.instance;
  });
  tearDown(() {
    SharedPreferencesStorePlatform.instance = platformStore;
    resetPortableData();
    workspace.deleteSync(recursive: true);
  });

  /// Turns this process into a carried copy whose data folder is [where].
  Future<void> carriedIn(Directory where) => startPortableData(
    environment: {portableEnvironmentVariable: where.path},
  );

  String join(List<String> parts) => parts.join(Platform.pathSeparator);

  group('an installed copy', () {
    test('writes down exactly what it was given', () {
      const path = '/home/testuser/Karten/niedersachsen.pmtiles';
      expect(storeLocation(path), path);
      expect(readLocation(path), path);
    });
  });

  group('a carried copy', () {
    test('writes a file inside the data folder down relative to it', () async {
      await carriedIn(workspace);

      final inside = join([workspace.path, 'Archive', 'wikipedia.zim']);
      expect(storeLocation(inside), 'daten:Archive/wikipedia.zim');
    });

    test('and reads it back as a path on this machine', () async {
      await carriedIn(workspace);

      expect(
        readLocation('daten:Archive/wikipedia.zim'),
        join([workspace.path, 'Archive', 'wikipedia.zim']),
      );
    });

    test(
      'so the same archive is found after the disk changes letter',
      () async {
        // The whole reason any of this exists. Written on one machine,
        // read on another where the stick came up somewhere else.
        final monday = Directory('${workspace.path}/E')..createSync();
        final tuesday = Directory('${workspace.path}/F')..createSync();

        await carriedIn(monday);
        final written = storeLocation(
          join([monday.path, 'Archive', 'wikipedia.zim']),
        );

        resetPortableData();
        await carriedIn(tuesday);

        expect(
          readLocation(written),
          join([tuesday.path, 'Archive', 'wikipedia.zim']),
        );
      },
    );

    test('leaves a file outside the data folder absolute', () async {
      await carriedIn(workspace);

      // An archive on the machine's own disk is exactly as findable as
      // it ever was, and writing it down relative to a stick would be
      // wrong.
      const elsewhere = '/home/testuser/Karten/niedersachsen.pmtiles';
      expect(storeLocation(elsewhere), elsewhere);
    });

    test('reads a path written before any of this existed unchanged', () async {
      await carriedIn(workspace);

      const old = '/home/testuser/wikipedia.zim';
      expect(readLocation(old), old);
    });

    test('does not mistake a neighbour for something inside', () async {
      await carriedIn(workspace);

      // `…/daten` and `…/daten-alt` share a prefix and are two folders.
      final sibling = '${workspace.path}-alt/wikipedia.zim';
      expect(storeLocation(sibling), sibling);
    });

    test(
      'writes separators that the other operating system can read',
      () async {
        await carriedIn(workspace);

        final stored = storeLocation(
          join([workspace.path, 'Archive', 'de', 'wikipedia.zim']),
        );
        // Forward slashes whatever wrote them: one disk, several machines.
        expect(stored, 'daten:Archive/de/wikipedia.zim');
        expect(stored, isNot(contains(r'\')));
      },
    );
  });

  test('a marked path read by an installed copy resolves to nothing real', () {
    // The stick was set up portable and is now being read by an
    // installation. There is no data folder to resolve against, and the
    // screen has to say "not found" rather than open something else.
    expect(readLocation('daten:Archive/wikipedia.zim'), isNot(startsWith('/')));
  });
}
