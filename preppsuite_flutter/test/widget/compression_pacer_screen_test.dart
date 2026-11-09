import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/first_aid/application/compression_pacer.dart';
import 'package:preppsuite_flutter/features/first_aid/presentation/compression_pacer_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';

class _Clock implements Stopwatch {
  Duration now = Duration.zero;

  @override
  Duration get elapsed => now;

  @override
  void start() {}

  @override
  void stop() {}

  @override
  void reset() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The call to breathe has to be readable whole, at every text size, on the
/// smallest window the app runs in (#337). It used to sit in a box 40 high.
void main() {
  const pacer = CompressionPacer();
  final breaths = pacer.beatInterval * 30 + const Duration(seconds: 1);

  Future<(_Clock, AppLocalizations)> start(
    WidgetTester tester, {
    Size size = const Size(360, 640),
    double textScale = 1,
    Locale locale = const Locale('de'),
  }) async {
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearAllTestValues);

    final clock = _Clock();
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: CompressionPacerScreen(stopwatch: clock),
      ),
    );
    await tester.pump();
    final l10n = await AppLocalizations.delegate.load(locale);
    final startButton = find.text(l10n.pacerStart);
    await tester.ensureVisible(startButton);
    await tester.pump();
    await tester.tap(startButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    return (clock, l10n);
  }

  Future<void> stop(WidgetTester tester, AppLocalizations l10n) async {
    await tester.tap(find.text(l10n.pacerStop));
    await tester.pump();
  }

  Future<void> windTo(WidgetTester tester, _Clock clock, Duration to) async {
    clock.now = to;
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 16));
  }

  for (final (size, scale) in const [
    (Size(360, 640), 1.0),
    (Size(360, 640), 1.25),
    (Size(360, 640), 2.0),
    (Size(360, 800), 1.5),
    (Size(360, 800), 2.0),
  ]) {
    for (final locale in const [Locale('de'), Locale('en'), Locale('es')]) {
      testWidgets('breaths at $size, text $scale, ${locale.languageCode}', (
        tester,
      ) async {
        final (clock, l10n) = await start(
          tester,
          size: size,
          textScale: scale,
          locale: locale,
        );
        await windTo(tester, clock, breaths);

        expect(tester.takeException(), isNull);
        final call = tester.getRect(find.text(l10n.pacerBreathe));
        final hint = tester.getRect(find.text(l10n.pacerBreatheHint));
        final depth = tester.getRect(find.text(l10n.pacerDepth));
        expect(call.bottom, lessThanOrEqualTo(hint.top + 1));
        expect(
          hint.bottom,
          lessThanOrEqualTo(depth.top + 1),
          reason: 'it used to lie across the text on depth',
        );
        await stop(tester, l10n);
      });
    }
  }

  testWidgets('while it runs, Stop stays on the screen', (tester) async {
    final (clock, l10n) = await start(tester, textScale: 2);
    await windTo(tester, clock, breaths);
    final button = tester.getRect(find.text(l10n.pacerStop));
    expect(button.bottom, lessThanOrEqualTo(640));
    await stop(tester, l10n);
  });

  testWidgets('tapping the dial during the pause starts the next round', (
    tester,
  ) async {
    final (clock, l10n) = await start(tester);
    await windTo(tester, clock, breaths);
    expect(find.text('4 s'), findsOneWidget);

    await tester.tap(find.text(l10n.pacerBreatheHint));
    await windTo(tester, clock, breaths + const Duration(milliseconds: 20));

    expect(find.text('1'), findsOneWidget, reason: 'compression one again');
    await stop(tester, l10n);
  });

  testWidgets('a tap while pressing does nothing to the count', (tester) async {
    final (clock, l10n) = await start(tester);
    await windTo(tester, clock, pacer.beatInterval * 4);
    expect(find.text('5'), findsOneWidget);

    await tester.tap(find.text('5'));
    await windTo(tester, clock, pacer.beatInterval * 4);

    expect(find.text('5'), findsOneWidget);
    await stop(tester, l10n);
  });

  testWidgets('every beat changes the circle, for those who cannot hear it', (
    tester,
  ) async {
    Color? circle(String count) =>
        (tester
                    .widget<DecoratedBox>(
                      find
                          .ancestor(
                            of: find.text(count),
                            matching: find.byType(DecoratedBox),
                          )
                          .first,
                    )
                    .decoration
                as BoxDecoration)
            .color;

    final (clock, l10n) = await start(tester);
    await windTo(tester, clock, Duration.zero);
    final first = circle('1');
    await windTo(tester, clock, pacer.beatInterval);
    final second = circle('2');
    await windTo(tester, clock, pacer.beatInterval * 2);
    final third = circle('3');

    expect(second, isNot(first));
    expect(third, first);
    await stop(tester, l10n);
  });
}
