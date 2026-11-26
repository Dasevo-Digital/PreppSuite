import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// What the system says when the app asks for a permission (#411).
///
/// The texts in `Info.plist` are German. Without an `InfoPlist.strings` for
/// a language, a device in that language shows them in German, and nothing
/// shows that before somebody holds such a device. A purpose that names
/// less than the app does with a permission is a reason for App Review to
/// refuse it.
void main() {
  const languages = ['de', 'en', 'es'];

  Map<String, String> strings(String path) => {
    for (final match in RegExp(
      r'^"(\w+)" = "(.+)";$',
      multiLine: true,
    ).allMatches(File(path).readAsStringSync()))
      match.group(1)!: match.group(2)!,
  };

  for (final (platform, project) in [
    ('ios', 'ios/Runner.xcodeproj/project.pbxproj'),
    ('macos', 'macos/Runner.xcodeproj/project.pbxproj'),
  ]) {
    final plist = File('$platform/Runner/Info.plist').readAsStringSync();
    final keys = [
      for (final match in RegExp(
        r'<key>(NS\w+UsageDescription)</key>',
      ).allMatches(plist))
        match.group(1)!,
    ];

    test('$platform: every purpose is there in every language', () {
      expect(keys, contains('NSCameraUsageDescription'));
      for (final language in languages) {
        final texts = strings(
          '$platform/Runner/$language.lproj/InfoPlist.strings',
        );
        expect(
          texts.keys,
          unorderedEquals(keys),
          reason: '$platform $language',
        );
      }
    });

    test('$platform: the project builds the texts into the app', () {
      final source = File(project).readAsStringSync();
      for (final language in languages) {
        expect(
          source,
          contains('path = $language.lproj/InfoPlist.strings;'),
          reason: '$platform $language',
        );
        expect(
          RegExp(
            r'knownRegions = \(([^)]*)\);',
          ).firstMatch(source)!.group(1),
          contains('$language,'),
        );
      }
      expect(source, contains('/* InfoPlist.strings in Resources */,'));
    });
  }

  test('the iPhone names every use of its camera', () {
    // Barcodes, QR codes, pictures of supplies, the photo translator.
    const named = {
      'de': ['Barcodes', 'QR-Codes', 'Vorräte', 'Übersetzer'],
      'en': ['barcodes', 'QR codes', 'supplies', 'translator'],
      'es': ['códigos de barras', 'códigos QR', 'provisiones', 'traductor'],
    };
    for (final MapEntry(key: language, value: words) in named.entries) {
      final camera = strings(
        'ios/Runner/$language.lproj/InfoPlist.strings',
      )['NSCameraUsageDescription']!;
      for (final word in words) {
        expect(camera, contains(word), reason: language);
      }
    }
  });

  test('the location text names every use of the position (#390)', () {
    // Since the position is measured precisely for the emergency call, the
    // check-in, the meeting point and the defibrillators, the text that
    // asks for it says so, not only "region and shelters".
    const named = {
      'de': [
        'Bundesland',
        'Schutzräume',
        'Defibrillatoren',
        'Notruf',
        'Treffpunkt',
      ],
      'en': [
        'region',
        'shelters',
        'defibrillators',
        'emergency call',
        'meeting point',
      ],
      'es': [
        'estado federado',
        'refugios',
        'desfibriladores',
        'emergencia',
        'punto de encuentro',
      ],
    };
    for (final platform in ['ios', 'macos']) {
      for (final MapEntry(key: language, value: words) in named.entries) {
        final location = strings(
          '$platform/Runner/$language.lproj/InfoPlist.strings',
        )['NSLocationWhenInUseUsageDescription']!;
        for (final word in words) {
          expect(location, contains(word), reason: '$platform $language');
        }
      }
    }
  });
}
