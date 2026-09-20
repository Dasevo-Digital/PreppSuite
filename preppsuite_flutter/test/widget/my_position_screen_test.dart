import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/maps/application/readable_position.dart';
import 'package:preppsuite_flutter/features/maps/presentation/my_position_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';

import 'accessibility.dart';

/// Where I am, in a form somebody else can write down.
///
/// The screen exists for one moment: the telephone is at your ear and
/// somebody has asked where you are. So what is pinned here is that the
/// answer is on screen, that it can be taken off the screen, and that the
/// doubt is shown next to it rather than hidden.
void main() {
  const gate = ReadablePosition(
    latitude: 52.516275,
    longitude: 13.377704,
    accuracyMetres: 12,
  );

  Future<void> show(
    WidgetTester tester, {
    ReadablePosition position = gate,
    String locale = 'de',
  }) async {
    await tester.binding.setSurfaceSize(const Size(500, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        locale: Locale(locale),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MyPositionScreen(initial: position),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('all four spellings of the point are on screen', (tester) async {
    await show(tester);

    expect(find.text('52° 30′ 58.6″ N, 13° 22′ 39.7″ E'), findsOneWidget);
    expect(find.text('33U 389918 5819699'), findsOneWidget);
    expect(find.text('33U UU 89918 19699'), findsOneWidget);
    expect(find.text('9F4MG98H+G3'), findsOneWidget);
  });

  testWidgets('degrees and minutes come first', (tester) async {
    // Ordered by who is listening, not by precision: a German control
    // room asks for degrees and minutes and reads them back.
    await show(tester);

    expect(
      tester.getTopLeft(find.text('52° 30′ 58.6″ N, 13° 22′ 39.7″ E')).dy,
      lessThan(tester.getTopLeft(find.text('33U 389918 5819699')).dy),
    );
  });

  testWidgets('a line can be taken off the screen', (tester) async {
    final copied = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied.add((call.arguments as Map)['text'] as String);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await show(tester);
    await tester.tap(find.byIcon(Icons.copy_outlined).first);
    await tester.pumpAndSettle();

    expect(copied, ['52° 30′ 58.6″ N, 13° 22′ 39.7″ E']);
    expect(find.text('Kopiert.'), findsOneWidget);
  });

  testWidgets('the fix says what it is worth', (tester) async {
    await show(tester);

    expect(find.textContaining('±12 m'), findsOneWidget);
  });

  testWidgets('a rough fix says so rather than looking exact', (tester) async {
    // Ten metres is a doorway, eight hundred is the wrong end of the
    // village, and both print the same number of digits.
    await show(
      tester,
      position: const ReadablePosition(
        latitude: 52.516275,
        longitude: 13.377704,
        accuracyMetres: 800,
      ),
    );

    expect(find.textContaining('±800 m'), findsOneWidget);
    expect(find.textContaining('nicht bis zur Hausnummer'), findsOneWidget);
  });

  testWidgets('a position picked on the map carries no false accuracy', (
    tester,
  ) async {
    await show(
      tester,
      position: const ReadablePosition(latitude: 52.5, longitude: 13.4),
    );

    expect(find.textContaining('±'), findsNothing);
  });

  testWidgets('it says that this needs no network', (tester) async {
    await show(tester);
    expect(find.textContaining('kein Netz'), findsOneWidget);
  });

  testWidgets('English gets the English screen', (tester) async {
    await show(tester, locale: 'en');
    expect(find.text('My position'), findsOneWidget);
    expect(find.textContaining('control room'), findsWidgets);
  });

  testWidgets('the screen meets the accessibility guidelines', (tester) async {
    await show(tester);
    await expectAccessible(tester);
  });

  testWidgets('it survives twice the font size', (tester) async {
    useLargeText(tester);
    await show(tester);
  });
}
