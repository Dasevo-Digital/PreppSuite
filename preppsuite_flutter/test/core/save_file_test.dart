import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/core/save_file.dart';

/// Saving through the file picker, per platform (#110).
void main() {
  final bytes = Uint8List.fromList([1, 2, 3]);

  Future<String?> Function({
    required String dialogTitle,
    required String fileName,
    required List<String> allowedExtensions,
    required Uint8List bytes,
  })
  answering(String? path) =>
      ({
        required dialogTitle,
        required fileName,
        required allowedExtensions,
        required bytes,
      }) async => path;

  test('on a phone a path outside the sandbox is not touched', () async {
    // What iOS hands back after saving to "On My iPhone": a path the app
    // may not open. Reading it is what threw "could not be reached" for a
    // backup that had in fact been saved.
    final saved = await saveFileWithPicker(
      dialogTitle: 'Sichern',
      fileName: 'preppsuite-backup.json',
      extension: 'json',
      bytes: bytes,
      pick: answering('/private/var/mobile/Containers/Shared/elsewhere.json'),
      pickerWrites: true,
    );

    expect(saved, isTrue);
  });

  test('on a desktop the app writes the file itself', () async {
    final dir = await Directory.systemTemp.createTemp('save');
    addTearDown(() => dir.delete(recursive: true));
    final path = '${dir.path}/vorraete.csv';

    final saved = await saveFileWithPicker(
      dialogTitle: 'Sichern',
      fileName: 'vorraete.csv',
      extension: 'csv',
      bytes: bytes,
      pick: answering(path),
      pickerWrites: false,
    );

    expect(saved, isTrue);
    expect(File(path).readAsBytesSync(), bytes);
  });

  test('a cancelled dialog saves nothing and is not an error', () async {
    final saved = await saveFileWithPicker(
      dialogTitle: 'Sichern',
      fileName: 'x.ics',
      extension: 'ics',
      bytes: bytes,
      pick: answering(null),
      pickerWrites: false,
    );

    expect(saved, isFalse);
  });
}
