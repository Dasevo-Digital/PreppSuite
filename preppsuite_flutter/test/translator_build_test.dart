import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The Mac translator is built for every Apple silicon Mac, not for the
/// one that builds it (#375).
///
/// What the library actually holds is checked by
/// `native/translate/check_arm64_baseline.sh` at the end of every build;
/// this only keeps the build script from going back to "native".
void main() {
  final script = File('native/translate/build_macos.sh').readAsStringSync();

  test('arm64 is built for a fixed baseline', () {
    expect(script, contains('arm64) cpu=armv8.4-a'));
    expect(script, contains('-DBUILD_ARCH="\$cpu"'));
    expect(script, isNot(contains('BUILD_ARCH=native')));
  });

  test('a changed baseline reaches a build directory that exists', () {
    // Ninja never reconfigures on its own; without the stamp the new
    // baseline would only have reached a clean checkout.
    expect(script, contains(r'"$out/.configured"'));
    expect(script, contains(r'${configure[*]}'));
  });

  test('every build ends with the look at what is inside', () {
    expect(script, contains('check_arm64_baseline.sh'));
    final check = File('native/translate/check_arm64_baseline.sh');
    expect(check.existsSync(), isTrue);
    for (final mnemonic in ['smmla', 'usdot', 'bfdot', 'bfmmla', 'smstart']) {
      expect(check.readAsStringSync(), contains(mnemonic));
    }
    if (!Platform.isWindows) {
      final mode = check.statSync().mode;
      expect(mode & 0x40, isNonZero, reason: 'executable by its owner');
    }
  });
}
