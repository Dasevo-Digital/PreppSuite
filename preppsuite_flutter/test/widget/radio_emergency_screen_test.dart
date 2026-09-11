import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/home/presentation/radio_emergency_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';

import 'accessibility.dart';

void main() {
  Future<void> show(WidgetTester tester) async {
    // Tall enough that the whole list is built: a `ListView` builds only
    // what it can show, and this screen is now long.
    tester.view.physicalSize = const Size(1200, 6000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: RadioEmergencyScreen(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('keeps CB and licensed amateur radio guidance separate', (
    tester,
  ) async {
    await show(tester);

    expect(find.text('Kanal 9 AM'), findsOneWidget);
    expect(find.textContaining('27,065 MHz'), findsOneWidget);
    expect(find.textContaining('3,760 MHz'), findsOneWidget);
    expect(
      find.textContaining('gültiger Amateurfunkzulassung'),
      findsOneWidget,
    );
    expect(find.textContaining('immer zuerst 112'), findsWidgets);
  });

  testWidgets('the two licence-free bands carry the current limits', (
    tester,
  ) async {
    await show(tester);

    expect(find.text('PMR446'), findsOneWidget);
    expect(find.text('446,0–446,2 MHz'), findsOneWidget);
    expect(find.textContaining('0,5 W ERP'), findsWidgets);

    expect(find.text('Freenet Deutschland'), findsOneWidget);
    expect(find.text('149,01875–149,11875 MHz'), findsOneWidget);
    // The figure the 2025 allocation changed, and the border rule that
    // comes with it.
    expect(find.textContaining('1 W ERP'), findsOneWidget);
    expect(
      find.textContaining('belgischen und polnischen Grenze'),
      findsOneWidget,
    );
  });

  testWidgets('each band names the allocation its figures come from', (
    tester,
  ) async {
    await show(tester);

    // Without this a power limit is a number somebody typed. With it, a
    // reader can check it — and can see when it has been superseded.
    expect(find.textContaining('Vfg. 91/2025'), findsOneWidget);
    expect(find.textContaining('Vfg. 45/2025'), findsOneWidget);
  });

  testWidgets('the six Freenet channels are written out', (tester) async {
    await show(tester);

    expect(find.text('Freenet 1'), findsOneWidget);
    expect(find.textContaining('149,0250 MHz'), findsOneWidget);
    expect(find.text('Freenet 6'), findsOneWidget);
    expect(find.textContaining('149,1125 MHz'), findsOneWidget);
    // The digital ones are counted, not listed.
    expect(find.textContaining('12 Kanäle mit 6,25 kHz'), findsOneWidget);
  });

  testWidgets('it refuses to invent a calling channel', (tester) async {
    await show(tester);

    expect(
      find.textContaining('Es gibt keinen amtlichen Anrufkanal'),
      findsOneWidget,
    );
    // The convention is named as a convention, with who is behind it.
    expect(find.textContaining('private Initiative'), findsOneWidget);
    expect(find.textContaining('Kanal 1 verwendet'), findsOneWidget);
    // And the thing that matters most: nobody has to be listening.
    expect(find.textContaining('Niemand ist verpflichtet'), findsOneWidget);
  });

  testWidgets('it says what is forbidden, not only what is allowed', (
    tester,
  ) async {
    await show(tester);

    // The rules the 2025 allocations tightened, and the ones somebody
    // with a mast in the garden is most likely to break.
    expect(find.textContaining('Koaxialkabel'), findsOneWidget);
    expect(find.textContaining('Ortsfeste Funkstellen'), findsOneWidget);
    expect(find.textContaining('kein Gateway'), findsOneWidget);
    expect(find.textContaining('180 Sekunden'), findsOneWidget);
  });

  testWidgets('is accessible', (tester) async {
    await show(tester);

    await expectAccessible(tester);
  });
}
