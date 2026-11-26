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

    String function(String name) {
      final start = source.indexOf('private func $name(');
      expect(start, greaterThan(0), reason: '$platform: func $name');
      return source.substring(start, source.indexOf('\n  }\n', start));
    }

    test('$platform: a file iCloud has not downloaded is listed under its '
        'own name, read once it arrives, and never missing (#398)', () {
      // `.<name>.icloud` was listed as such, and Dart, looking for
      // `.json`, never read the other devices' files.
      expect(
        function('list'),
        contains(
          'Self.cloudPlaceholderTarget(entry.lastPathComponent) ?? '
          'entry.lastPathComponent',
        ),
      );
      expect(
        source,
        contains(
          'guard name.hasPrefix("."), name.hasSuffix(suffix), '
          'name.count > suffix.count + 1 else {',
        ),
      );

      final read = function('read');
      expect(read, contains('startDownloadingUbiquitousItem(at: file)'));
      // Waits for the download, but not for ever: the queue it holds
      // serves every other folder call and the map's tiles. Only for an
      // iCloud placeholder, whose download goes on without the read;
      // another provider fetches for the read itself.
      expect(read, contains('coordinator.cancel()'));
      expect(
        read,
        contains(
          'if pending {\n'
          '        DispatchQueue.global(qos: .utility).asyncAfter(',
        ),
      );
      expect(read, contains('coordinator.coordinate(readingItemAt: file'));
      // nil is "never in use", and the household file would be founded
      // anew over the one still in the cloud (#312).
      expect(read, contains('files.fileExists(atPath: placeholder.path)'));
    });
  }
}
