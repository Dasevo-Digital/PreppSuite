import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Where the time-sensitive entitlement (#101) belongs, and where it must
/// not go. Nothing at run time says it is missing: the warnings simply
/// stay behind a Focus. And on the Mac, signed ad hoc without a profile,
/// it would keep the app from starting at all.
void main() {
  const timeSensitive = 'com.apple.developer.usernotifications.time-sensitive';

  test('the iPhone app may break through a Focus', () {
    final ios = File('ios/Runner/Runner.entitlements').readAsStringSync();
    expect(ios, contains('<key>$timeSensitive</key>'));
  });

  test('the Mac packages do not ask for it', () {
    for (final name in ['DebugProfile', 'Release']) {
      final mac = File(
        'macos/Runner/$name.entitlements',
      ).readAsStringSync();
      expect(mac, isNot(contains(timeSensitive)), reason: name);
    }
  });
}
