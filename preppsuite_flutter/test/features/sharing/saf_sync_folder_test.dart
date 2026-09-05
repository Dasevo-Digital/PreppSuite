import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/sharing/application/saf_sync_folder.dart';
import 'package:preppsuite_flutter/features/sharing/application/sync_folder.dart';

/// The Android side of the shared folder is Kotlin and cannot be tested
/// here. What can be — and what would break a household quietly — is the
/// layout Dart asks it for: a phone writing to `preppsuite/devices/` and a
/// laptop writing somewhere else would produce two folders that look like
/// one.
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

  const folder = SafSyncFolder('content://tree/primary%3ASync');

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
}
