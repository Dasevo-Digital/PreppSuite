import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/core/former_identity.dart';

/// Carrying the household over from `de.status403.preppsuite`.
///
/// The identifier decides where the data lives on every desktop. Getting
/// this wrong leaves somebody with an empty app and their household on the
/// disk under a name they will never look for — or, worse, a half-copied
/// one that looks like theirs.
void main() {
  group('where the data was', () {
    String? former(String path, String platform) =>
        formerSupportDirectory(path, platform: platform);

    test('macOS: the container and the folder in it', () {
      expect(
        former(
          '/Users/x/Library/Containers/de.dasevo.preppsuite/Data/Library/'
              'Application Support/de.dasevo.preppsuite',
          'macos',
        ),
        '/Users/x/Library/Containers/de.status403.preppsuite/Data/Library/'
        'Application Support/de.status403.preppsuite',
      );
    });

    test('macOS: the test copy takes over the former test copy', () {
      expect(
        former(
          '/Users/x/Library/Containers/de.dasevo.preppsuite.test/Data/'
              'Library/Application Support/de.dasevo.preppsuite.test',
          'macos',
        ),
        '/Users/x/Library/Containers/de.status403.preppsuite.test/Data/'
        'Library/Application Support/de.status403.preppsuite.test',
      );
    });

    test('Linux', () {
      expect(
        former('/home/x/.local/share/de.dasevo.preppsuite', 'linux'),
        '/home/x/.local/share/de.status403.preppsuite',
      );
    });

    test('Windows: CompanyName and ProductName, whatever their case', () {
      expect(
        former(r'C:\Users\x\AppData\Roaming\De.Dasevo\PreppSuite', 'windows'),
        r'C:\Users\x\AppData\Roaming\PreppSuite Contributors\PreppSuite',
      );
    });

    test('anything else is left alone', () {
      expect(former('/home/x/.local/share/other', 'linux'), isNull);
      expect(
        former(r'C:\Users\x\AppData\Roaming\de.dasevo\famio', 'windows'),
        isNull,
      );
      expect(
        former('/data/user/0/de.dasevo.preppsuite/files', 'android'),
        isNull,
      );
    });
  });

  group('taking it over', () {
    late Directory root;
    setUp(() => root = Directory.systemTemp.createTempSync('preppsuite-id'));
    tearDown(() => root.deleteSync(recursive: true));

    Directory dir(String name) => Directory('${root.path}/$name');
    Directory household(String name) {
      final d = dir(name)..createSync(recursive: true);
      File('${d.path}/preppsuite.sqlite').writeAsStringSync('haushalt');
      Directory('${d.path}/inventory_photos').createSync();
      File('${d.path}/inventory_photos/a.jpg').writeAsStringSync('bild');
      return d;
    }

    test('the household is renamed into place, not copied', () async {
      final former = household('alt/de.status403.preppsuite');
      final current = dir('neu/de.dasevo.preppsuite');

      await adoptFormerDirectory(current: current, former: former);

      expect(
        File('${current.path}/inventory_photos/a.jpg').readAsStringSync(),
        'bild',
      );
      expect(former.existsSync(), isFalse);
    });

    test('the empty folder path_provider made is no obstacle', () async {
      final former = household('alt/x');
      final current = dir('neu/y')..createSync(recursive: true);
      File('${current.path}/.DS_Store').writeAsStringSync('');

      await adoptFormerDirectory(current: current, former: former);
      expect(File('${current.path}/preppsuite.sqlite').existsSync(), isTrue);
    });

    test('a used installation is never touched', () async {
      final former = household('alt/x');
      final current = household('neu/y');
      File('${current.path}/preppsuite.sqlite').writeAsStringSync('neuer');

      await adoptFormerDirectory(current: current, former: former);
      expect(
        File('${current.path}/preppsuite.sqlite').readAsStringSync(),
        'neuer',
      );
      expect(File('${former.path}/preppsuite.sqlite').existsSync(), isTrue);
    });

    test('nothing to take over leaves everything as it was', () async {
      final current = dir('neu/y');
      await adoptFormerDirectory(current: current, former: dir('gibtsnicht'));
      expect(current.existsSync(), isFalse);
    });
  });

  group('the table matches the platform files', () {
    // An identifier changed in one place and not in the table would find
    // nothing on the first start. These read it where it is really set.
    test('macOS: the bundle id has a former one, and the entitlements let '
        'the sandbox reach both former containers', () {
      final xcconfig = File(
        'macos/Runner/Configs/AppInfo.xcconfig',
      ).readAsStringSync();
      final id = RegExp(
        r'^PRODUCT_BUNDLE_IDENTIFIER = (\S+)',
        multiLine: true,
      ).firstMatch(xcconfig)!.group(1)!;
      for (final variant in [id, '$id.test']) {
        final former = formerSupportDirectory(
          '/Users/x/Library/Containers/$variant/Data/Library/'
          'Application Support/$variant',
          platform: 'macos',
        );
        expect(former, isNotNull, reason: variant);
        final container = RegExp(
          r'Containers/([^/]+)/',
        ).firstMatch(former!)!.group(1);
        for (final file in ['Release', 'DebugProfile']) {
          expect(
            File('macos/Runner/$file.entitlements').readAsStringSync(),
            contains('<string>/Library/Containers/$container/</string>'),
            reason: '$file.entitlements, $variant',
          );
        }
      }
    });

    test('Linux: APPLICATION_ID', () {
      final cmake = File('linux/CMakeLists.txt').readAsStringSync();
      final id = RegExp(
        r'set\(APPLICATION_ID "([^"]+)"\)',
      ).firstMatch(cmake)!.group(1)!;
      expect(
        formerSupportDirectory('/home/x/.local/share/$id', platform: 'linux'),
        isNotNull,
      );
    });

    test('Windows: CompanyName and ProductName', () {
      final rc = File('windows/runner/Runner.rc').readAsStringSync();
      String value(String name) =>
          RegExp('VALUE "$name", "([^"]+)"').firstMatch(rc)!.group(1)!;
      expect(
        formerSupportDirectory(
          'C:\\Users\\x\\AppData\\Roaming\\${value('CompanyName')}'
          '\\${value('ProductName')}',
          platform: 'windows',
        ),
        isNotNull,
      );
    });
  });
}
