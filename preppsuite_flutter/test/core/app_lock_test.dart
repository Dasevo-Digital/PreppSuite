import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/core/app_lock.dart';

class _MemoryStorage implements AppLockStorage {
  final values = <String, String>{};

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}

void main() {
  AppLockStore store(_MemoryStorage storage) => AppLockStore(
    storage: storage,
    // Keeps the regression test fast. The installed app uses the secure
    // defaults documented in AppLockStore.
    memory: 1024,
    iterations: 1,
  );

  test('enables, verifies and removes the optional device lock', () async {
    final storage = _MemoryStorage();
    final lock = store(storage);

    expect(await lock.isEnabled(), isFalse);

    await lock.enable('ein-langer-test-schluessel');
    expect(await lock.isEnabled(), isTrue);
    expect(await lock.verify('ein-langer-test-schluessel'), isTrue);
    expect(await lock.verify('falscher-schluessel'), isFalse);

    await lock.disable();
    expect(await lock.isEnabled(), isFalse);
    expect(await lock.verify('ein-langer-test-schluessel'), isFalse);
  });

  test('rejects an incomplete secure-store verifier', () async {
    final storage = _MemoryStorage();
    await store(storage).enable('ein-langer-test-schluessel');
    storage.values.remove('appLock.check.v1');

    expect(await store(storage).verify('ein-langer-test-schluessel'), isFalse);
  });
}
