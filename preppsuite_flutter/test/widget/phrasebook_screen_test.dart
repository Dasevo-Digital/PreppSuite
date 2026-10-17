import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/first_aid/application/step_speech.dart';
import 'package:preppsuite_flutter/features/phrasebook/presentation/phrase_display.dart';
import 'package:preppsuite_flutter/features/phrasebook/presentation/phrasebook_screen.dart';
import 'package:preppsuite_flutter/features/translator/application/translator_catalogue.dart';
import 'package:preppsuite_flutter/features/translator/application/translator_providers.dart';
import 'package:preppsuite_flutter/features/translator/application/translator_store.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';

import 'accessibility.dart';

/// A device with an English and a German voice, as the phrasebook asks
/// for them, and nothing else.
class _Voices implements StepSpeech {
  final spoken = <(String, String)>[];

  @override
  Future<bool> isAvailable(String languageCode) async =>
      languageCode == 'en-GB' || languageCode == 'de-DE';

  @override
  Future<void> speak(String text, {required String languageCode}) async =>
      spoken.add((text, languageCode));

  @override
  Future<void> stop() async {}
}

/// No packs, and never the app's real folder.
class _NoPacks extends TranslatorStore {
  @override
  Future<List<InstalledTranslatorPack>> installed() async => const [];
}

void main() {
  late _Voices voices;

  Future<void> pump(
    WidgetTester tester, {
    Locale locale = const Locale('de'),
    Size size = const Size(400, 900),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    voices = _Voices();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          phraseSpeechProvider.overrideWithValue(voices),
          translatorAvailableProvider.overrideWithValue(true),
          translatorStoreProvider.overrideWithValue(_NoPacks()),
          // Never Mozilla's list from a test.
          translatorCatalogueProvider.overrideWith(
            (ref) async => const TranslatorCatalogue({}),
          ),
        ],
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const PhrasebookScreen(),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('a German reader starts with English beside German', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('Ich spreche Ihre Sprache nicht.'), findsOneWidget);
    expect(find.text("I don't speak your language."), findsOneWidget);
    expect(
      find.textContaining('nicht von Muttersprachlern geprüft'),
      findsOneWidget,
    );
  });

  testWidgets('a Spanish reader starts with German', (tester) async {
    await pump(tester, locale: const Locale('es'));
    expect(find.text('No hablo su idioma.'), findsOneWidget);
    expect(find.text('Ich spreche Ihre Sprache nicht.'), findsOneWidget);
  });

  testWidgets('Arabic is set right to left', (tester) async {
    await pump(tester);
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    // The menu scrolls; the last entries are built only once reached.
    final arabicEntry = find.text('العربية', skipOffstage: false).last;
    await tester.ensureVisible(arabicEntry);
    await tester.pumpAndSettle();
    await tester.tap(arabicEntry);
    await tester.pumpAndSettle();

    final arabic = tester.widget<Text>(find.text('لا أتكلم لغتك.'));
    expect(arabic.textDirection, TextDirection.rtl);
  });

  testWidgets('search finds a sentence by either language', (tester) async {
    await pump(tester);
    await tester.enterText(find.byType(TextField), 'krankenwagen');
    await tester.pump();

    expect(find.text('Bitte rufen Sie einen Krankenwagen.'), findsOneWidget);
    expect(find.text('Please call an ambulance.'), findsOneWidget);
    expect(find.text('Ich spreche Ihre Sprache nicht.'), findsNothing);

    await tester.enterText(find.byType(TextField), 'xyzzy');
    await tester.pump();
    expect(find.text('Kein Satz gefunden.'), findsOneWidget);
  });

  testWidgets('a sentence is shown large, and closed again', (tester) async {
    await pump(tester);
    await tester.scrollUntilVisible(
      find.text('Hilfe!'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Hilfe!'));
    await tester.pumpAndSettle();

    final large = tester.widget<Text>(find.text('Help!').last);
    expect(large.style?.fontSize, greaterThan(30));
    await tester.tap(find.byTooltip('Schließen'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('a sentence is read out where there is a voice (#189)', (
    tester,
  ) async {
    await pump(tester);
    await tester.pump();

    final speak = find.byTooltip('Vorlesen');
    expect(speak, findsWidgets);
    await tester.tap(speak.first);
    await tester.pump();
    expect(voices.spoken.single, ("I don't speak your language.", 'en-GB'));
  });

  testWidgets('and not where there is none', (tester) async {
    await pump(tester);
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    final persian = find.text('فارسی', skipOffstage: false).last;
    await tester.ensureVisible(persian);
    await tester.pumpAndSettle();
    await tester.tap(persian);
    await tester.pumpAndSettle();

    expect(find.byTooltip('Vorlesen'), findsNothing);
  });

  testWidgets('a sentence that is not here goes to the translator (#190)', (
    tester,
  ) async {
    await pump(tester);
    await tester.enterText(find.byType(TextField), 'Wo ist der Bahnhof?');
    await tester.pump();

    await tester.tap(find.text('„Wo ist der Bahnhof?“ übersetzen'));
    await tester.pumpAndSettle();

    expect(find.text('Übersetzer'), findsOneWidget);
    final input = tester.widget<TextField>(find.byType(TextField));
    expect(input.controller!.text, 'Wo ist der Bahnhof?');
    // From the reader's language into the one the phrasebook showed.
    expect(find.text('Deutsch'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
  });

  testWidgets('at twice the text size nothing overflows', (tester) async {
    useLargeText(tester);
    await pump(tester, size: const Size(360, 640));
    await tester.drag(find.byType(ListView), const Offset(0, -2000));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('is accessible', (tester) async {
    await pump(tester);
    await expectAccessible(tester);
  });
}
