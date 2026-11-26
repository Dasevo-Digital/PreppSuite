import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:preppsuite_flutter/core/portable_data.dart';
import 'package:preppsuite_flutter/features/settings/presentation/portable_data_card.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';

import 'accessibility.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(resetPortableData);

  Future<void> show(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: SingleChildScrollView(
              child: PortableDataCard(l10n: AppLocalizations.of(context)!),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('an installed copy says so, and where that is', (tester) async {
    await show(tester);

    expect(find.text('Auf diesem Rechner'), findsOneWidget);
  });

  testWidgets('it says how to turn it on, in the way this platform can', (
    tester,
  ) async {
    await show(tester);

    if (findsPortableFolderByItself) {
      // Windows and Linux: unzip, make the folder, done.
      expect(find.textContaining('PreppSuite-Daten'), findsWidgets);
    } else {
      // macOS cannot find a folder beside the program, because the app
      // runs sandboxed on purpose. Saying why beats letting somebody
      // create the folder and wonder why nothing happened.
      expect(find.textContaining('Sandbox'), findsOneWidget);
      expect(find.text('Ordner auswählen'), findsOneWidget);
    }
  });

  testWidgets('it says the take-over copies rather than moves', (tester) async {
    await show(tester);

    // The one thing somebody needs to be sure of before plugging a stick
    // into a working installation.
    expect(find.textContaining('kopiert, nicht verschoben'), findsOneWidget);
  });

  testWidgets('it explains why archives survive a changed drive letter', (
    tester,
  ) async {
    await show(tester);

    expect(find.textContaining('anderen Buchstaben'), findsOneWidget);
  });

  testWidgets('is accessible', (tester) async {
    await show(tester);

    await expectAccessible(tester);
  });

  group('the household installed here (#392)', () {
    late Directory workspace;
    late SharedPreferencesStorePlatform platform;

    setUp(() {
      workspace = Directory.systemTemp.createTempSync('portable-card');
      SharedPreferences.setMockInitialValues({});
      platform = SharedPreferencesStorePlatform.instance;
    });

    tearDown(() {
      SharedPreferencesStorePlatform.instance = platform;
      workspace.deleteSync(recursive: true);
    });

    Future<void> carry(WidgetTester tester, Directory installation) async {
      final folder = Directory(p.join(workspace.path, 'PreppSuite-Daten'))
        ..createSync();
      await tester.runAsync(
        () => startPortableData(
          environment: {portableEnvironmentVariable: folder.path},
          installationDirectory: () async => installation,
        ),
      );
    }

    testWidgets('a refusal to take it over is said', (tester) async {
      // An installation in the middle of its upgrade is not copied. The
      // carried copy then starts empty, which looks like a lost household
      // unless something says why.
      final installation = Directory(p.join(workspace.path, 'installiert'))
        ..createSync();
      File(
        p.join(installation.path, 'preppsuite.sqlite.plaintext-recovery'),
      ).writeAsStringSync('');
      await carry(tester, installation);
      expect(portableTakeover, PortableTakeover.failed);

      await show(tester);

      expect(find.textContaining('ließ sich nicht übernehmen'), findsOneWidget);
    }, skip: !supportsPortableData);

    testWidgets('nothing of the kind without one', (tester) async {
      await carry(tester, workspace);

      await show(tester);

      expect(find.textContaining('nicht übernehmen'), findsNothing);
      expect(find.textContaining('nicht übernommen'), findsNothing);
    }, skip: !supportsPortableData);
  });
}
