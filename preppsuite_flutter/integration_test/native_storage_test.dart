import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:preppsuite_flutter/core/platform_storage.dart';

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
