import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_background_worker.dart';

/// Nothing at run time shows that these are missing (#345): the plugin
/// logs a refused submit and Dart sees success, the poll simply never runs
/// in the background, and a warning found in the foreground is marked as
/// told without a banner. Neither shows in the simulator, which has no
/// background scheduler at all.
void main() {
  final plist = File('ios/Runner/Info.plist').readAsStringSync();
  final delegate = File('ios/Runner/AppDelegate.swift').readAsStringSync();

  test('iOS permits the task under the name Dart submits it', () {
    final permitted = RegExp(
      r'<key>BGTaskSchedulerPermittedIdentifiers</key>\s*<array>(.*?)</array>',
      dotAll: true,
    ).firstMatch(plist)?.group(1);
    expect(permitted, isNotNull);
    expect(permitted, contains('<string>$warningPollTaskUniqueName</string>'));
    expect(plist, contains('<string>fetch</string>'));
  });

  test('the app registers its launch handler before launching ends', () {
    expect(delegate, contains('"$warningPollTaskUniqueName"'));
    expect(delegate, contains('WorkmanagerPlugin.registerPeriodicTask('));
    expect(delegate, contains('WorkmanagerPlugin.setPluginRegistrantCallback'));
    // In didFinishLaunching, ahead of the call that ends it.
    final launch = delegate.indexOf('didFinishLaunchingWithOptions');
    final ends = delegate.indexOf('return super.application(', launch);
    final registered = delegate.indexOf('registerPeriodicTask(', launch);
    expect(launch, greaterThan(0));
    expect(registered, inExclusiveRange(launch, ends));
  });

  test('notifications show while the app is open', () {
    expect(
      delegate,
      contains('UNUserNotificationCenter.current().delegate = self'),
    );
  });
}
