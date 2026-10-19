import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/first_aid/application/step_speech.dart';
import 'package:preppsuite_flutter/features/phrasebook/presentation/phrase_display.dart';
import 'package:preppsuite_flutter/features/warnings/presentation/warning_speech.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:preppsuite_flutter/local_db/database.dart';
import 'package:preppsuite_flutter/model/categories.dart';

class _FakeSpeech implements StepSpeech {
  _FakeSpeech(this.voices);

  final Set<String> voices;
  final spoken = <(String, String)>[];
  var stopped = 0;

  @override
  Future<bool> isAvailable(String languageCode) async =>
      voices.contains(languageCode);

  @override
  Future<void> speak(String text, {required String languageCode}) async =>
      spoken.add((text, languageCode));

  @override
  Future<void> stop() async => stopped++;
}

void main() {
  Warning warning({String? description, String? instruction}) => Warning(
    source: 'bbk',
    externalId: 'w1',
    countryCode: 'DE',
    severity: 'severe',
    eventType: 'Unwetter',
    headline: 'Unwetterwarnung vor Orkanböen',
    description: description,
    instruction: instruction,
    effective: DateTime.utc(2026),
    sent: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
    notified: false,
  );

  Future<void> pump(
    WidgetTester tester,
    _FakeSpeech speech,
    Warning warning,
    WarningSource source,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [phraseSpeechProvider.overrideWithValue(speech)],
        child: MaterialApp(
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SpeakWarningButton(warning: warning, source: source),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  test('reads the publisher\'s text: headline, description, instruction', () {
    expect(
      warningSpeechText(
        warning(description: 'Böen bis 120 km/h.', instruction: ' '),
      ),
      'Unwetterwarnung vor Orkanböen\nBöen bis 120 km/h.',
    );
  });

  testWidgets('a German warning is read with a German voice, '
      'whatever the app language', (tester) async {
    final speech = _FakeSpeech({'de-DE'});
    await pump(
      tester,
      speech,
      warning(instruction: 'Bleiben Sie im Haus.'),
      WarningSource.bbk,
    );

    await tester.tap(find.text('Leer en voz alta'));
    await tester.pump();
    expect(speech.spoken, [
      ('Unwetterwarnung vor Orkanböen\nBleiben Sie im Haus.', 'de-DE'),
    ]);

    await tester.tap(find.text('Dejar de leer'));
    await tester.pump();
    expect(speech.stopped, 1);
    expect(find.text('Leer en voz alta'), findsOneWidget);
  });

  testWidgets('a MeteoAlarm warning is read in English', (tester) async {
    final speech = _FakeSpeech({'de-DE', 'en-GB'});
    await pump(tester, speech, warning(), WarningSource.meteoalarm);

    await tester.tap(find.byType(TextButton));
    await tester.pump();
    expect(speech.spoken.single.$2, 'en-GB');
  });

  testWidgets('without a voice for the language there is no button', (
    tester,
  ) async {
    await pump(tester, _FakeSpeech({'en-GB'}), warning(), WarningSource.bbk);

    expect(find.byType(TextButton), findsNothing);
  });
}
