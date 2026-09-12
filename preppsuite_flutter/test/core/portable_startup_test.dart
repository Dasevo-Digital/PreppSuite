import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/core/app_database_directory.dart';
import 'package:preppsuite_flutter/core/portable_data.dart';
import 'package:preppsuite_flutter/core/portable_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

/// The whole way in: what `main` does before anything else runs.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory workspace;
  late SharedPreferencesStorePlatform platformStore;

  setUp(() {
    workspace = Directory.systemTemp.createTempSync('startup');
    SharedPreferences.setMockInitialValues({});
    platformStore = SharedPreferencesStorePlatform.instance;
  });
  tearDown(() {
    SharedPreferencesStorePlatform.instance = platformStore;
    resetPortableData();
    workspace.deleteSync(recursive: true);
  });

  test('a named folder becomes the place everything is written', () async {
    final location = await startPortableData(
      environment: {portableEnvironmentVariable: workspace.path},
    );

    expect(location.isPortable, isTrue);
    expect(portableSupportDirectory!.path, workspace.path);
    expect(await appSupportDirectory(), isA<Directory>());
    expect((await appSupportDirectory()).path, workspace.path);

    // And a setting saved from anywhere in the app lands in it.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('daylightPlaceName', 'Braunschweig');

    final file = File(
      '${workspace.path}/${PortablePreferencesStore.fileName}',
    );
    expect(file.existsSync(), isTrue);
    expect(file.readAsStringSync(), contains('Braunschweig'));
  });

  test('no folder leaves everything exactly where it was', () async {
    final location = await startPortableData(environment: const {});

    expect(location.isPortable, isFalse);
    expect(portableSupportDirectory, isNull);
    // Whatever store was in place is still in place: an installed copy
    // must behave precisely as it did before any of this existed.
    expect(
      SharedPreferencesStorePlatform.instance,
      isNot(isA<PortablePreferencesStore>()),
    );
  });

  test('a folder that goes away mid-start is not fatal', () async {
    final vanishing = Directory('${workspace.path}/weg')..createSync();
    vanishing.deleteSync();

    final location = await startPortableData(
      environment: {portableEnvironmentVariable: vanishing.path},
    );

    expect(location.isPortable, isFalse);
  });
}
