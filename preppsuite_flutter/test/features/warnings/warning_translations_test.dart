import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart' show TextDirection;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:preppsuite_flutter/core/notification_service.dart';
import 'package:preppsuite_flutter/features/warnings/application/bbk_client.dart';
import 'package:preppsuite_flutter/features/warnings/application/meteoalarm_client.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_filter.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_ingest.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_poll_service.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_region_filter.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_translations.dart';
import 'package:preppsuite_flutter/features/warnings/presentation/warning_speech.dart';
import 'package:preppsuite_flutter/features/warnings/presentation/warning_translation_sections.dart';
import 'package:preppsuite_flutter/local_db/database.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The BBK sends each warning with its official translations, and the app
/// kept only the German (#357). Shaped after what the BBK sent on
/// 2026-11-11: MoWaS names the event in a translation's headline, leaves
/// the description German and translates what to do; DWD translates it
/// all.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const germanHeadline =
      'Entwarnung: Stromausfall in Teilen von Hückelhoven / Erkelenz';
  const germanDescription =
      'Dies ist die Entwarnung zur Warnung &quot;Stromausfall&quot;.'
      '<br/>Der Strom ist wieder da.';

  Map<String, Object?> mowasInfo(
    String language, {
    required String headline,
    required String instruction,
  }) => {
    'language': language,
    'event': 'Gefahreninformation',
    'headline': headline,
    'description': germanDescription,
    'instruction': instruction,
    'area': [
      {'areaDesc': 'Stadt Hückelhoven'},
      {'areaDesc': 'Stadt Erkelenz'},
    ],
  };

  final mowasDetail = jsonEncode({
    'sender': 'Kreis Heinsberg',
    'msgType': 'Cancel',
    'info': [
      mowasInfo(
        'de',
        headline: germanHeadline,
        instruction: 'Es besteht keine Gefahr.',
      ),
      mowasInfo(
        'de-LS',
        headline: 'Stromausfall',
        instruction: 'Es besteht keine Gefahr.',
      ),
      mowasInfo(
        'en',
        headline: 'Power outage',
        instruction: 'There is no danger.',
      ),
      mowasInfo(
        'es',
        headline: 'Interrupción del suministro eléctrico',
        instruction: 'No hay ningún peligro.',
      ),
      mowasInfo(
        'ar',
        headline: 'انقطاع الكهرباء',
        instruction: 'لا يوجد خطر.',
      ),
    ],
  });

  const mowas = BbkRawWarning(
    id: 'mow.DE-NW-ERK-SE056-20261111-56-002',
    startDate: '2026-11-11T08:00:00+01:00',
    severity: 'Minor',
    eventTitleDe: germanHeadline,
    raw: {},
    messageType: 'Cancel',
  );

  Map<String, Object?> dwdInfo(
    String language,
    String event,
    String headline,
    String description,
    String instruction,
  ) => {
    'language': language,
    'event': event,
    'headline': headline,
    'description': description,
    'instruction': instruction,
  };

  final dwdDetail = jsonEncode({
    'msgType': 'Alert',
    'info': [
      dwdInfo(
        'de-DE',
        'FROST',
        'Amtliche WARNUNG vor FROST',
        'Es tritt leichter Frost auf.',
        'Pflanzen abdecken.',
      ),
      dwdInfo(
        'es',
        'heladas',
        'Aviso oficial de HELADAS',
        'Se producen heladas leves.',
        'Cubra las plantas.',
      ),
    ],
  });

  const dwd = BbkRawWarning(
    id: 'dwd.2.49.0.0.276.0.DWD.PVW.1762840000000.frost',
    startDate: '2026-11-11T08:00:00+01:00',
    severity: 'Minor',
    eventTitleDe: 'Amtliche WARNUNG vor FROST',
    raw: {},
    messageType: 'Alert',
  );

  Future<BbkRawWarning> detailed(BbkRawWarning warning, String body) =>
      BbkClient(
        httpClient: MockClient(
          (_) async => http.Response.bytes(utf8.encode(body), 200),
        ),
      ).fetchDetails(warning);

  String allClear(String title) => 'Fin del aviso: $title';

  test('a MoWaS translation keeps the event, not a headline, and only what '
      'differs from the German', () async {
    final warning = await detailed(mowas, mowasDetail);

    expect(warning.instruction, 'Es besteht keine Gefahr.');
    expect(warning.messageType, 'Cancel');
    expect(
      warning.translations!.keys,
      unorderedEquals(['de-ls', 'en', 'es', 'ar']),
    );
    final es = warning.translations!['es']!;
    expect(es.event, 'Interrupción del suministro eléctrico');
    expect(es.headline, isNull);
    expect(es.description, isNull, reason: 'the German, repeated');
    expect(es.instruction, 'No hay ningún peligro.');
    // Leichte Sprache differs only in its short headline.
    final easy = warning.translations!['de-ls']!;
    expect(easy.event, 'Stromausfall');
    expect(easy.instruction, isNull);
  });

  test('DWD translates its headline and its text', () async {
    final warning = await detailed(dwd, dwdDetail);
    final es = warning.translations!['es']!;

    expect(es.headline, 'Aviso oficial de HELADAS');
    expect(es.description, 'Se producen heladas leves.');
    expect(es.instruction, 'Cubra las plantas.');
  });

  group('stored', () {
    late AppDatabase db;
    setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
    tearDown(() => db.close());

    Future<Warning> stored(String id) async =>
        (await db.warningsBySource('bbk'))[id]!;

    Future<Warning> storedMowas() async {
      await WarningIngest(
        db,
      ).ingestBbk([await detailed(mowas, mowasDetail)], countryCode: 'DE');
      return stored(mowas.id);
    }

    test('the title keeps the German headline, after the event in the '
        'app language, and says it is an all-clear', () async {
      final warning = await storedMowas();

      expect(warning.isAllClear, isTrue);
      expect(
        warning.textIn('es').headline,
        'Interrupción del suministro eléctrico – $germanHeadline',
      );
      // The German "Entwarnung:" is left off behind the app's word (#367).
      expect(
        warning.titleIn('es', allClear: allClear),
        'Fin del aviso: Interrupción del suministro eléctrico – '
        'Stromausfall in Teilen von Hückelhoven / Erkelenz',
      );
      expect(warning.titleIn('de', allClear: allClear), germanHeadline);
      expect(warning.textIn('es').instruction, 'No hay ningún peligro.');
      expect(
        warning.textIn('es').description,
        warning.description,
        reason: 'the description stays German, as the BBK sent it',
      );
    });

    test('an all-clear without a translation says it once', () async {
      const older = BbkRawWarning(
        id: 'mow.DE-NW-ERK-SE056-20261111-56-002',
        startDate: '2026-11-11T08:00:00+01:00',
        severity: 'Minor',
        eventTitleDe: germanHeadline,
        raw: {},
        messageType: 'Cancel',
      );
      await WarningIngest(db).ingestBbk([older], countryCode: 'DE');
      final warning = await stored(older.id);

      expect(
        warning.titleIn('en', allClear: (title) => 'All clear: $title'),
        'All clear: Stromausfall in Teilen von Hückelhoven / Erkelenz',
      );
      expect(warning.titleIn('de', allClear: allClear), germanHeadline);
      expect(warning.textIn('en').headline, germanHeadline);
    });

    test('kept small: no copy of the German text', () async {
      final warning = await storedMowas();

      expect(warning.translationsJson, isNot(contains('Strom ist wieder')));
      expect(warning.translationsJson, isNot(contains('Gefahreninformation')));
      expect(
        decodeWarningTranslations(warning.translationsJson).keys,
        unorderedEquals(['de-ls', 'en', 'es', 'ar']),
      );
    });

    test(
      'the notification names the place, not "Gefahreninformation"',
      () async {
        final warning = await storedMowas();

        expect(warningNotificationTitle(warning, 'es'), startsWith('Fin del'));
        expect(warningNotificationTitle(warning, 'de'), germanHeadline);
        expect(
          warningNotificationBody(warning, 'es'),
          'Stadt Hückelhoven, Stadt Erkelenz',
        );
        expect(
          warningNotificationBody(warning, 'de'),
          'Stadt Hückelhoven, Stadt Erkelenz',
        );
      },
    );

    test('read in one language: the German where the translation is '
        'partial, the translation where it is whole', () async {
      final partial = await storedMowas();
      expect(partial.isWhollyTranslatedFor('es'), isFalse);
      expect(
        warningSpeechText(partial, language: 'es'),
        contains('Es besteht keine Gefahr.'),
      );
      expect(
        warningSpeechText(partial, language: 'es'),
        isNot(contains('peligro')),
      );

      await WarningIngest(
        db,
      ).ingestBbk([await detailed(dwd, dwdDetail)], countryCode: 'DE');
      final whole = await stored(dwd.id);
      expect(whole.isWhollyTranslatedFor('es'), isTrue);
      expect(
        warningSpeechText(whole, language: 'es'),
        'Aviso oficial de HELADAS\n'
        'Se producen heladas leves.\n'
        'Cubra las plantas.',
      );
    });

    test('a search finds the title on screen', () async {
      final warning = await storedMowas();
      bool finds(String query) => WarningFilter(query: query).matches(
        warning,
        regions: const WarningRegionFilter(countryCode: 'DE'),
        now: DateTime.utc(2026, 11, 11, 9),
      );

      expect(finds('suministro'), isTrue);
      expect(finds('power outage'), isTrue);
      expect(finds('Hückelhoven'), isTrue);
      expect(finds('Waldbrand'), isFalse);
    });

    test(
      'a warning stored before is translated without a second notice',
      () async {
        // As 2.9.5 stored it: the German detail, no translations.
        const older = BbkRawWarning(
          id: 'mow.DE-NW-ERK-SE056-20261111-56-002',
          startDate: '2026-11-11T08:00:00+01:00',
          severity: 'Minor',
          eventTitleDe: germanHeadline,
          raw: {},
          instruction: 'Es besteht keine Gefahr.',
        );
        await WarningIngest(db).ingestBbk([older], countryCode: 'DE');
        await db.markWarningsNotified([await stored(older.id)]);
        expect((await stored(older.id)).translationsJson, isNull);
        expect((await stored(older.id)).messageType, isNull);

        final newsworthy = await WarningIngest(
          db,
        ).ingestBbk([await detailed(mowas, mowasDetail)], countryCode: 'DE');

        expect(newsworthy, isEmpty);
        final warning = await stored(older.id);
        expect(warning.translationIn('es'), isNotNull);
        expect(warning.messageType, 'Cancel');
        expect(warning.notified, isTrue, reason: 'already told stays told');
      },
    );

    test('the type alone arrives with the map feed', () async {
      const compact = BbkRawWarning(
        id: 'mow.DE-NW-ERK-SE056-20261111-56-002',
        startDate: '2026-11-11T08:00:00+01:00',
        severity: 'Minor',
        eventTitleDe: germanHeadline,
        raw: {},
      );
      await WarningIngest(db).ingestBbk([compact], countryCode: 'DE');
      await WarningIngest(db).ingestBbk([mowas], countryCode: 'DE');

      expect((await stored(mowas.id)).isAllClear, isTrue);
    });

    test('a later pass without the detail keeps what it had', () async {
      await storedMowas();
      await WarningIngest(db).ingestBbk([mowas], countryCode: 'DE');

      expect((await stored(mowas.id)).translationIn('es'), isNotNull);
    });
  });

  test('the map feed and the dashboard say which kind of message', () async {
    final client = BbkClient(
      httpClient: MockClient((request) async {
        final path = request.url.path;
        final body = path.contains('dashboard')
            ? [
                {
                  'id': 'mow.a',
                  'sent': '2026-11-11T08:00:00+01:00',
                  'payload': {
                    'data': {'headline': 'Entwarnung', 'msgType': 'Cancel'},
                  },
                },
              ]
            : path.contains('mowas')
            ? [
                {
                  'id': 'mow.b',
                  'startDate': '2026-11-11T08:00:00+01:00',
                  'type': 'Update',
                  'i18nTitle': {'de': '1. AKTUALISIERUNG'},
                },
              ]
            : <Object>[];
        return http.Response.bytes(utf8.encode(jsonEncode(body)), 200);
      }),
    );

    final all = await client.fetchAll();
    expect(all.warnings.single.messageType, 'Update');
    final dashboard = await client.fetchDashboard('05370');
    expect(dashboard.single.messageType, 'Cancel');
  });

  test('the stored form is the same for the same translations', () {
    const a = WarningTranslation(event: 'e');
    const b = WarningTranslation(headline: 'g', instruction: 'i');
    expect(
      encodeWarningTranslations({'tr': a, 'en': b}),
      encodeWarningTranslations({'en': b, 'tr': a}),
    );
    expect(decodeWarningTranslations('not json'), isEmpty);
    expect(decodeWarningTranslations('{"en": {}}'), isEmpty);
  });

  test('each part runs in the direction of its own words', () {
    expect(warningTextDirection('لا يوجد خطر.'), TextDirection.rtl);
    expect(
      warningTextDirection('Dies ist die Entwarnung.'),
      TextDirection.ltr,
    );
  });

  test('missing details are asked for before missing translations', () async {
    SharedPreferences.setMockInitialValues({});
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final sent = DateTime.utc(2026, 11, 11, 6);

    BbkRawWarning raw(String id) => BbkRawWarning(
      id: id,
      startDate: sent.toIso8601String(),
      severity: 'Severe',
      eventTitleDe: 'Warnung $id',
      raw: const {},
    );

    // As 2.9.5 left them: 40 with their detail and no translations, then
    // one whose detail request had failed.
    await db.upsertWarnings([
      for (var i = 0; i < 40; i++)
        WarningsCompanion.insert(
          source: 'bbk',
          externalId: 'dwd.$i',
          countryCode: 'DE',
          severity: 'severe',
          eventType: 'Sturm',
          headline: 'Sturm',
          instruction: const Value('Drinnen bleiben.'),
          effective: sent,
          sent: sent,
          updatedAt: sent,
          notified: const Value(true),
        ),
      WarningsCompanion.insert(
        source: 'bbk',
        externalId: 'mow.late',
        countryCode: 'DE',
        severity: 'severe',
        eventType: 'Gefahr',
        headline: 'Gefahr',
        effective: sent,
        sent: sent,
        updatedAt: sent,
        notified: const Value(true),
      ),
    ]);

    final bbk = _Bbk([
      for (var i = 0; i < 40; i++) raw('dwd.$i'),
      raw('mow.late'),
    ]);
    await WarningPollService(
      database: db,
      bbkClient: bbk,
      meteoAlarmClient: _NoMeteo(),
    ).poll(countryCode: 'DE');

    expect(bbk.asked.first, 'mow.late');
    expect(
      bbk.asked.length,
      1 + WarningPollService.translationRetriesPerPoll,
    );
    final late = (await db.warningsBySource('bbk'))['mow.late']!;
    expect(late.instruction, isNotNull);
  });

  test('schema 29 lets go of the translations 2.9.6 kept whole', () async {
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
              '"polygons_json" TEXT NULL, "translations_json" TEXT NULL, '
              '"effective" INTEGER NOT NULL, '
              '"expires" INTEGER NULL, "sent" INTEGER NOT NULL, '
              '"updated_at" INTEGER NOT NULL, '
              '"notified" INTEGER NOT NULL DEFAULT 0 '
              'CHECK ("notified" IN (0, 1)), '
              'PRIMARY KEY ("source", "external_id"))',
            )
            ..execute(
              "INSERT INTO warnings (source, external_id, country_code, "
              "severity, event_type, headline, translations_json, "
              "effective, sent, updated_at) "
              "VALUES ('bbk', 'w', 'DE', 'minor', 'Entwarnung: Strom', "
              "'Entwarnung: Strom', "
              "'{\"en\":{\"event\":\"Gefahreninformation\","
              "\"headline\":\"Power outage\"}}', 1, 1, 1)",
            )
            ..execute('PRAGMA user_version = 28');
        },
      ),
    );
    addTearDown(db.close);

    final warning = (await db.warningsBySource('bbk'))['w']!;
    expect(warning.headline, 'Entwarnung: Strom');
    expect(warning.translationsJson, isNull);
    expect(warning.messageType, isNull);
    expect(warning.textIn('en').headline, 'Entwarnung: Strom');
  });
}

class _Bbk extends BbkClient {
  _Bbk(this.feed);
  final List<BbkRawWarning> feed;
  final asked = <String>[];

  @override
  Future<BbkFetchResult> fetchAll() async =>
      BbkFetchResult(warnings: feed, complete: true);

  @override
  Future<List<BbkRawWarning>> fetchDashboard(String kreisSchluessel) async =>
      const [];

  @override
  Future<BbkRawWarning> fetchDetails(BbkRawWarning warning) async {
    asked.add(warning.id);
    return warning.withDetails(
      instruction: 'Drinnen bleiben.',
      translations: const {'en': WarningTranslation(instruction: 'Stay in.')},
    );
  }
}

class _NoMeteo extends MeteoAlarmClient {
  @override
  Future<MeteoAlarmFeed> fetchCountry(
    String countrySlug, {
    String? knownStamp,
  }) => throw StateError('offline');
}
