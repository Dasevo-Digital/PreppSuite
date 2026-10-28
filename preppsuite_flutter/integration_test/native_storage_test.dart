import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:integration_test/integration_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:preppsuite_flutter/core/platform_storage.dart';
import 'package:preppsuite_flutter/features/maps/application/map_archive_access.dart';

/// Checks that something is actually answering on the storage channel.
///
/// The unit suite mocks it, which proves what Dart asks for and nothing
/// about whether anyone is listening — and the two implementations that
/// have to listen are Kotlin and Swift. A missing registration, a renamed
/// method or a channel that crashes on a bad handle would all pass every
/// other test in the repository and fail on the first folder anybody
/// picks.
///
/// Run against a device or simulator:
///
/// ```bash
/// flutter test integration_test/native_storage_test.dart -d <device>
/// ```
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('the native storage bridge', () {
    testWidgets(
      'Android ranged readers survive repeated reads and another close',
      (
        tester,
      ) async {
        await tester.runAsync(() async {
          // Use the app's existing share provider to obtain a real content URI
          // without a picker or any permission outside this test's cache file.
          final cache = await getTemporaryDirectory();
          final folder = await Directory('${cache.path}/share_plus').create();
          final name = 'reader-${DateTime.now().microsecondsSinceEpoch}.bin';
          final file = File('${folder.path}/$name')
            ..writeAsBytesSync([10, 20, 30, 40]);
          addTearDown(file.delete);
          final package = (await PackageInfo.fromPlatform()).packageName;
          final uri = 'content://$package.flutter.share_provider/cache/$name';
          final first = await NativeByteRangeSource.open(uri);
          final second = await NativeByteRangeSource.open(uri);
          addTearDown(first.close);
          addTearDown(second.close);
          expect(await first.read(0, 2), [10, 20]);
          expect(await first.read(2, 2), [30, 40]);
          await first.close();
          expect(await second.read(1, 2), [20, 30]);
          expect(await second.read(0, 4), [10, 20, 30, 40]);
        });
      },
      skip: !Platform.isAndroid,
    );

    testWidgets('an invalid leased reader is rejected and closes harmlessly', (
      tester,
    ) async {
      const arguments = {
        'uri': 'bookmark://00000000-0000-0000-0000-000000000000',
        'fileToken': 'unavailable-reader',
      };
      expect(
        await nativeStorageChannel.invokeMethod<bool>('openFile', arguments),
        isFalse,
      );
      await nativeStorageChannel.invokeMethod<void>('closeFile', arguments);
      await expectLater(
        nativeStorageChannel.invokeMethod<Object>('readRange', {
          ...arguments,
          'offset': 0,
          'length': 1,
        }),
        throwsA(
          isA<PlatformException>().having((e) => e.code, 'code', 'not-open'),
        ),
      );
    });
    testWidgets('a write through a dead handle reports failure', (
      tester,
    ) async {
      expect(usesNativeStoragePicker, isTrue);
      await expectLater(
        nativeStorageChannel.invokeMethod<void>('write', {
          'uri': 'bookmark://00000000-0000-0000-0000-000000000000',
          'path': 'preppsuite/devices/test.json',
          'contents': '{}',
        }),
        throwsA(
          isA<PlatformException>().having(
            (error) => error.code,
            'code',
            'write-failed',
          ),
        ),
      );
    });
    testWidgets('answers at all', (tester) async {
      expect(
        usesNativeStoragePicker,
        isTrue,
        reason: 'run the native integration suite on Android or iOS',
      );

      // A handle that resolves to nothing: no permission on Android, no
      // such bookmark on iOS. Both must say so rather than throw — this
      // is what the app sees after a reinstall.
      final opened = await nativeStorageChannel.invokeMethod<bool>('openFile', {
        'uri': 'bookmark://00000000-0000-0000-0000-000000000000',
      });

      expect(
        opened,
        isFalse,
        reason: 'a handle that resolves to nothing must read as unopenable',
      );
    });

    testWidgets('a folder that cannot be resolved is not writable', (
      tester,
    ) async {
      expect(usesNativeStoragePicker, isTrue);

      final writable = await nativeStorageChannel.invokeMethod<bool>(
        'ensureWritable',
        {'uri': 'bookmark://00000000-0000-0000-0000-000000000000'},
      );

      expect(writable, isFalse);
    });

    testWidgets('reading through a dead handle gives nothing, not an error', (
      tester,
    ) async {
      expect(usesNativeStoragePicker, isTrue);

      final contents = await nativeStorageChannel.invokeMethod<String>('read', {
        'uri': 'bookmark://00000000-0000-0000-0000-000000000000',
        'path': 'preppsuite/household.json',
      });

      expect(contents, isNull);
    });
  });
}
