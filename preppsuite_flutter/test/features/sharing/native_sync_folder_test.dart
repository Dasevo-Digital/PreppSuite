import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/core/platform_storage.dart';
import 'package:preppsuite_flutter/features/sharing/application/native_sync_folder.dart';
import 'package:preppsuite_flutter/features/sharing/application/shared_folder_access.dart';
import 'package:preppsuite_flutter/features/sharing/application/sync_folder.dart';

/// The native sides of the shared folder are Kotlin and Swift and cannot
/// be tested here. What can be — and what would break a household quietly
/// — is the layout Dart asks them for: a phone writing to
/// `preppsuite/devices/` and a laptop writing somewhere else would produce
/// two folders that look like one.
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

  const folder = NativeSyncFolder('content://tree/primary%3ASync');

  test('asks for the same paths the desktop folder uses', () async {
    await folder.readHouseholdFile();
    await folder.writeDeviceFile('phone', '{}');
    await folder.readDeviceFile('laptop');

    expect(calls.map((c) => c.arguments['path']), [
      householdFilePath,
      'preppsuite/devices/phone.json',
      'preppsuite/devices/laptop.json',
    ]);
    expect(
      calls.every((c) => c.arguments['uri'] == 'content://tree/primary%3ASync'),
      isTrue,
    );
  });

  test('device ids come back without their extension', () async {
    reply = <String>['phone.json', 'laptop.json', 'notes.txt'];

    expect(await folder.listDeviceIds(), ['phone', 'laptop']);
    expect(calls.single.arguments['path'], devicesDirectoryPath);
  });

  test(
    'a lost permission reads as not writable rather than as an error',
    () async {
      // The native side answers false once the persisted grant is gone — a
      // reinstall, or the user revoking it. Anything else here would turn
      // that into a crash on a background sync.
      reply = false;

      expect(await folder.isWritable(), isFalse);

      reply = null;
      expect(await folder.isWritable(), isFalse);
    },
  );

  group('choosing a reader for a stored location', () {
    // The location outlives the app that stored it: it goes into
    // preferences, and preferences come back from backups and from other
    // devices. Handing a desktop path to the channel, or an iOS bookmark
    // to `dart:io`, is the failure this guards.

    test('an Android tree goes through the channel', () {
      final folder = syncFolderFor(
        'content://com.android.externalstorage/tree/x',
      );
      expect(folder, isA<NativeSyncFolder>());
    });

    test('an iOS bookmark goes through the channel too', () {
      final folder = syncFolderFor(
        'bookmark://6F9619FF-8B86-D011-B42D-00CF4FC964FF',
      );
      expect(folder, isA<NativeSyncFolder>());
    });

    test('a desktop path is opened directly', () {
      expect(syncFolderFor('/Users/someone/Nextcloud'), isA<IoSyncFolder>());
      expect(syncFolderFor(r'C:\Users\someone\Nextcloud'), isA<IoSyncFolder>());
    });

    test('the two handle shapes are the only ones', () {
      expect(isNativeStorageHandle('content://x'), isTrue);
      expect(isNativeStorageHandle('bookmark://x'), isTrue);
      // A path that merely mentions one is still a path.
      expect(isNativeStorageHandle('/home/me/content://x'), isFalse);
      expect(isNativeStorageHandle('/home/me/Sync'), isFalse);
    });
  });
}
