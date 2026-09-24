import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('macOS builds declare Keychain Sharing for secure local storage', () {
    for (final name in ['DebugProfile.entitlements', 'Release.entitlements']) {
      final file = File('macos/Runner/$name');
      expect(file.existsSync(), isTrue, reason: '$name is part of the runner');

      final entitlements = file.readAsStringSync();
      expect(
        entitlements,
        contains('<key>keychain-access-groups</key>'),
        reason:
            '$name must let flutter_secure_storage write the local data key',
      );
    }
  });
}
