import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/core/app_database_directory.dart';

/// Moving the databases out of the documents folder.
///
/// Without the sandbox, "documents" on macOS is the user's own
/// `~/Documents` — the same path for every build whatever its bundle
/// identifier, which is how two installs meant to be independent ended up
/// sharing one household. The move is one-way and runs before anything
/// opens the files, so getting it wrong loses data rather than annoying
/// somebody.
void main() {
  late Directory legacy;
  late Directory target;

  setUp(() {
    legacy = Directory.systemTemp.createTempSync('preppsuite-legacy');
    target = Directory.systemTemp.createTempSync('preppsuite-target');
  });

  tearDown(() {
    legacy.deleteSync(recursive: true);
    target.deleteSync(recursive: true);
  });

  File write(Directory directory, String name, String content) =>
      File('${directory.path}/$name')..writeAsStringSync(content);

  test('the household database and its journal files come along', () async {
    write(legacy, 'preppsuite.sqlite', 'haushalt');
    write(legacy, 'preppsuite.sqlite-wal', 'journal');
    write(legacy, 'preppsuite.sqlite-shm', 'shared');

    await adoptLegacyDatabases(legacy: legacy, target: target);

    expect(
      File('${target.path}/preppsuite.sqlite').readAsStringSync(),
      'haushalt',
    );
    expect(File('${target.path}/preppsuite.sqlite-wal').existsSync(), isTrue);
    expect(File('${target.path}/preppsuite.sqlite-shm').existsSync(), isTrue);

    // Moved, not copied: two files would be two databases, and the next
    // version would not know which one was current.
    expect(File('${legacy.path}/preppsuite.sqlite').existsSync(), isFalse);
  });

  test('every archive index comes along too', () async {
    write(legacy, 'preppsuite_knowledge.sqlite', 'alt');
    write(legacy, 'preppsuite_knowledge_a1b2c3.sqlite', 'neu');

    await adoptLegacyDatabases(legacy: legacy, target: target);

    expect(
      File('${target.path}/preppsuite_knowledge.sqlite').readAsStringSync(),
      'alt',
    );
    expect(
      File(
        '${target.path}/preppsuite_knowledge_a1b2c3.sqlite',
      ).readAsStringSync(),
      'neu',
    );
  });

  test('nothing else in the documents folder is touched', () async {
    write(legacy, 'Steuererklaerung.pdf', 'privat');
    write(legacy, 'notizen.sqlite', 'fremde Datenbank');
    write(legacy, 'preppsuite-map-z14.pmtiles', 'karte');

    await adoptLegacyDatabases(legacy: legacy, target: target);

    expect(File('${legacy.path}/Steuererklaerung.pdf').existsSync(), isTrue);
    expect(File('${legacy.path}/notizen.sqlite').existsSync(), isTrue);
    expect(
      File('${legacy.path}/preppsuite-map-z14.pmtiles').existsSync(),
      isTrue,
      reason: 'a downloaded map is not a database of ours',
    );
    expect(target.listSync(), isEmpty);
  });

  test('a database already in place is never overwritten', () async {
    write(legacy, 'preppsuite.sqlite', 'alt und verlassen');
    write(target, 'preppsuite.sqlite', 'in Benutzung');

    await adoptLegacyDatabases(legacy: legacy, target: target);

    expect(
      File('${target.path}/preppsuite.sqlite').readAsStringSync(),
      'in Benutzung',
    );
    // The old one stays too, rather than being deleted on the strength of
    // an assumption about which of the two mattered.
    expect(File('${legacy.path}/preppsuite.sqlite').existsSync(), isTrue);
  });

  test('running it twice is harmless', () async {
    write(legacy, 'preppsuite.sqlite', 'haushalt');

    await adoptLegacyDatabases(legacy: legacy, target: target);
    await adoptLegacyDatabases(legacy: legacy, target: target);

    expect(
      File('${target.path}/preppsuite.sqlite').readAsStringSync(),
      'haushalt',
    );
  });

  test('a documents folder that cannot be read is not fatal', () async {
    // On macOS without the sandbox, reading the user's own documents
    // folder needs their permission. Declined, listing it throws — and
    // this runs while the database directory is being resolved, so an
    // error escaping here would leave the app with no database at all.
    final gone = Directory('${legacy.path}/weg');

    await adoptLegacyDatabases(legacy: gone, target: target);

    expect(target.listSync(), isEmpty);
  });

  test('the same directory twice does nothing at all', () async {
    write(legacy, 'preppsuite.sqlite', 'haushalt');

    await adoptLegacyDatabases(legacy: legacy, target: legacy);

    expect(File('${legacy.path}/preppsuite.sqlite').existsSync(), isTrue);
  });
}
