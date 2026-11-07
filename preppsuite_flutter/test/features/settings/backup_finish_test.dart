import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:preppsuite_flutter/features/settings/presentation/backup_flow.dart';

/// A backup takes its name only when it is complete (#314).
void main() {
  late Directory folder;

  setUp(() => folder = Directory.systemTemp.createTempSync('backup-finish'));
  tearDown(() => folder.deleteSync(recursive: true));

  String named(String name) => p.join(folder.path, name);

  File partial(String content) => File(
    named('preppsuite-backup-2026-11-07.preppsuite$partialBackupSuffix'),
  )..writeAsStringSync(content);

  test('a complete backup loses its provisional name', () async {
    final finished = await finishBackupFile(partial('neu'));

    expect(finished.path, named('preppsuite-backup-2026-11-07.preppsuite'));
    expect(finished.readAsStringSync(), 'neu');
    expect(folder.listSync(), hasLength(1));
  });

  test('an earlier backup of the day stays where it is', () async {
    final earlier = File(named('preppsuite-backup-2026-11-07.preppsuite'))
      ..writeAsStringSync('alt');

    final finished = await finishBackupFile(partial('neu'));

    expect(earlier.readAsStringSync(), 'alt');
    expect(finished.path, named('preppsuite-backup-2026-11-07-2.preppsuite'));
    expect(finished.readAsStringSync(), 'neu');
  });

  test('and so does a third one', () async {
    File(
      named('preppsuite-backup-2026-11-07.preppsuite'),
    ).writeAsStringSync('eins');
    File(
      named('preppsuite-backup-2026-11-07-2.preppsuite'),
    ).writeAsStringSync('zwei');

    final finished = await finishBackupFile(partial('drei'));

    expect(finished.path, named('preppsuite-backup-2026-11-07-3.preppsuite'));
  });
}
