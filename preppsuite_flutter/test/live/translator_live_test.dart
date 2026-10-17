import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/phrasebook/application/phrasebook.dart';
import 'package:preppsuite_flutter/features/translator/application/translator_catalogue.dart';
import 'package:preppsuite_flutter/features/translator/application/translator_engine.dart';
import 'package:preppsuite_flutter/features/translator/application/translator_store.dart';

/// Translates with the real engine and real models (#182).
///
/// Needs the library built (`native/translate/build_macos.sh`) and a
/// folder holding Mozilla's `deen/` and `ende/` files, named in
/// PREPPSUITE_TRANSLATOR_MODELS. Without both it is skipped: the models
/// are 70 MB and not in the repository.
void main() {
  final models = Platform.environment['PREPPSUITE_TRANSLATOR_MODELS'];
  final skip = models == null
      ? 'set PREPPSUITE_TRANSLATOR_MODELS to a folder with deen/ and ende/'
      : !translatorAvailable
      ? 'the translator library is not built'
      : null;

  InstalledTranslatorPack pack(PhraseLanguage from, PhraseLanguage to) {
    final code = '${from.name}${to.name}';
    final dir = '$models/$code';
    return InstalledTranslatorPack(
      direction: TranslatorDirection(from, to),
      version: 'test',
      size: 0,
      modelPath: '$dir/model.$code.intgemm.alphas.bin',
      lexPath: Directory(dir)
          .listSync()
          .map((f) => f.path)
          .firstWhere((p) => p.contains('/lex.')),
      vocabPath: '$dir/vocab.$code.spm',
    );
  }

  test(
    'Mozilla offers every direction, on the desktop and on Android',
    () async {
      for (final android in [false, true]) {
        final catalogue = await TranslatorCatalogue.fetch(android: android);
        final wanted = [
          for (final language in PhraseLanguage.values)
            if (language != PhraseLanguage.en) ...[
              TranslatorDirection(language, PhraseLanguage.en),
              TranslatorDirection(PhraseLanguage.en, language),
            ],
        ];
        for (final direction in wanted) {
          final pack = catalogue.packs[direction];
          expect(pack, isNotNull, reason: '$direction, android: $android');
          stdout.writeln(
            '${android ? 'android' : 'desktop'} $direction ${pack!.version} '
            '${(pack.size / 1e6).toStringAsFixed(1)} MB',
          );
        }
      }
    },
    skip: Platform.environment['PREPPSUITE_TEST_NETWORK'] == null
        ? 'set PREPPSUITE_TEST_NETWORK=1 to ask Mozilla for the list'
        : null,
  );

  test('German to English', () async {
    final out = await translateText(
      'Bitte rufen Sie einen Krankenwagen.',
      [pack(PhraseLanguage.de, PhraseLanguage.en)],
    );
    expect(out, 'Please call an ambulance.');
  }, skip: skip);

  test('there and back by way of English', () async {
    final out = await translateText('Wo gibt es Trinkwasser?', [
      pack(PhraseLanguage.de, PhraseLanguage.en),
      pack(PhraseLanguage.en, PhraseLanguage.de),
    ]);
    expect(out, contains('Trinkwasser'));
  }, skip: skip);

  test('a model that is not there is an error, not a crash', () async {
    final broken = InstalledTranslatorPack(
      direction: const TranslatorDirection(
        PhraseLanguage.de,
        PhraseLanguage.en,
      ),
      version: 'test',
      size: 0,
      modelPath: '/nonexistent/model.bin',
      lexPath: '/nonexistent/lex.bin',
      vocabPath: '/nonexistent/vocab.spm',
    );
    await expectLater(
      translateText('Hallo', [broken]),
      throwsA(isA<TranslatorException>()),
    );
  }, skip: !translatorAvailable ? 'the translator library is not built' : null);
}
