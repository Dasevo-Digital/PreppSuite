import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// What the privacy manifests declare, and why (#379). App Store Connect
/// reads them on upload; a category that code in the bundle uses and no
/// manifest names comes back as a warning on the upload, and as a
/// rejection once the app goes to review.
///
/// The app's manifest also speaks for the libraries that bring none of
/// their own: home_widget, which writes the widget's data into the app
/// group's defaults, and the SQLite build (`sqlite3mc`), which asks the
/// file system with `statfs`. Plugins that ship a manifest of their own
/// (shared_preferences, flutter_local_notifications and others) are not
/// repeated here.
void main() {
  /// The reasons declared per category, read from the plist without a
  /// plist parser: each category's dict is followed by its reasons.
  Map<String, Set<String>> declared(String path) {
    final text = File(path).readAsStringSync();
    final result = <String, Set<String>>{};
    final entry = RegExp(
      r'<string>(NSPrivacyAccessedAPICategory\w+)</string>\s*'
      r'<key>NSPrivacyAccessedAPITypeReasons</key>\s*<array>(.*?)</array>',
      dotAll: true,
    );
    for (final match in entry.allMatches(text)) {
      result[match.group(1)!] = {
        for (final reason in RegExp(
          r'<string>([0-9A-F]{4}\.\d)</string>',
        ).allMatches(match.group(2)!))
          reason.group(1)!,
      };
    }
    return result;
  }

  test('the app declares what it and its libraries without one use', () {
    expect(declared('ios/Runner/PrivacyInfo.xcprivacy'), {
      // The storage bridge's bookmarks (CA92.1); home_widget's app group
      // defaults (1C8F.1).
      'NSPrivacyAccessedAPICategoryUserDefaults': {'CA92.1', '1C8F.1'},
      // The app's own files, and documents somebody picked.
      'NSPrivacyAccessedAPICategoryFileTimestamp': {'C617.1', '3B52.1'},
      // sqlite3mc's statfs and fstatfs: Apple counts them as disk space
      // APIs whatever they are asked for.
      'NSPrivacyAccessedAPICategoryDiskSpace': {'E174.1'},
    });
  });

  test('the widget declares its app group', () {
    expect(declared('ios/PreppSuiteWidget/PrivacyInfo.xcprivacy'), {
      'NSPrivacyAccessedAPICategoryUserDefaults': {'1C8F.1'},
    });
  });

  test('neither tracks nor collects', () {
    for (final path in [
      'ios/Runner/PrivacyInfo.xcprivacy',
      'ios/PreppSuiteWidget/PrivacyInfo.xcprivacy',
    ]) {
      final text = File(path).readAsStringSync();
      expect(
        text,
        matches(RegExp(r'<key>NSPrivacyTracking</key>\s*<false/>')),
        reason: path,
      );
      expect(
        text,
        matches(
          RegExp(r'<key>NSPrivacyCollectedDataTypes</key>\s*<array/>'),
        ),
        reason: path,
      );
    }
  });
}
