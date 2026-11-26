import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'package:preppsuite_flutter/core/app_lock_provider.dart';
import 'package:preppsuite_flutter/core/portable_data.dart';
import 'package:preppsuite_flutter/features/settings/presentation/app_lock_card.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';

class _Unlocked extends AppLockController {
  @override
  Future<bool> build() async => false;
}

Widget _card() => ProviderScope(
  overrides: [appLockProvider.overrideWith(_Unlocked.new)],
  child: MaterialApp(
    locale: const Locale('de'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Builder(
      builder: (context) => Scaffold(
        body: AppLockCard(l10n: AppLocalizations.of(context)!),
      ),
    ),
  ),
);

void main() {
  late Directory folder;
  late SharedPreferencesStorePlatform platform;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    platform = SharedPreferencesStorePlatform.instance;
    folder = Directory.systemTemp.createTempSync('lock-card');
  });

  tearDown(() {
    SharedPreferencesStorePlatform.instance = platform;
    resetPortableData();
    folder.deleteSync(recursive: true);
  });

  testWidgets('an installed copy offers the lock', (tester) async {
    await tester.pumpWidget(_card());
    await tester.pumpAndSettle();

    expect(find.byType(Switch), findsOneWidget);
  });

  testWidgets('a carried folder says it has none, and why (#392)', (
    tester,
  ) async {
    await tester.runAsync(
      () => startPortableData(
        environment: {portableEnvironmentVariable: folder.path},
      ),
    );

    await tester.pumpWidget(_card());
    await tester.pumpAndSettle();

    expect(find.byType(Switch), findsNothing);
    expect(
      find.textContaining('mitgeführten Datenordner gibt es keine App-Sperre'),
      findsOneWidget,
    );
  });
}
