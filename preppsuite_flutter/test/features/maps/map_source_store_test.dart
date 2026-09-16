import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:preppsuite_flutter/features/maps/application/map_download_providers.dart';
import 'package:preppsuite_flutter/features/maps/application/map_source_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MemoryKeyStore implements MapApiKeyStore {
  String? value;

  @override
  Future<void> delete() async => value = null;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String newValue) async => value = newValue;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('stores a map provider key in protected storage', () async {
    final keys = _MemoryKeyStore();
    final store = MapSourceStore(keyStore: keys);

    await store.saveApiKey('a-user-key');

    expect(await store.apiKey(), 'a-user-key');
    expect(
      (await SharedPreferences.getInstance()).getString('mapTilerApiKey'),
      isNull,
    );
  });

  test('migrates a legacy preferences key then removes it', () async {
    SharedPreferences.setMockInitialValues({'mapTilerApiKey': 'legacy-key'});
    final keys = _MemoryKeyStore();

    final key = await MapSourceStore(keyStore: keys).apiKey();

    expect(key, 'legacy-key');
    expect(keys.value, 'legacy-key');
    expect(
      (await SharedPreferences.getInstance()).getString('mapTilerApiKey'),
      isNull,
    );
  });

  test('clearing a key clears protected and legacy storage', () async {
    SharedPreferences.setMockInitialValues({'mapTilerApiKey': 'legacy-key'});
    final keys = _MemoryKeyStore()..value = 'protected-key';

    await MapSourceStore(keyStore: keys).saveApiKey(null);

    expect(keys.value, isNull);
    expect(
      (await SharedPreferences.getInstance()).getString('mapTilerApiKey'),
      isNull,
    );
  });

  test(
    'the map source provider stays usable without a platform key store',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final source = await container.read(mapSourceProvider.future);

      expect(source.apiKey, isNull);
    },
  );
}
