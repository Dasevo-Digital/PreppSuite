import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The Mac package's Developer ID signing (#387): what
/// `tool/macos_developer_id.py` makes of a profile, and what stays out of
/// the repository.
///
/// The profiles here are bare plists with a made-up team; the real ones
/// are signed by Apple and live on the machine that builds.
void main() {
  final tool = File('../tool/macos_developer_id.py').absolute.path;
  final skip = Platform.isWindows ? 'needs python3 and a POSIX shell' : null;

  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('developer-id'));
  tearDown(() => dir.deleteSync(recursive: true));

  String profile({
    String appId = 'ABCDE12345.de.dasevo.preppsuite',
    List<String> groups = const ['ABCDE12345.*'],
  }) {
    final path = '${dir.path}/test.provisionprofile';
    final groupXml = groups.map((g) => '<string>$g</string>').join();
    File(path).writeAsStringSync('''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>Platform</key><array><string>OSX</string></array>
<key>ProvisionsAllDevices</key><true/>
<key>ExpirationDate</key><date>2040-01-01T00:00:00Z</date>
<key>Entitlements</key><dict>
<key>com.apple.application-identifier</key><string>$appId</string>
<key>com.apple.developer.team-identifier</key><string>ABCDE12345</string>
<key>keychain-access-groups</key><array>$groupXml</array>
</dict></dict></plist>''');
    return path;
  }

  test(
    'the keychain entitlements come from the profile, on top of the file',
    () async {
      final out = '${dir.path}/merged.plist';
      final result = await Process.run('python3', [
        tool,
        'entitlements',
        profile(),
        'macos/Runner/Release.entitlements',
        out,
      ]);
      expect(result.exitCode, 0, reason: '${result.stderr}');
      final merged = File(out).readAsStringSync();
      expect(merged, contains('ABCDE12345.de.dasevo.preppsuite'));
      expect(merged, contains('keychain-access-groups'));
      expect(merged, contains('com.apple.developer.team-identifier'));
      // What the repository's file says stays.
      expect(merged, contains('com.apple.security.app-sandbox'));
      expect(merged, contains('com.apple.security.network.client'));
      // The app's own group, not the profile's wildcard.
      expect(merged, isNot(contains('ABCDE12345.*')));
    },
    skip: skip,
  );

  test('a profile that allows no keychain group is refused', () async {
    final result = await Process.run('python3', [
      tool,
      'entitlements',
      profile(groups: const ['ABCDE12345.other.app']),
      'macos/Runner/Release.entitlements',
      '${dir.path}/merged.plist',
    ]);
    expect(result.exitCode, 1);
    expect('${result.stderr}', contains('Schlüsselbundgruppe'));
  }, skip: skip);

  test('only a valid Developer ID profile for the identifier fits', () async {
    // profile_fits and the signature conversion, called directly.
    final result = await Process.run('python3', [
      '-c',
      '''
import datetime as dt, sys
sys.path.insert(0, "../tool")
import macos_developer_id as m
now = dt.datetime(2026, 11, 13, tzinfo=dt.timezone.utc)
good = {"Platform": ["OSX"], "ProvisionsAllDevices": True,
        "ExpirationDate": dt.datetime(2040, 1, 1),
        "Entitlements": {"com.apple.application-identifier": "ABCDE12345.de.dasevo.preppsuite"}}
print(m.profile_fits(good, "de.dasevo.preppsuite", None, now))
print(m.profile_fits(good, "de.dasevo.preppsuite.test", None, now))
print(m.profile_fits(dict(good, Platform=["iOS"]), "de.dasevo.preppsuite", None, now))
print(m.profile_fits(dict(good, ProvisionsAllDevices=False), "de.dasevo.preppsuite", None, now))
print(m.profile_fits(dict(good, ExpirationDate=dt.datetime(2026, 1, 1)), "de.dasevo.preppsuite", None, now))
print(m.profile_fits(good, "de.dasevo.preppsuite", "00" * 20, now))
der = bytes.fromhex("3044" "0220" + "01" * 32 + "0220" + "02" * 32)
assert m.der_signature_to_raw(der) == b"\\x01" * 32 + b"\\x02" * 32
padded = bytes.fromhex("3045" "0221" "00" + "ff" * 32 + "0220" + "02" * 32)
assert m.der_signature_to_raw(padded) == b"\\xff" * 32 + b"\\x02" * 32
print("ok")
''',
    ]);
    expect(result.exitCode, 0, reason: '${result.stderr}');
    expect('${result.stdout}'.trim().split('\n'), [
      'True',
      'False',
      'False',
      'False',
      'False',
      'False',
      'ok',
    ]);
  }, skip: skip);

  test('the repository names no team and asks for no keychain group', () {
    // Added at signing from the profile: with them, an ad hoc build would
    // not start, and the team id is not the repository's business.
    for (final name in ['Release', 'DebugProfile']) {
      final text = File(
        'macos/Runner/$name.entitlements',
      ).readAsStringSync();
      expect(text, isNot(contains('keychain-access-groups')), reason: name);
      expect(text, isNot(contains('application-identifier')), reason: name);
      expect(text, isNot(contains('team-identifier')), reason: name);
    }
  });

  test('no Mac script pipes a long output into grep -q', () {
    // Under pipefail, `codesign -dv … | grep -q` ends in SIGPIPE (141)
    // when grep stops at its match while codesign is still writing. That
    // happened on 13.11.2026: a good Developer ID signature read as none,
    // and macos_install.sh would have re-signed a notarized release ad hoc.
    final pattern = RegExp(
      r'\b(codesign|nm|security|spctl)\b[^|#]*\|\s*grep\s+-q',
    );
    for (final name in [
      'macos_sign.sh',
      'macos_notarize.sh',
      'macos_install.sh',
      'release.sh',
    ]) {
      final lines = File('../tool/$name').readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i].trimLeft();
        if (line.startsWith('#')) continue;
        expect(
          pattern.hasMatch(line),
          isFalse,
          reason: '$name:${i + 1}: $line',
        );
      }
    }
  });

  test('an ad hoc signature takes no profile', () async {
    final app = Directory('${dir.path}/PreppSuite.app/Contents/MacOS')
      ..createSync(recursive: true);
    final result = await Process.run('bash', [
      '../tool/macos_sign.sh',
      app.parent.parent.path,
      '--allow-ad-hoc',
      '--profile',
      profile(),
    ]);
    expect(result.exitCode, 2, reason: '${result.stdout}');
  }, skip: skip);
}
