import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/core/portable_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory workspace;
  setUp(() => workspace = Directory.systemTemp.createTempSync('prefs'));
  tearDown(() => workspace.deleteSync(recursive: true));

  File file() => File('${workspace.path}/${PortablePreferencesStore.fileName}');

  test('a setting written lands in the folder, not in the platform', () async {
    final store = await PortablePreferencesStore.open(workspace);
    await store.setValue('String', 'flutter.name', 'Braunschweig');

    expect(file().existsSync(), isTrue);
    expect(jsonDecode(file().readAsStringSync()), {
      'flutter.name': 'Braunschweig',
    });
  });

  test('what was written is read back by a second copy of the app', () async {
    final first = await PortablePreferencesStore.open(workspace);
    await first.setValue('Int', 'flutter.days', 10);
    await first.setValue('Bool', 'flutter.dark', true);
    await first.setValue('Double', 'flutter.radius', 2.5);
    await first.setValue('StringList', 'flutter.roads', <String>['A2', 'A39']);

    final second = await PortablePreferencesStore.open(workspace);
    final all = await second.getAll();

    expect(all['flutter.days'], 10);
    expect(all['flutter.dark'], isTrue);
    expect(all['flutter.radius'], 2.5);
    expect(all['flutter.roads'], ['A2', 'A39']);
  });

  test('a list comes back as a list of strings, not of anything', () async {
    // JSON gives back `List<dynamic>`, and every caller in the app asks
    // for `List<String>`. Handing over the first would throw at the call
    // site rather than here, which is a long way from the cause.
    final first = await PortablePreferencesStore.open(workspace);
    await first.setValue('StringList', 'flutter.roads', <String>['A2']);

    final second = await PortablePreferencesStore.open(workspace);
    final value = (await second.getAll())['flutter.roads'];

    expect(value, isA<List<String>>());
  });

  test('removing and clearing reach the file', () async {
    final store = await PortablePreferencesStore.open(workspace);
    await store.setValue('String', 'flutter.a', 'one');
    await store.setValue('String', 'flutter.b', 'two');

    await store.remove('flutter.a');
    expect((await store.getAll()).keys, ['flutter.b']);

    await store.clear();
    expect(await store.getAll(), isEmpty);
    expect(jsonDecode(file().readAsStringSync()), isEmpty);
  });

  test('a damaged file loses the settings, not the app', () async {
    file().writeAsStringSync('{ this is not json');

    final store = await PortablePreferencesStore.open(workspace);
    expect(await store.getAll(), isEmpty);

    // And it is usable again straight away.
    await store.setValue('String', 'flutter.name', 'wieder da');
    expect((await store.getAll())['flutter.name'], 'wieder da');
  });

  test(
    'nothing half-written is left behind if a write is interrupted',
    () async {
      // Written beside and renamed over. On a carried disk "the disk went
      // away mid-write" is not a theoretical failure — it is how the disk
      // usually goes away.
      final store = await PortablePreferencesStore.open(workspace);
      await store.setValue('String', 'flutter.name', 'eins');
      await store.setValue('String', 'flutter.name', 'zwei');

      final leftovers = workspace
          .listSync()
          .map((e) => e.uri.pathSegments.last)
          .where((name) => name.isNotEmpty)
          .toList();
      expect(leftovers, [PortablePreferencesStore.fileName]);
    },
  );

  test('two settings saved at once do not race for the file', () async {
    final store = await PortablePreferencesStore.open(workspace);
    await Future.wait([
      for (var i = 0; i < 20; i++) store.setValue('Int', 'flutter.key$i', i),
    ]);

    final reopened = await PortablePreferencesStore.open(workspace);
    expect((await reopened.getAll()).length, 20);
  });

  test('the settings of an installed copy are taken over once', () async {
    final installed = InMemorySharedPreferencesStore.withData({
      'flutter.archive': '/irgendwo/wikipedia.zim',
      'flutter.days': 10,
    });

    final store = await PortablePreferencesStore.open(workspace);
    await adoptInstalledPreferences(store, installed);

    expect(
      (await store.getAll())['flutter.archive'],
      '/irgendwo/wikipedia.zim',
    );
    expect((await store.getAll())['flutter.days'], 10);
  });

  test('a folder that has been used once is never written over', () async {
    final store = await PortablePreferencesStore.open(workspace);
    await store.setValue('String', 'flutter.archive', '/auf/dem/stick.zim');

    await adoptInstalledPreferences(
      store,
      InMemorySharedPreferencesStore.withData({
        'flutter.archive': '/auf/dem/rechner.zim',
      }),
    );

    expect((await store.getAll())['flutter.archive'], '/auf/dem/stick.zim');
  });

  test(
    'registered in place of the platform, it serves SharedPreferences',
    () async {
      // The point of the whole exercise: the twenty-six places that read a
      // setting go on calling `SharedPreferences.getInstance()` and know
      // nothing about any of this.
      final previous = SharedPreferencesStorePlatform.instance;
      addTearDown(() => SharedPreferencesStorePlatform.instance = previous);

      SharedPreferencesStorePlatform.instance =
          await PortablePreferencesStore.open(workspace);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('daylightPlaceName', 'Braunschweig');

      expect(file().readAsStringSync(), contains('Braunschweig'));
    },
  );
}
