import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Versions held back on purpose, checked against what the lock file
/// actually resolved -- a dependency update must not bring them back
/// unnoticed.
void main() {
  String locked(String package) {
    final lock = File('../pubspec.lock').readAsStringSync();
    final match = RegExp(
      '\\n  $package:\\n(?:    [^\\n]*\\n|      [^\\n]*\\n)*?    version: "([^"]+)"',
    ).firstMatch(lock);
    return match!.group(1)!;
  }

  test('shared_preferences_android stays below 2.5 (#210)', () {
    // 2.5 registers its native side in one process-wide table under one
    // name, and every engine that ends removes that entry -- also the
    // UI's. The background warning poll is a second engine; ending while
    // the app started, it left the household unloadable until the process
    // restarted. 2.5.3 still does it.
    final version = locked('shared_preferences_android');
    final [major, minor, ...] = [
      for (final part in version.split('.').take(2)) int.parse(part),
    ];
    expect(
      major < 2 || (major == 2 && minor < 5),
      isTrue,
      reason: 'shared_preferences_android $version is locked',
    );
  });
}
