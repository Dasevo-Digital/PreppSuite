import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:preppsuite_flutter/features/knowledge/application/tesseract_data.dart';
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

/// Text recognition data on an Android device, in memory.
class _Data extends DownloadedTesseractData {
  _Data(this.present);

  final Set<String> present;
  final fetched = <String>[];

  @override
  Future<bool> has(TesseractLanguage language) async =>
      present.contains(language.code);

  @override
  Stream<int> install(TesseractLanguage language) async* {
    yield language.size ~/ 2;
    fetched.add(language.code);
    present.add(language.code);
    yield language.size;
  }
}

/// The system's Tesseract on Linux, with some language packages.
class _System implements TesseractData {
  const _System(this.present);

  final Set<String> present;

  @override
  Future<bool> has(TesseractLanguage language) async =>
      present.contains(language.code);
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

  test('Tesseract reads a language with its own data, or Latin letters '
      'with German and English, or not at all', () {
    expect(
      tesseractRecognitionLanguagesFor(PhraseLanguage.de, hasData: false),
      ['de-DE', 'en-US'],
    );
    expect(
      tesseractRecognitionLanguagesFor(PhraseLanguage.ru, hasData: true),
      ['ru-RU', 'en-US'],
    );
    expect(
      tesseractRecognitionLanguagesFor(PhraseLanguage.pl, hasData: false),
      ['de-DE', 'en-US'],
    );
    expect(
      tesseractRecognitionLanguagesFor(PhraseLanguage.ar, hasData: false),
      isNull,
    );
    expect(readsWithTesseractOn(TargetPlatform.android), isTrue);
    expect(readsWithTesseractOn(TargetPlatform.linux), isTrue);
    expect(readsWithTesseractOn(TargetPlatform.macOS), isFalse);
    expect(readsWithTesseractOn(TargetPlatform.windows), isFalse);
  });

  group('on the translator screen', () {
    late _Recognizer recognizer;
    late List<ImageSource> picked;
    late List<List<String>> read;

    Future<void> pump(
      WidgetTester tester, {
      PhraseLanguage from = PhraseLanguage.fr,
      TextRecognitionSupport support = TextRecognitionSupport.available,
      String text = 'Où est l’hôpital ?',
      TesseractData? data,
    }) async {
      tester.view.physicalSize = const Size(500, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      recognizer = _Recognizer(support);
      picked = [];
      read = [];
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
            photoTextReaderProvider.overrideWithValue((bytes, languages) async {
              read.add(languages);
              return text;
            }),
            tesseractDataProvider.overrideWithValue(data ?? _Data({'fra'})),
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

      // Android reads with Tesseract, here with the French data present.
      expect(recognizer.asked.single, ['fr-FR', 'en-US']);
      expect(read.single, ['fr-FR', 'en-US']);
      expect(picked, [ImageSource.gallery]);
      expect(find.text('Où est l’hôpital ?'), findsOneWidget);
      expect(find.textContaining('Aus einem Foto gelesen'), findsOneWidget);
    });

    testWidgets('Russian without its data: the data is offered, fetched, '
        'and the photo read with it', (tester) async {
      final data = _Data({});
      await pump(tester, from: PhraseLanguage.ru, data: data);

      await tester.tap(find.text('Text aus Foto'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Um Русский von einem Foto zu lesen'),
        findsOne,
      );
      // No reading without it: Cyrillic is not German letters.
      expect(find.text('Ohne Daten lesen'), findsNothing);

      await tester.tap(find.text('Laden'));
      await tester.pumpAndSettle();
      expect(data.fetched, ['rus']);

      await tester.tap(find.text('Foto auswählen'));
      await tester.pumpAndSettle();
      expect(read.single, ['ru-RU', 'en-US']);
    });

    testWidgets('a Latin-script language can be read without its data', (
      tester,
    ) async {
      final data = _Data({});
      await pump(tester, from: PhraseLanguage.pl, data: data);

      await tester.tap(find.text('Text aus Foto'));
      await tester.pumpAndSettle();
      expect(find.textContaining('ł, ş oder ñ'), findsOne);

      await tester.tap(find.text('Ohne Daten lesen'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Foto auswählen'));
      await tester.pumpAndSettle();

      expect(data.fetched, isEmpty);
      expect(read.single, ['de-DE', 'en-US']);
    });

    testWidgets('cancelling the offer takes no photo', (tester) async {
      await pump(tester, from: PhraseLanguage.ar, data: _Data({}));

      await tester.tap(find.text('Text aus Foto'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Abbrechen'));
      await tester.pumpAndSettle();

      expect(picked, isEmpty);
    });

    testWidgets('on Linux the package to install is named', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      try {
        await pump(tester, from: PhraseLanguage.uk, data: const _System({}));

        await tester.tap(find.text('Text aus Foto'));
        await tester.pumpAndSettle();

        expect(
          find.textContaining('sudo apt install tesseract-ocr-ukr'),
          findsOne,
        );
        expect(picked, isEmpty);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('Windows without the language pack says which one', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      try {
        await pump(tester, support: TextRecognitionSupport.needsLanguagePack);

        await tester.tap(find.text('Text aus Foto'));
        await tester.pumpAndSettle();

        expect(recognizer.asked.single, ['fr-FR', 'de-DE', 'en-US']);
        expect(find.textContaining('für Français ist keines da'), findsOne);
        expect(picked, isEmpty);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('a photo without text says so and leaves the field', (
      tester,
    ) async {
      await pump(tester, text: '  ');

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
