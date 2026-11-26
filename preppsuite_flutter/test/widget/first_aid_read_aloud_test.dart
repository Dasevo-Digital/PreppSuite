import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/first_aid/application/first_aid_providers.dart';
import 'package:preppsuite_flutter/features/first_aid/application/step_speech.dart';
import 'package:preppsuite_flutter/features/first_aid/presentation/first_aid_guide_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';

/// A voice that is still speaking until the test says it is done --
/// and whose stop, as on iOS, does not end the reading itself.
class _Voice implements StepSpeech {
  final readings = <Completer<void>>[];
  var stopped = 0;

  @override
  Future<bool> isAvailable(String languageCode) async => true;

  @override
  Future<void> speak(String text, {required String languageCode}) {
    final reading = Completer<void>();
    readings.add(reading);
    return reading.future;
  }

  @override
  Future<void> stop() async => stopped++;
}

/// "Schritte vorlesen" on a guide (#412).
void main() {
  late _Voice voice;

  Future<void> show(WidgetTester tester) async {
    voice = _Voice();
    tester.view.physicalSize = const Size(420, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          installedFirstAidPackProvider.overrideWith(
            (ref) async => InstalledFirstAidPack.none,
          ),
          firstAidSpeechProvider.overrideWithValue(voice),
        ],
        child: const MaterialApp(
          locale: Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: FirstAidGuideScreen(guideId: 'choking'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('it offers reading again once the voice has finished', (
    tester,
  ) async {
    // It stayed on "stop" after the last step: nothing told it that the
    // voice had ended.
    await show(tester);
    await tester.tap(find.byTooltip('Schritte vorlesen'));
    await tester.pump();
    expect(find.byTooltip('Vorlesen beenden'), findsOneWidget);

    voice.readings.single.complete();
    await tester.pump();

    expect(find.byTooltip('Schritte vorlesen'), findsOneWidget);
    expect(find.byTooltip('Vorlesen beenden'), findsNothing);
  });

  testWidgets('stopping it stops the voice', (tester) async {
    await show(tester);
    await tester.tap(find.byTooltip('Schritte vorlesen'));
    await tester.pump();

    await tester.tap(find.byTooltip('Vorlesen beenden'));
    await tester.pump();

    expect(voice.stopped, 1);
    expect(find.byTooltip('Schritte vorlesen'), findsOneWidget);
  });

  testWidgets('the end of a stopped reading leaves the next one alone', (
    tester,
  ) async {
    await show(tester);
    await tester.tap(find.byTooltip('Schritte vorlesen'));
    await tester.pump();
    await tester.tap(find.byTooltip('Vorlesen beenden'));
    await tester.pump();

    // Started again before the first reading's end arrived.
    await tester.tap(find.byTooltip('Schritte vorlesen'));
    await tester.pump();
    final [stopped, current] = voice.readings;

    stopped.complete();
    await tester.pump();
    expect(find.byTooltip('Vorlesen beenden'), findsOneWidget);

    current.complete();
    await tester.pump();
    expect(find.byTooltip('Schritte vorlesen'), findsOneWidget);
  });
}
