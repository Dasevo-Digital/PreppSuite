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

  test(
    'the look finds SVE and SME on their own, and passes plain code',
    () async {
      final dir = Directory.systemTemp.createTempSync('baseline');
      addTearDown(() => dir.deleteSync(recursive: true));
      Future<ProcessResult> check(String name, List<String> lines) async {
        final source = File('${dir.path}/$name.s')
          ..writeAsStringSync(
            '.text\n.globl _f\n_f:\n${lines.map((l) => '  $l\n').join()}'
            '  ret\n',
          );
        final library = '${dir.path}/lib$name.dylib';
        final built = await Process.run('xcrun', [
          'clang',
          '-dynamiclib',
          '-arch',
          'arm64',
          '-march=armv9-a+sve2+sme+i8mm+bf16',
          source.path,
          '-o',
          library,
        ]);
        expect(built.exitCode, 0, reason: '${built.stderr}');
        return Process.run('bash', [
          'native/translate/check_arm64_baseline.sh',
          library,
        ]);
      }

      final plain = await check('plain', [
        'prfm pldl1keep, [x0]',
        'sdot v0.4s, v1.16b, v2.16b',
      ]);
      expect(plain.exitCode, 0, reason: '${plain.stderr}');
      expect('${plain.stdout}', contains('3 Befehle'));

      // Each alone, as a compiler might leave one in a loop it
      // vectorised; none of them names a register the old check knew.
      for (final instruction in [
        'ptrue p0.s',
        'ldr z2, [x0]',
        'cntw x3',
        'zero {za}',
        'usdot v0.4s, v1.16b, v2.16b',
      ]) {
        final result = await check('one', [instruction]);
        expect(result.exitCode, 1, reason: instruction);
      }
    },
    skip: Platform.isMacOS ? null : 'needs Apple clang',
  );
}
