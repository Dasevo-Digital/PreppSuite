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

  group('a run through the pictures', () {
    test('looks each one up with one query, not one per picture', () {
      // `findFile` asks every entry of the folder for its name, one binder
      // call each: for every picture read, written or removed, a call per
      // picture already there.
      final code = _withoutComments(source);
      expect(code, isNot(contains('.findFile(')));
      expect(code, isNot(contains('.listFiles(')));
      final children = _body(source, 'private fun children(');
      expect(
        RegExp(r'contentResolver\.query\(').allMatches(children),
        hasLength(1),
      );
      expect(children, contains('COLUMN_DISPLAY_NAME'));
      expect(children, contains('COLUMN_DOCUMENT_ID'));
      for (final function in [
        'private fun read(',
        'private fun write(',
        'private fun delete(',
        'private fun list(',
        'private fun resolveDirectory(',
      ]) {
        expect(
          _body(source, function),
          contains('children('),
          reason: function,
        );
      }
    });

    test('does not hold up the tiles of the map', () {
      expect(source, contains('private val rangeReads ='));
      final read = _body(source, 'private fun readRange(');
      expect(read, contains('rangeReads.execute {'));
      expect(read, isNot(contains('fileReads')));
      // Closed after the reads queued for it, on the same thread.
      expect(_body(source, 'private fun closeFile('), contains('rangeReads'));
      expect(_body(source, 'override fun onDestroy('), contains('rangeReads'));
    });
  });
}

/// [source] without its `//` and `/* */` comments. MainActivity has no
/// string with two slashes in it, which this would cut.
String _withoutComments(String source) => source
    .replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '')
    .replaceAll(RegExp(r'//[^\n]*'), '');

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
