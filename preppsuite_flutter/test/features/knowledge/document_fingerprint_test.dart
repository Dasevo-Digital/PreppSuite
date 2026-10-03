import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/knowledge/application/document_fingerprint.dart';

/// A document replaced behind the app's back has to be noticed, or the
/// search goes on answering from the old file (#77).
void main() {
  late Directory dir;

  setUp(() async => dir = await Directory.systemTemp.createTemp('fp'));
  tearDown(() async => dir.delete(recursive: true));

  Future<File> write(String name, List<int> bytes) async {
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  /// Large enough that head and tail are different windows.
  Uint8List big([int fill = 1]) =>
      Uint8List(300 * 1024)..fillRange(0, 300 * 1024, fill);

  test('the same file gives the same fingerprint', () async {
    final file = await write('a.pdf', big());

    expect(
      await documentFingerprint(file.path),
      await documentFingerprint(file.path),
    );
  });

  test('a file replaced by one of the same length is noticed', () async {
    final file = await write('a.pdf', big());
    final before = await documentFingerprint(file.path);
    final modified = await file.lastModified();

    // Same size, same modification time, different last bytes: only the
    // hash can tell, and it has to.
    final changed = big()..[300 * 1024 - 1] = 9;
    await file.writeAsBytes(changed, flush: true);
    await file.setLastModified(modified);

    expect(
      documentChanged(before, await documentFingerprint(file.path)),
      isTrue,
    );
  });

  test('a newer edition saved over it is noticed', () async {
    final file = await write('a.pdf', big());
    final before = await documentFingerprint(file.path);

    await file.writeAsBytes([...big(), 1, 2, 3], flush: true);

    expect(
      documentChanged(before, await documentFingerprint(file.path)),
      isTrue,
    );
  });

  test('a small file works too', () async {
    final file = await write('a.md', [1, 2, 3]);

    expect(await documentFingerprint(file.path), startsWith('f1:3:'));
  });

  test(
    'a file that is gone has no fingerprint, and is not called changed',
    () async {
      final missing = '${dir.path}/weg.pdf';

      expect(await documentFingerprint(missing), isNull);
      expect(documentChanged('f1:1:2:abc', null), isFalse);
    },
  );

  test('a document indexed before fingerprints is not called changed', () {
    expect(documentChanged(null, 'f1:1:2:abc'), isFalse);
  });
}
