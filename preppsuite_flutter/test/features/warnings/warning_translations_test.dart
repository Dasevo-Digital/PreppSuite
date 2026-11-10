import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:preppsuite_flutter/features/warnings/application/bbk_client.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_ingest.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_translations.dart';
import 'package:preppsuite_flutter/features/warnings/presentation/warning_speech.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

/// The BBK sends each warning with its official translations, and the app
/// kept only the German (#357).
void main() {
  Map<String, Object?> info(
    String language, {
    required String headline,
    String? instruction,
  }) => {
    'language': language,
    'event': 'event $language',
    'headline': headline,
    'description': 'description $language',
    'instruction': ?instruction,
    'area': [
      {'areaDesc': 'Landkreis Regensburg'},
    ],
  };

  final detail = jsonEncode({
    'sender': 'Landratsamt',
    'info': [
      info('de-DE', headline: 'Abkochgebot', instruction: 'Wasser abkochen.'),
      info('DE-LS', headline: 'Wasser kochen', instruction: 'Erst kochen.'),
      info('en', headline: 'Boil water notice', instruction: 'Boil water.'),
      info('es', headline: 'Hervir el agua', instruction: 'Hierva el agua.'),
      info('tr', headline: 'Suyu kaynatın', instruction: 'Suyu kaynatın.'),
    ],
  });

  const compact = BbkRawWarning(
    id: 'mow.DE-BY-R-W001',
    startDate: '2026-11-10T08:00:00+01:00',
    severity: 'Severe',
    eventTitleDe: 'Abkochgebot',
    raw: {},
  );

  Future<BbkRawWarning> detailed() => BbkClient(
    httpClient: MockClient(
      (_) async => http.Response.bytes(utf8.encode(detail), 200),
    ),
  ).fetchDetails(compact);

  test('the detail keeps the German and every translation', () async {
    final warning = await detailed();

    expect(warning.instruction, 'Wasser abkochen.');
    expect(
      warning.translations!.keys,
      unorderedEquals(['de-ls', 'en', 'es', 'tr']),
    );
    expect(warning.translations!['es']!.headline, 'Hervir el agua');
    expect(warning.translations!['es']!.instruction, 'Hierva el agua.');
  });

  group('stored', () {
    late AppDatabase db;
    setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
    tearDown(() => db.close());

    Future<Warning> stored() async =>
        (await db.warningsBySource('bbk'))[compact.id]!;

    test('and shown in the app language, German where there is none', () async {
      await WarningIngest(db).ingestBbk([await detailed()], countryCode: 'DE');
      final warning = await stored();

      expect(warning.textIn('es').headline, 'Hervir el agua');
      expect(warning.textIn('en').instruction, 'Boil water.');
      expect(warning.textIn('de').headline, 'Abkochgebot');
      expect(warning.isTranslatedFor('de'), isFalse);
      expect(warning.translationIn('de-LS')!.headline, 'Wasser kochen');
      expect(warningSpeechText(warning, language: 'es'), contains('Hierva'));
    });

    test(
      'a warning stored before is translated without a second notice',
      () async {
        // As 2.9.5 stored it: the German detail, no translations.
        const older = BbkRawWarning(
          id: 'mow.DE-BY-R-W001',
          startDate: '2026-11-10T08:00:00+01:00',
          severity: 'Severe',
          eventTitleDe: 'Abkochgebot',
          raw: {},
          instruction: 'Wasser abkochen.',
        );
        await WarningIngest(db).ingestBbk([older], countryCode: 'DE');
        await db.markWarningsNotified([await stored()]);
        expect((await stored()).translationsJson, isNull);

        final newsworthy = await WarningIngest(
          db,
        ).ingestBbk([await detailed()], countryCode: 'DE');

        expect(newsworthy, isEmpty);
        final warning = await stored();
        expect(warning.translationIn('es'), isNotNull);
        expect(warning.notified, isTrue, reason: 'already told stays told');
      },
    );

    test('a later pass without the detail keeps what it had', () async {
      await WarningIngest(db).ingestBbk([await detailed()], countryCode: 'DE');
      await WarningIngest(db).ingestBbk([compact], countryCode: 'DE');

      expect((await stored()).translationIn('es'), isNotNull);
    });
  });

  test('the stored form is the same for the same translations', () {
    const a = WarningText(event: 'e', headline: 'h');
    const b = WarningText(event: 'f', headline: 'g', instruction: 'i');
    expect(
      encodeWarningTranslations({'tr': a, 'en': b}),
      encodeWarningTranslations({'en': b, 'tr': a}),
    );
    expect(decodeWarningTranslations('not json'), isEmpty);
  });

  test('schema 28 adds the column to an older database', () async {
    final db = AppDatabase.forTesting(
      NativeDatabase.memory(
        setup: (raw) {
          raw
            ..execute(
              'CREATE TABLE "warnings" ("source" TEXT NOT NULL, '
              '"external_id" TEXT NOT NULL, "country_code" TEXT NOT NULL, '
              '"region_key" TEXT NULL, "severity" TEXT NOT NULL, '
              '"event_type" TEXT NOT NULL, "headline" TEXT NOT NULL, '
              '"description" TEXT NULL, "instruction" TEXT NULL, '
              '"area_description" TEXT NULL, "sender_contact" TEXT NULL, '
              '"polygons_json" TEXT NULL, "effective" INTEGER NOT NULL, '
              '"expires" INTEGER NULL, "sent" INTEGER NOT NULL, '
              '"updated_at" INTEGER NOT NULL, '
              '"notified" INTEGER NOT NULL DEFAULT 0 '
              'CHECK ("notified" IN (0, 1)), '
              'PRIMARY KEY ("source", "external_id"))',
            )
            ..execute(
              "INSERT INTO warnings (source, external_id, country_code, "
              "severity, event_type, headline, effective, sent, updated_at) "
              "VALUES ('bbk', 'w', 'DE', 'severe', 'Hochwasser', "
              "'Hochwasser', 1, 1, 1)",
            )
            ..execute('PRAGMA user_version = 27');
        },
      ),
    );
    addTearDown(db.close);

    final warning = (await db.warningsBySource('bbk'))['w']!;
    expect(warning.headline, 'Hochwasser');
    expect(warning.translationsJson, isNull);
  });
}
