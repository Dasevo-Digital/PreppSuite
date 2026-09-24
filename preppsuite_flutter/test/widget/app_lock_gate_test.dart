import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/core/app_lock_gate.dart';
import 'package:preppsuite_flutter/core/app_lock_provider.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';

class _UnavailableLock extends AppLockController {
  @override
  Future<bool> build() => Future<bool>.error(StateError('secure storage'));
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
}
