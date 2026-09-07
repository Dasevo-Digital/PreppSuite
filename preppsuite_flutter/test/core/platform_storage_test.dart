import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/core/platform_storage.dart';

/// Which platforms hand back a handle instead of a path, and what happens
/// to a handle afterwards.
///
/// macOS joined that group when the app took on the sandbox. Getting the
/// answer wrong there is not a visible bug but a quiet one: the app would
/// pick with `file_picker`, store a bare path, and find it unreadable on
/// the next launch — with the archive still sitting there, untouched.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('preppsuite/storage');
  late List<MethodCall> calls;
  Object? reply;

  setUp(() {
    calls = [];
    reply = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return reply;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('the sandboxed platforms pick natively, the open ones do not', () {
    expect(
      usesNativeStoragePicker,
      Platform.isMacOS || Platform.isAndroid || Platform.isIOS,
    );
    // Only macOS resolves a handle back into a usable path: Android's
    // `content://` never becomes one, and iOS keeps its archives inside
    // the app's own storage.
    expect(usesStorageBookmarks, Platform.isMacOS);
  });

  test('a plain path is never sent to the native side', () async {
    expect(await resolveStoragePath('/Users/me/Documents/PreppSuite'), isNull);
    expect(calls, isEmpty);
  });

  test('a handle that no longer resolves reads as absent', () async {
    if (!usesStorageBookmarks) return;

    reply = null;
    expect(await resolveStoragePath('bookmark://gone'), isNull);
    expect(calls.single.method, 'resolvePath');
    expect(calls.single.arguments, {'uri': 'bookmark://gone'});
  });

  test('a handle that resolves comes back as a path', () async {
    if (!usesStorageBookmarks) return;

    reply = '/Volumes/Backup/PreppSuite';
    expect(
      await resolveStoragePath('bookmark://kept'),
      '/Volumes/Backup/PreppSuite',
    );
  });

  test('a native side that is not there is not fatal', () async {
    if (!usesStorageBookmarks) return;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);

    // A build without the bridge registered would otherwise take the
    // whole download folder down with it.
    expect(await resolveStoragePath('bookmark://kept'), isNull);
  });
}
