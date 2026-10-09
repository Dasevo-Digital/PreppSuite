import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/core/phone_call.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';

/// A call button that does nothing is the worst kind (#135).
void main() {
  Future<List<Uri>> press(
    WidgetTester tester,
    String number,
    Future<bool> Function(Uri uri) launch,
  ) async {
    final asked = <Uri>[];
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => callNumber(
                context,
                number,
                launch: (uri) {
                  asked.add(uri);
                  return launch(uri);
                },
              ),
              child: const Text('anrufen'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('anrufen'));
    await tester.pumpAndSettle();
    return asked;
  }

  testWidgets('a phone calls, and nothing else happens', (tester) async {
    final asked = await press(tester, '112', (_) async => true);
    expect(asked.single.toString(), 'tel:112');
    expect(find.byType(CannotCallDialog), findsNothing);
  });

  testWidgets('a device without a dialler says so, with the number', (
    tester,
  ) async {
    await press(tester, '112', (_) async => false);
    expect(find.text('Dieses Gerät kann nicht anrufen'), findsOneWidget);
    expect(find.text('112'), findsOneWidget);
  });

  testWidgets('a launcher that throws counts as no call', (tester) async {
    await press(tester, '0531 4700', (_) async => throw StateError('none'));
    expect(find.byType(CannotCallDialog), findsOneWidget);
    // Shown as it was written, dialled as digits.
    expect(find.text('0531 4700'), findsOneWidget);
  });

  test('what goes into the link', () {
    expect(dialableNumber('112'), '112');
    expect(dialableNumber(' 0531 / 47-00 '), '05314700');
    expect(dialableNumber('+49 531 4700'), '+495314700');
    expect(dialableNumber('kein Anschluss'), '');
  });
}
