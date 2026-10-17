import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/phrasebook/application/phrasebook.dart';
import 'package:preppsuite_flutter/features/translator/application/translator_catalogue.dart';

/// Read against a cut of Mozilla's real model list, taken 2026-10-17.
void main() {
  final fixture = File(
    'test/fixtures/translations_models_sample.json',
  ).readAsStringSync();
  final catalogue = TranslatorCatalogue.parse(fixture);
  const de = PhraseLanguage.de;
  const en = PhraseLanguage.en;

  test('each direction gets its newest released version', () {
    expect(catalogue.packs[const TranslatorDirection(de, en)]!.version, '2.0');
    expect(catalogue.packs[const TranslatorDirection(en, de)]!.version, '2.1');
    expect(
      catalogue
          .packs[const TranslatorDirection(en, PhraseLanguage.ar)]!
          .version,
      '2.2',
    );
  });

  test('a version held back for Nightly is passed over', () {
    // Turkish to English has a 1.0a1 only Nightly gets, and a 1.0.
    expect(
      catalogue
          .packs[const TranslatorDirection(PhraseLanguage.tr, en)]!
          .version,
      '1.0',
    );
  });

  test('English to Russian: the desktop version here, the phone one there', () {
    // The only direction with no record for everyone: 2.0 is filtered to
    // the desktop, 2.1 to Android, and a 2.1a1 to Nightly.
    const enRu = TranslatorDirection(en, PhraseLanguage.ru);
    expect(catalogue.packs[enRu]!.version, '2.0');
    final phone = TranslatorCatalogue.parse(fixture, android: true);
    expect(phone.packs[enRu]!.version, '2.1');
    // Everything without a filter is the same on both.
    expect(phone.packs[const TranslatorDirection(de, en)]!.version, '2.0');
  });

  test('a filter this app cannot read keeps the record out', () {
    // The fixture has a German to English 5.0 behind a version check.
    expect(catalogue.packs[const TranslatorDirection(de, en)]!.version, '2.0');
    expect(
      releasedFor("env.version|versionCompare('150.0') >= 0", android: false),
      isFalse,
    );
  });

  test('filters are read as a released Firefox reads them', () {
    const nightly = "env.channel == 'default' || env.channel == 'nightly'";
    const desktop = "env.appinfo.OS != 'Android' || env.channel != 'release'";
    const phone = "env.appinfo.OS == 'Android' ";
    expect(releasedFor(null, android: false), isTrue);
    expect(releasedFor('', android: true), isTrue);
    expect(releasedFor(nightly, android: false), isFalse);
    expect(releasedFor(nightly, android: true), isFalse);
    expect(releasedFor(desktop, android: false), isTrue);
    expect(releasedFor(desktop, android: true), isFalse);
    expect(releasedFor(phone, android: true), isTrue);
    expect(releasedFor(phone, android: false), isFalse);
    expect(
      releasedFor(
        "env.appinfo.OS == 'Android' && env.channel == 'release'",
        android: true,
      ),
      isTrue,
    );
    expect(releasedFor(7, android: false), isFalse);
  });

  test('a pack has its three files, checked and addressed', () {
    final pack = catalogue.packs[const TranslatorDirection(de, en)]!;
    expect([for (final f in pack.files) f.kind], TranslatorFileKind.values);
    final model = pack.files.first;
    expect(model.name, 'model.deen.intgemm.alphas.bin');
    expect(model.size, 31561787);
    expect(model.sha256, hasLength(64));
    expect(
      model.url.toString(),
      startsWith('https://firefox-settings-attachments.cdn.mozilla.net/'),
    );
    expect(pack.size, greaterThan(30000000));
  });

  test('nothing between two languages neither of which is English', () {
    expect(
      catalogue.packs.keys.where((d) => d.from != en && d.to != en),
      isEmpty,
    );
  });

  test('a file name with a path in it is not taken', () {
    // The fixture carries a 9.9 whose model is "../evil.bin"; if it were
    // read, German to English would be 9.9.
    expect(catalogue.packs[const TranslatorDirection(de, en)]!.version, '2.0');
  });

  test('versions order as Mozilla means them', () {
    final sorted = ['1.0', '2.1', '1.0a1', '2.0', '1.1', '2.0a1']
      ..sort(compareModelVersions);
    expect(sorted, ['1.0a1', '1.0', '1.1', '2.0a1', '2.0', '2.1']);
  });

  test('a translation goes through English unless one side is English', () {
    expect(directionsFor(de, en).map((d) => d.code), ['deen']);
    expect(directionsFor(en, PhraseLanguage.uk).map((d) => d.code), ['enuk']);
    expect(directionsFor(de, PhraseLanguage.ar).map((d) => d.code), [
      'deen',
      'enar',
    ]);
    expect(directionsFor(de, de), isEmpty);
  });

  test('something that is not a model list is refused', () {
    expect(
      () => TranslatorCatalogue.parse('<html>captive portal</html>'),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => TranslatorCatalogue.parse('{"nothing": 1}'),
      throwsA(isA<TranslatorCatalogueException>()),
    );
  });
}
