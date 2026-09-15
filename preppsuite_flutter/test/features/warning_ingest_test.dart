import 'package:drift/drift.dart'
    show ApplyInterceptor, BatchedStatements, QueryExecutor, QueryInterceptor;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/warnings/application/bbk_client.dart';
import 'package:preppsuite_flutter/features/warnings/application/dwd_areas.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_ingest.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

/// Counts what actually reaches SQLite.
///
/// The point of this is the shape of the traffic, not its result: a poll
/// that writes the right rows one statement at a time is still a poll that
/// costs a transaction and an fsync per warning, four times a day, in a
/// background isolate on a phone on battery. Nothing about the stored data
/// would show that, so it is counted here instead.
class _Counting extends QueryInterceptor {
  final selects = <String>[];
  final writes = <String>[];
  var batches = 0;

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    if (statement.contains('warnings')) selects.add(statement);
    return super.runSelect(executor, statement, args);
  }

  @override
  Future<int> runInsert(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    if (statement.contains('warnings')) writes.add(statement);
    return super.runInsert(executor, statement, args);
  }

  @override
  Future<int> runUpdate(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    if (statement.contains('warnings')) writes.add(statement);
    return super.runUpdate(executor, statement, args);
  }

  @override
  Future<void> runBatched(
    QueryExecutor executor,
    BatchedStatements statements,
  ) {
    batches++;
    return super.runBatched(executor, statements);
  }
}

