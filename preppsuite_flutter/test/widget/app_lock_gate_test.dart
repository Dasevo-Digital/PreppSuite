import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:preppsuite_flutter/app.dart';
import 'package:preppsuite_flutter/core/app_lock_gate.dart';
import 'package:preppsuite_flutter/core/emergency_access.dart';
import 'package:preppsuite_flutter/core/app_lock_provider.dart';
import 'package:preppsuite_flutter/core/biometric_unlock.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';

class _UnavailableLock extends AppLockController {
  @override
  Future<bool> build() => Future<bool>.error(StateError('secure storage'));
}

class _Locked extends AppLockController {
  @override
  Future<bool> build() async => true;
}

class _BiometricOn extends AppLockBiometricController {
  @override
  Future<bool> build() async => true;
}

class _BiometricOff extends AppLockBiometricController {
  @override
  Future<bool> build() async => false;
}

class _Sensor implements BiometricAuth {
  _Sensor({required this.recognises});

  bool recognises;
  var asked = 0;

  @override
  Future<bool> available() async => true;

  @override
  Future<bool> authenticate(String reason) async {
    asked++;
    return recognises;
  }
}

class _PendingSensor extends _Sensor {
  _PendingSensor() : super(recognises: false);
  final requests = <Completer<bool>>[];

  @override
  Future<bool> authenticate(String reason) {
    final request = Completer<bool>();
    requests.add(request);
    return request.future;
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({'localeOverride': 'de'}));

  testWidgets('a biometric result from before relocking cannot open the app', (
    tester,
  ) async {
    final sensor = _PendingSensor();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appLockProvider.overrideWith(_Locked.new),
          appLockBiometricProvider.overrideWith(_BiometricOn.new),
          biometricAuthProvider.overrideWithValue(sensor),
        ],
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (_, child) => AppLockGate(child: child!),
          home: const Text('private household data'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(sensor.requests, hasLength(1));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(sensor.requests, hasLength(1));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(sensor.requests, hasLength(2));
    sensor.requests.first.complete(true);
    sensor.requests.last.complete(false);
    await tester.pumpAndSettle();
    expect(find.text('private household data'), findsNothing);
    expect(find.text('PreppSuite entsperren'), findsOneWidget);
  });

