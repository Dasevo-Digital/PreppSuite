import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/core/platform_storage.dart';
import 'package:preppsuite_flutter/features/downloads/application/download_folder.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The download folder under a sandbox.
///
/// The stored path is not enough there: until the bookmark behind the
/// handle has opened the scope, that path is a place the app may not go,
/// and asking whether it exists answers no. Falling back on that answer
/// would drop the folder the user chose — for the largest files the app
/// ever writes — without saying a word.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('preppsuite/storage');
  late Directory chosen;
  String? resolves;

  setUp(() {
    chosen = Directory.systemTemp.createTempSync('preppsuite-downloads');
    resolves = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          return call.method == 'resolvePath' ? resolves : null;
        });
  });

  tearDown(() {
    chosen.deleteSync(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('a handle is stored beside the path and cleared with it', () async {
    SharedPreferences.setMockInitialValues({});

    await const DownloadFolder().use(chosen.path, handle: 'bookmark://a');
    var prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('archiveDownloadFolder'), chosen.path);
    expect(prefs.getString('archiveDownloadFolderHandle'), 'bookmark://a');

    await const DownloadFolder().reset();
    prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('archiveDownloadFolder'), isNull);
    expect(prefs.getString('archiveDownloadFolderHandle'), isNull);
  });

  test('choosing without a handle drops the one that was there', () async {
    SharedPreferences.setMockInitialValues({});

    await const DownloadFolder().use(chosen.path, handle: 'bookmark://a');
    // A restored backup from a Mac, opened on Linux: the handle means
    // nothing there and must not outlive the folder it belonged to.
    await const DownloadFolder().use(chosen.path);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('archiveDownloadFolderHandle'), isNull);
  });

  test('the handle decides where the folder is', () async {
    if (!usesStorageBookmarks) return;

    SharedPreferences.setMockInitialValues({
      'flutter.archiveDownloadFolder': '/somewhere/that/is/not/there',
      'flutter.archiveDownloadFolderHandle': 'bookmark://a',
    });
    resolves = chosen.path;

    // The stored path is deliberately wrong: what counts is what the
    // bookmark resolved to, not what was written down last time.
    expect((await const DownloadFolder().current()).path, chosen.path);
  });

  test('a handle that no longer resolves falls back to the path', () async {
    if (!usesStorageBookmarks) return;

    SharedPreferences.setMockInitialValues({
      'flutter.archiveDownloadFolder': chosen.path,
      'flutter.archiveDownloadFolderHandle': 'bookmark://gone',
    });
    resolves = null;

    expect((await const DownloadFolder().current()).path, chosen.path);
  });
}
