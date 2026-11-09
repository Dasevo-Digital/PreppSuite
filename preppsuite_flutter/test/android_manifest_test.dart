import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Nothing at run time shows that these are missing: the list of pending
/// notifications looks right and the alarm is set, and on the day it comes
/// due nobody is there to receive it (#331).
void main() {
  final manifest = File(
    'android/app/src/main/AndroidManifest.xml',
  ).readAsStringSync();

  test('scheduled reminders have somebody to receive them', () {
    expect(
      manifest,
      contains(
        'com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver',
      ),
    );
  });

  test('and they come back after a restart', () {
    expect(
      manifest,
      contains(
        'com.dexterous.flutterlocalnotifications'
        '.ScheduledNotificationBootReceiver',
      ),
    );
    expect(manifest, contains('android.intent.action.BOOT_COMPLETED'));
    expect(manifest, contains('android.intent.action.MY_PACKAGE_REPLACED'));
    expect(manifest, contains('android.permission.RECEIVE_BOOT_COMPLETED'));
  });
}