void main() {
  late AppDatabase db;
  late WarningIngest ingest;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    ingest = WarningIngest(db);
  });
  tearDown(() => db.close());

  BbkRawWarning raw({
    String id = 'mow.DE-HE-MKK-W220-20260811-001',
    String severity = 'Moderate',
    String startDate = '2026-08-11T08:30:54+02:00',
    String title = 'Testwarnung',
  }) {
    return BbkRawWarning(
      id: id,
      startDate: startDate,
      severity: severity,
      eventTitleDe: title,
      raw: const {},
    );
  }

  test('a new warning is newsworthy', () async {
    final result = await ingest.ingestBbk([raw()], countryCode: 'DE');

    expect(result, hasLength(1));
  });

  test('the same warning reissued unchanged is not', () async {
    // The feeds republish constantly; announcing every repeat is how a
    // warning channel gets muted.
    await ingest.ingestBbk([raw()], countryCode: 'DE');
    final second = await ingest.ingestBbk([raw()], countryCode: 'DE');

    expect(second, isEmpty);
  });

  test('a rewritten warning at the same severity is not', () async {
    await ingest.ingestBbk([raw()], countryCode: 'DE');
    final second = await ingest.ingestBbk([
      raw(startDate: '2026-08-11T09:30:54+02:00'),
    ], countryCode: 'DE');

    expect(second, isEmpty);
  });

  test(
    'a warning escalating to a higher severity is newsworthy again',
    () async {
      // The one kind of update worth a second notification.
      await ingest.ingestBbk([raw(severity: 'Moderate')], countryCode: 'DE');
      final escalated = await ingest.ingestBbk([
        raw(severity: 'Extreme', startDate: '2026-08-11T09:30:54+02:00'),
      ], countryCode: 'DE');

      expect(escalated, hasLength(1));

      final stored = await db.findWarning('bbk', raw().id);
      expect(stored!.severity, 'extreme');
      expect(
        stored.notified,
        isFalse,
        reason: 'escalation must re-arm the announcement',
      );
    },
  );

  test('a warning dropping in severity is not announced again', () async {
    await ingest.ingestBbk([raw(severity: 'Extreme')], countryCode: 'DE');
    final calmer = await ingest.ingestBbk([
      raw(severity: 'Minor', startDate: '2026-08-11T09:30:54+02:00'),
    ], countryCode: 'DE');

    expect(calmer, isEmpty);
  });

  group('placing a warning whose id names no state', () {
    // KATWARN's ids carry none, so these came out unplaced — and unplaced
    // means "concerns everyone". An earthquake near Worms was pinned to
    // the top of a household in Braunschweig because of it.
    final areas = DwdAreas.parse("""
# name;district;state
Kreis Alzey-Worms;07331;RP
Kreis Bad Dürkheim;07332;RP
Rhein-Pfalz-Kreis;07338;RP
Kreis Göttingen;03159;NI
Kreis Kassel;06633;HE
""");

    BbkRawWarning katwarn({String? areaDescription, String? title}) =>
        raw(
          id: 'kat.6aa2cd02995efd5eae120ffb_public_topics',
          title: title ?? 'Testwarnung',
        ).withDetails(
          description: null,
          instruction: null,
          areaDescription: areaDescription,
          senderContact: null,
          polygons: const [],
        );

    Future<String?> storedRegionKey() async {
      final rows = await db.select(db.warnings).get();
      return rows.single.regionKey;
    }

    test('the area description places it in its state', () async {
      await ingest.ingestBbk(
        [
          katwarn(
            areaDescription:
                'Teile von LKr. Alzey-Worms, LKr. Bad Dürkheim, '
                'Rhein-Pfalz-Kreis und Umland',
          ),
        ],
        countryCode: 'DE',
        areas: areas,
      );

      expect(await storedRegionKey(), 'RP');
    });

    test('without the table it stays unplaced', () async {
      // A table that will not load must not cost the warning itself.
      await ingest.ingestBbk(
        [katwarn(areaDescription: 'Rhein-Pfalz-Kreis')],
        countryCode: 'DE',
      );

      expect(await storedRegionKey(), isNull);
    });

    test('an area spanning two states stays unplaced', () async {
      await ingest.ingestBbk(
        [katwarn(areaDescription: 'Kreis Kassel und Kreis Göttingen')],
        countryCode: 'DE',
        areas: areas,
      );

      expect(await storedRegionKey(), isNull);
    });

    test('a state in the id is trusted over the prose', () async {
      // Order of trust: the id is structured, the description is a
      // sentence. Only the warnings with nothing in the id fall through.
      await ingest.ingestBbk(
        [
          raw(id: 'mow.DE-HE-MKK-W220-20260811-001').withDetails(
            description: null,
            instruction: null,
            areaDescription: 'Rhein-Pfalz-Kreis',
            senderContact: null,
            polygons: const [],
          ),
        ],
        countryCode: 'DE',
        areas: areas,
      );

      expect(await storedRegionKey(), 'HE');
    });

    test('a precise per-Kreis fetch outranks both', () async {
      await ingest.ingestBbk(
        [katwarn(areaDescription: 'Rhein-Pfalz-Kreis')],
        countryCode: 'DE',
        regionKeyOverride: '03101',
        areas: areas,
      );

      expect(await storedRegionKey(), '03101');
    });

    group('and whose area description cannot be placed either', () {
      // The real case, live on 2026-09-14: a severe drinking-water alert
      // for Lauterbach in Hesse reached a household in Braunschweig.
      // "Teile von Lauterbach" is genuinely unplaceable -- there is a
      // Lauterbach in Baden-Wurttemberg and one in Thuringia, and the
      // Hessian one is filed under a name of its own -- but the title
      // says who warned, and that name is in the table exactly once.
      final withLauterbach = DwdAreas.parse("""
# name;district;state
Gemeinde Lauterbach;08325;BW
Gemeinde Lauterbach;16063;TH
Stadt Lauterbach (Hessen);06535;HE
Vogelsbergkreis;06535;HE
""");

      test('the authority that issued it places it', () async {
        await ingest.ingestBbk(
          [
            katwarn(
              areaDescription: 'Teile von Lauterbach',
              title:
                  'Vogelsbergkreis meldet: Warnung Trinkwasserunfall. '
                  'Gultig ab 14.09.2026, 15:29.',
            ),
          ],
          countryCode: 'DE',
          areas: withLauterbach,
        );

        expect(await storedRegionKey(), 'HE');
      });

      test('an issuer that is not a place leaves it unplaced', () async {
        // "Erdbebendienst Sudwest meldet: ..." -- a seismic service is
        // not in the warncell table, and a warning nobody can place
        // concerns everyone, which is the safe error here.
        await ingest.ingestBbk(
          [
            katwarn(
              areaDescription: 'Teile von Lauterbach',
              title:
                  'Erdbebendienst Sudwest meldet: Schwaches Erdbeben bei '
                  'Worms',
            ),
          ],
          countryCode: 'DE',
          areas: withLauterbach,
        );

        expect(await storedRegionKey(), isNull);
      });

      test('the area description still wins over the issuer', () async {
        // Where it applies beats who said it, whenever both answer.
        await ingest.ingestBbk(
          [
            katwarn(
              areaDescription: 'Stadt Lauterbach (Hessen)',
              title: 'Vogelsbergkreis meldet: Warnung',
            ),
          ],
          countryCode: 'DE',
          areas: withLauterbach,
        );

        expect(await storedRegionKey(), 'HE');
      });

      test('a warning stored unplaced is placed on a later pass', () async {
        // Otherwise the fix only helps the next warning, and the one
        // already on somebody's screen keeps the reading that put it
        // there.
        await ingest.ingestBbk(
          [
            katwarn(
              areaDescription: 'Teile von Lauterbach',
              title: 'Vogelsbergkreis meldet: Warnung Trinkwasserunfall.',
            ),
          ],
          countryCode: 'DE',
        );
        expect(await storedRegionKey(), isNull, reason: 'no table yet');

        final again = await ingest.ingestBbk(
          [
            katwarn(
              areaDescription: 'Teile von Lauterbach',
              title: 'Vogelsbergkreis meldet: Warnung Trinkwasserunfall.',
            ),
          ],
          countryCode: 'DE',
          areas: withLauterbach,
        );

        expect(await storedRegionKey(), 'HE');
        expect(
          again,
          isEmpty,
          reason: 'nobody is notified twice because the app learned geography',
        );
      });

      test('a key already known is never overwritten by the issuer', () async {
        await ingest.ingestBbk(
          [katwarn(areaDescription: 'Stadt Lauterbach (Hessen)')],
          countryCode: 'DE',
          areas: withLauterbach,
        );
        expect(await storedRegionKey(), 'HE');

        await ingest.ingestBbk(
          [
            katwarn(
              areaDescription: 'Gemeinde Lauterbach',
              title: 'Vogelsbergkreis meldet: Warnung',
            ),
          ],
          countryCode: 'DE',
          areas: withLauterbach,
        );

        expect(await storedRegionKey(), 'HE');
      });
    });
  });

  group('bbkIssuerFromTitle', () {
    test('reads the authority out of a KATWARN title', () {
      expect(
        bbkIssuerFromTitle(
          'Vogelsbergkreis meldet: Warnung Trinkwasserunfall. '
          'Gultig ab 14.09.2026, 15:29.',
        ),
        'Vogelsbergkreis',
      );
    });

    test('keeps a multi-word authority whole', () {
      expect(
        bbkIssuerFromTitle('Erdbebendienst Sudwest meldet: Schwaches Erdbeben'),
        'Erdbebendienst Sudwest',
      );
    });

    test('a title from any other source names no authority', () {
      // Every other feed writes a plain event title, so they fall out
      // here rather than having to be excluded by source.
      expect(bbkIssuerFromTitle('Abkochgebot Trinkwasser - Ehrenberg'), isNull);
      expect(bbkIssuerFromTitle('Sturmboeen'), isNull);
    });

    test('the word alone is not an authority', () {
      expect(bbkIssuerFromTitle('meldet: etwas'), isNull);
    });
  });

  group('bbkRegionFromId', () {
    test('reads the state code from a mowas id', () {
      expect(bbkRegionFromId('mow.DE-HE-KS-SE106-20260811'), 'HE');
    });

    test('reads the state code from an lhp id', () {
      expect(bbkRegionFromId('lhp.LHP.NW.nw86768'), 'NW');
    });

    test('refuses a pair of capitals that is not a state', () {
      // A wrong region is worse than none: none shows the warning to
      // everyone, a wrong one hides it from the people it concerns.
      expect(bbkRegionFromId('foo.XY.bar'), isNull);
    });
  });

  group('what reaches the database', () {
    late _Counting counter;
    late AppDatabase counted;
    late WarningIngest countedIngest;

    setUp(() {
      counter = _Counting();
      counted = AppDatabase.forTesting(
        NativeDatabase.memory().interceptWith(counter),
      );
      countedIngest = WarningIngest(counted);
    });

    tearDown(() => counted.close());

    test(
      'twenty warnings cost one query and one batch, not twenty of each',
      () async {
        final many = [
          for (var i = 0; i < 20; i++)
            raw(
              id: 'mow.DE-HE-MKK-W220-20260811-${i.toString().padLeft(3, '0')}',
            ),
        ];

        final newsworthy = await countedIngest.ingestBbk(
          many,
          countryCode: 'DE',
        );

        expect(newsworthy, hasLength(20), reason: 'all of them are new');
        // One lookup for the whole source. It used to be one per warning,
        // and the poll service asked the same question a second time.
        expect(counter.selects, hasLength(1));
        // And one transaction for the writes rather than twenty.
        expect(counter.batches, 1);
        expect(counter.writes, isEmpty, reason: 'written inside the batch');
        expect(await counted.watchAllWarnings().first, hasLength(20));
      },
    );

    test('a poll that changes nothing writes nothing at all', () async {
      final many = [
        for (var i = 0; i < 5; i++) raw(id: 'mow.DE-HE-MKK-W220-20260811-00$i'),
      ];
      await countedIngest.ingestBbk(many, countryCode: 'DE');

      counter.batches = 0;
      counter.selects.clear();
      final again = await countedIngest.ingestBbk(many, countryCode: 'DE');

      expect(again, isEmpty);
      expect(counter.selects, hasLength(1));
      // Nothing moved, so there is nothing to write — not even an empty
      // transaction.
      expect(counter.batches, 0);
    });

    test('retiring what dropped out of the feed is one transaction', () async {
      final many = [
        for (var i = 0; i < 6; i++) raw(id: 'mow.DE-HE-MKK-W220-20260811-00$i'),
      ];
      await countedIngest.ingestBbk(many, countryCode: 'DE');

      counter.batches = 0;
      final retired = await counted.expireMissingWarnings(
        source: 'bbk',
        seenExternalIds: {'mow.DE-HE-MKK-W220-20260811-000'},
      );

      expect(retired, 5);
      expect(counter.batches, 1);
    });

    test('a sweep with nothing to retire opens no transaction', () async {
      await countedIngest.ingestBbk([raw()], countryCode: 'DE');

      counter.batches = 0;
      final retired = await counted.expireMissingWarnings(
        source: 'bbk',
        seenExternalIds: {raw().id},
      );

      expect(retired, 0);
      expect(counter.batches, 0);
    });
  });
}
