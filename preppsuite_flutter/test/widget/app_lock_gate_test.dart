import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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

  final bool recognises;
  var asked = 0;

  @override
  Future<bool> available() async => true;

  @override
  Future<bool> authenticate(String reason) async {
    asked++;
    return recognises;
  }
}

void main() {
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
