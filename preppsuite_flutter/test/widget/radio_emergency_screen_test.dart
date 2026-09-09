import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/home/presentation/radio_emergency_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('keeps CB and licensed amateur radio guidance separate', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: RadioEmergencyScreen(),
      ),
    );

    expect(find.text('Kanal 9 AM'), findsOneWidget);
    expect(find.textContaining('27,065 MHz'), findsOneWidget);
    await tester.scrollUntilVisible(find.textContaining('3,760 MHz'), 200);
    expect(find.textContaining('3,760 MHz'), findsOneWidget);
    expect(
      find.textContaining('gültiger Amateurfunkzulassung'),
      findsOneWidget,
    );
    expect(find.textContaining('immer zuerst 112'), findsWidgets);
  });
}
