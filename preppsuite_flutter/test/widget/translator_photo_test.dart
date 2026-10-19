import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:preppsuite_flutter/features/knowledge/application/text_recognition.dart';
import 'package:preppsuite_flutter/features/phrasebook/application/phrasebook.dart';
import 'package:preppsuite_flutter/features/translator/application/photo_text.dart';
import 'package:preppsuite_flutter/features/translator/application/translator_catalogue.dart';
import 'package:preppsuite_flutter/features/translator/application/translator_providers.dart';
import 'package:preppsuite_flutter/features/translator/application/translator_store.dart';
import 'package:preppsuite_flutter/features/translator/presentation/translator_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';

class _Recognizer implements TextRecognizer {
  _Recognizer(this.answer);

  final TextRecognitionSupport answer;
  final asked = <List<String>?>[];

  @override
  Future<TextRecognitionSupport> support({List<String>? languages}) async {
    asked.add(languages);
    return answer;
  }

  @override
  Future<String> recognize(PageImage page, {List<String>? languages}) async =>
      '';
}

class _NoPacks extends TranslatorStore {
  @override
  Future<List<InstalledTranslatorPack>> installed() async => const [];
}

void main() {
  group('a photo made ready for the engine', () {
    test('is shrunk to 4000 pixels on its long side, in BGRA', () {
      final red = img.Image(width: 5000, height: 100)
        ..clear(img.ColorRgb8(255, 0, 0));
      final page = photoPage(Uint8List.fromList(img.encodePng(red)))!;

      expect(page.width, 4000);
      expect(page.height, 80);
      expect(page.bgra.length, 4000 * 80 * 4);
      expect(page.bgra.sublist(0, 4), [0, 0, 255, 255]);
    });

    test('is nothing when the bytes are no image', () {
      expect(photoPage(Uint8List.fromList([1, 2, 3])), isNull);
    });
  });

  test('a Latin-script language falls back to German and English, '
      'another script does not', () {
    expect(recognitionLanguagesFor(PhraseLanguage.fr), [
      'fr-FR',
      'de-DE',
      'en-US',
    ]);
    expect(recognitionLanguagesFor(PhraseLanguage.de), ['de-DE', 'en-US']);
    expect(recognitionLanguagesFor(PhraseLanguage.uk), ['uk-UA']);
  });

  test('Tesseract reads Latin letters only; the system engines are asked', () {
    expect(readsScriptOn(TargetPlatform.android, PhraseLanguage.pl), isTrue);
    expect(readsScriptOn(TargetPlatform.android, PhraseLanguage.ru), isFalse);
    expect(readsScriptOn(TargetPlatform.linux, PhraseLanguage.ar), isFalse);
    expect(readsScriptOn(TargetPlatform.macOS, PhraseLanguage.ru), isTrue);
    expect(readsScriptOn(TargetPlatform.windows, PhraseLanguage.fa), isTrue);
  });

  group('on the translator screen', () {
    late _Recognizer recognizer;
    late List<ImageSource> picked;

    Future<void> pump(
      WidgetTester tester, {
      PhraseLanguage from = PhraseLanguage.fr,
      TextRecognitionSupport support = TextRecognitionSupport.available,
      String read = 'Où est l’hôpital ?',
    }) async {
      tester.view.physicalSize = const Size(500, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      recognizer = _Recognizer(support);
      picked = [];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            translatorAvailableProvider.overrideWithValue(true),
            translatorStoreProvider.overrideWithValue(_NoPacks()),
            translatorCatalogueProvider.overrideWith(
              (ref) async => TranslatorCatalogue({}),
            ),
            textRecognizerProvider.overrideWithValue(recognizer),
            translatorPhotoPickerProvider.overrideWithValue((source) async {
              picked.add(source);
              return Uint8List(1);
            }),
            photoTextReaderProvider.overrideWithValue(
              (bytes, languages) async => read,
            ),
          ],
          child: MaterialApp(
            locale: const Locale('de'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: TranslatorScreen(
              initialFrom: from,
              initialTo: PhraseLanguage.de,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('the text read from a photo lands in the field, marked', (
      tester,
    ) async {
      await pump(tester);

      await tester.tap(find.text('Text aus Foto'));
      await tester.pumpAndSettle();
      // A phone: camera or library.
      await tester.tap(find.text('Foto auswählen'));
      await tester.pumpAndSettle();

      expect(recognizer.asked.single, ['fr-FR', 'de-DE', 'en-US']);
      expect(picked, [ImageSource.gallery]);
      expect(find.text('Où est l’hôpital ?'), findsOneWidget);
      expect(find.textContaining('Aus einem Foto gelesen'), findsOneWidget);
    });

    testWidgets('a script the engine cannot read is said before any photo '
        'is taken', (tester) async {
      await pump(tester, from: PhraseLanguage.ru);

      await tester.tap(find.text('Text aus Foto'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Schrift kann die Texterkennung'), findsOne);
      expect(picked, isEmpty);
    });

    testWidgets('Windows without the language pack says which one', (
      tester,
    ) async {
      await pump(tester, support: TextRecognitionSupport.needsLanguagePack);

      await tester.tap(find.text('Text aus Foto'));
      await tester.pumpAndSettle();

      expect(find.textContaining('für Français ist keines da'), findsOne);
      expect(picked, isEmpty);
    });

    testWidgets('a photo without text says so and leaves the field', (
      tester,
    ) async {
      await pump(tester, read: '  ');

      await tester.tap(find.text('Text aus Foto'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Foto aufnehmen'));
      await tester.pumpAndSettle();

      expect(picked, [ImageSource.camera]);
      expect(find.text('Auf dem Foto wurde kein Text erkannt.'), findsOne);
      expect(find.textContaining('Aus einem Foto gelesen'), findsNothing);
    });
  });
}
