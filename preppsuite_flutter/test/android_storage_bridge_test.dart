import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The Android storage bridge, read as source (#410).
///
/// What it does on a device is exercised by
/// `integration_test/native_storage_test.dart`. What these guard does not
/// fail there: a call on the main thread works until the provider is slow,
/// and a lookup per file works until the folder is full.
void main() {
  final source = File(
    'android/app/src/main/kotlin/de/dasevo/preppsuite/MainActivity.kt',
  ).readAsStringSync();
  late final String handle;
  setUpAll(() => handle = _body(source, 'private fun handle('));

  group('the main thread asks no provider', () {
    test('opening a file for ranged reads', () {
      // A provider in the cloud may fetch the whole file first: a backup
      // in Nextcloud held the main thread for as long as that took.
      expect(handle, isNot(contains('result.success(openFile(')));
      final open = _body(source, 'private fun openFile(');
      expect(open, contains('fileReads.execute {'));
      expect(
        open.indexOf('openFileDescriptor'),
        greaterThan(open.indexOf('fileReads.execute {')),
      );
      expect(open, contains('runOnUiThread {'));
    });

    test('checking that the shared folder is still writable', () {
      expect(handle, isNot(contains('result.success(ensureWritable(')));
      final branch = _branch(handle, '"ensureWritable" ->');
      expect(branch, contains('fileReads.execute {'));
      expect(branch, contains('runOnUiThread {'));
      expect(branch, contains('onFailure'));
    });
  });
}

/// The block that starts at the first `{` after [signature].
String _body(String source, String signature) {
  final start = source.indexOf(signature);
  expect(start, isNonNegative, reason: '$signature is not in the source');
  final open = source.indexOf('{', start);
  var depth = 0;
  for (var i = open; i < source.length; i++) {
    if (source[i] == '{') depth++;
    if (source[i] == '}' && --depth == 0) return source.substring(open, i + 1);
  }
  fail('$signature has no end');
}

/// The `when` branch of `handle` that starts with [label].
String _branch(String handle, String label) => _body(handle, label);