  for (final kind in ['page', 'dialog', 'sheet']) {
    testWidgets(
      'relocking covers a private $kind and preserves it for unlock',
      (tester) async {
        final semantics = tester.ensureSemantics();
        try {
          final sensor = _Sensor(recognises: true);
          var actions = 0;
          Widget detail() => Scaffold(
            body: TextButton(
              onPressed: () => actions++,
              child: const Text('private action'),
            ),
          );
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                appLockProvider.overrideWith(_Locked.new),
                appLockBiometricProvider.overrideWith(_BiometricOn.new),
                biometricAuthProvider.overrideWithValue(sensor),
              ],
              child: MaterialApp(
                locale: const Locale('de'),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                builder: (_, child) => AppLockGate(child: child!),
                home: Builder(
                  builder: (context) => Scaffold(
                    body: TextButton(
                      child: const Text('open private'),
                      onPressed: () {
                        if (kind == 'dialog') {
                          showDialog<void>(
                            context: context,
                            builder: (_) => detail(),
                          );
                        } else if (kind == 'sheet') {
                          showModalBottomSheet<void>(
                            context: context,
                            builder: (_) => detail(),
                          );
                        } else {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(builder: (_) => detail()),
                          );
                        }
                      },
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.text('open private'));
          await tester.pumpAndSettle();
          expect(find.text('private action'), findsOneWidget);
          sensor.recognises = false;
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.inactive,
          );
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.hidden,
          );
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.paused,
          );
          await tester.pump();
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.hidden,
          );
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.inactive,
          );
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.resumed,
          );
          await tester.pumpAndSettle();
          expect(find.text('private action'), findsNothing);
          expect(find.bySemanticsLabel('private action'), findsNothing);
          expect(find.text('PreppSuite entsperren'), findsOneWidget);
          expect(actions, 0);
          await tester.tap(find.text('Notfall: 112 und Erste Hilfe'));
          await tester.pumpAndSettle();
          expect(find.byType(EmergencyAccessScreen), findsOneWidget);
          expect(find.text('private action'), findsNothing);
          await tester.tap(find.byType(BackButton));
          await tester.pumpAndSettle();
          sensor.recognises = true;
          await tester.tap(find.text('Mit Gesicht oder Fingerabdruck'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('private action'));
          expect(actions, 1);
        } finally {
          semantics.dispose();
        }
      },
    );
  }

  testWidgets('system back in the app returns from public help to the lock', (
    tester,
  ) async {
    tester.platformDispatcher.localeTestValue = const Locale('de');
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appLockProvider.overrideWith(_Locked.new),
          appLockBiometricProvider.overrideWith(_BiometricOff.new),
        ],
        child: const PreppSuiteApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Notfall: 112 und Erste Hilfe'));
    await tester.pumpAndSettle();
    expect(find.byType(EmergencyAccessScreen), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(EmergencyAccessScreen), findsNothing);
    expect(find.text('PreppSuite entsperren'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('PreppSuite entsperren'), findsOneWidget);
  });
  testWidgets('does not reveal the app when lock status cannot be read', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appLockProvider.overrideWith(_UnavailableLock.new)],
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AppLockGate(child: Text('private household data')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sperrstatus nicht verfügbar'), findsOneWidget);
    expect(find.text('private household data'), findsNothing);
    expect(find.text('Erneut versuchen'), findsOneWidget);
  });

  Future<void> pump(WidgetTester tester, AppLockController Function() lock) =>
      tester.pumpWidget(
        ProviderScope(
          overrides: [appLockProvider.overrideWith(lock)],
          child: MaterialApp(
            locale: const Locale('de'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const AppLockGate(child: Text('private household data')),
          ),
        ),
      );

  testWidgets('a locked app still leads to 112 and first aid (#137)', (
    tester,
  ) async {
    await pump(tester, _Locked.new);
    await tester.pumpAndSettle();
    expect(find.text('PreppSuite entsperren'), findsOneWidget);

    await tester.tap(find.text('Notfall: 112 und Erste Hilfe'));
    await tester.pumpAndSettle();
    expect(find.byType(EmergencyAccessScreen), findsOneWidget);
    expect(find.textContaining('112 anrufen'), findsOneWidget);
    expect(find.text('Erste Hilfe'), findsOneWidget);
    // And nothing of the household behind it.
    expect(find.text('private household data'), findsNothing);
  });

  testWidgets('so does a lock whose state cannot be read', (tester) async {
    await pump(tester, _UnavailableLock.new);
    await tester.pumpAndSettle();
    expect(find.byType(EmergencyAccessButton), findsOneWidget);
  });

  testWidgets('a load that hangs offers the way out after a while', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: LoadingWithEmergencyAccess(),
      ),
    );
    expect(find.byType(EmergencyAccessButton), findsNothing);
    await tester.pump(const Duration(seconds: 5));
    expect(find.byType(EmergencyAccessButton), findsOneWidget);
  });

  group('face or fingerprint (#143)', () {
    Future<_Sensor> pumpWith(
      WidgetTester tester, {
      required bool on,
      required bool recognises,
    }) async {
      final sensor = _Sensor(recognises: recognises);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appLockProvider.overrideWith(_Locked.new),
            appLockBiometricProvider.overrideWith(
              on ? _BiometricOn.new : _BiometricOff.new,
            ),
            biometricAuthProvider.overrideWithValue(sensor),
          ],
          child: MaterialApp(
            locale: const Locale('de'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const AppLockGate(child: Text('private household data')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return sensor;
    }

    testWidgets('a recognised face opens the app without the passphrase', (
      tester,
    ) async {
      final sensor = await pumpWith(tester, on: true, recognises: true);
      expect(sensor.asked, 1);
      expect(find.text('private household data'), findsOneWidget);
    });

    testWidgets('a cancelled prompt leaves it locked, with a way to retry', (
      tester,
    ) async {
      final sensor = await pumpWith(tester, on: true, recognises: false);
      expect(sensor.asked, 1);
      expect(find.text('private household data'), findsNothing);
      // Asked once by itself, then only on the button.
      await tester.pumpAndSettle();
      expect(sensor.asked, 1);
      await tester.tap(find.text('Mit Gesicht oder Fingerabdruck'));
      await tester.pumpAndSettle();
      expect(sensor.asked, 2);
      // The passphrase field is still there.
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('without the setting, nobody is asked for a face', (
      tester,
    ) async {
      final sensor = await pumpWith(tester, on: false, recognises: true);
      expect(sensor.asked, 0);
      expect(find.text('Mit Gesicht oder Fingerabdruck'), findsNothing);
      expect(find.text('private household data'), findsNothing);
    });
  });
}
