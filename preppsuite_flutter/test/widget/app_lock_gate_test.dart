import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/core/app_lock_gate.dart';
import 'package:preppsuite_flutter/core/emergency_access.dart';
import 'package:preppsuite_flutter/core/app_lock_provider.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';

class _UnavailableLock extends AppLockController {
  @override
  Future<bool> build() => Future<bool>.error(StateError('secure storage'));
}

class _Locked extends AppLockController {
  @override
  Future<bool> build() async => true;
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
}
