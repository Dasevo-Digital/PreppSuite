import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The Apple folder bridges, read as source: neither runs under
/// `flutter test`, and what these check shows on a device only as a
/// frozen app.
void main() {
  for (final platform in ['ios', 'macos']) {
    final source = File('$platform/Runner/StorageBridge.swift')
        .readAsStringSync();

    String dispatch(String method) {
      final start = source.indexOf('case "$method":');
      expect(start, greaterThan(0), reason: '$platform: case "$method"');
      final end = source.indexOf(RegExp(r'\n    (case |default:)'), start + 1);
      return source.substring(start, end);
    }

    test('$platform: the shared folder is not written on the main thread '
        '(#410)', () {
      for (final method in [
        'ensureWritable',
        'list',
        'read',
        'write',
        'delete',
      ]) {
        expect(
          dispatch(method),
          contains('onFileQueue(result)'),
          reason: '$platform: "$method" runs on the serial file queue',
        );
      }
      expect(
        source,
        contains(
          'fileReads.async {\n      let value = work()\n'
          '      DispatchQueue.main.async { result(value) }',
        ),
      );
    });
  }
}
