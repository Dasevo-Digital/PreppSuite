import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/core/platform_storage.dart';
import 'package:preppsuite_flutter/features/maps/application/map_archive_access.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('native readers of the same URI have independent lifetimes', () async {
    final handles = <String>{};
    final bytes = Uint8List.fromList([10, 20, 30, 40]);
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(nativeStorageChannel, (call) async {
      final a = call.arguments as Map;
      final token = a['fileToken'] as String;
      expect(token, isNotEmpty);
      switch (call.method) {
        case 'openFile':
          handles.add(token);
          return true;
        case 'closeFile':
          handles.remove(token);
          return null;
        case 'readRange':
          if (!handles.contains(token)) throw PlatformException(code: 'closed');
          return bytes.sublist(
            a['offset'] as int,
            (a['offset'] as int) + (a['length'] as int),
          );
      }
      throw StateError('Unexpected method');
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(nativeStorageChannel, null),
    );
    final first = await NativeByteRangeSource.open('bookmark://same');
    final second = await NativeByteRangeSource.open('bookmark://same');
    expect(handles, hasLength(2));
    await first.close();
    expect(await second.read(1, 2), [20, 30]);
    await second.close();
    expect(handles, isEmpty);
  });
}
