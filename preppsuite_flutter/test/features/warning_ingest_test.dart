import 'package:drift/drift.dart'
    show ApplyInterceptor, BatchedStatements, QueryExecutor, QueryInterceptor;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/warnings/application/bbk_client.dart';
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
  }) {
    return BbkRawWarning(
      id: id,
      startDate: startDate,
      severity: severity,
      eventTitleDe: 'Testwarnung',
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
