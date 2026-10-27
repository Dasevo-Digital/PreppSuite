import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart'
    show DriftWrappedException, CouldNotRollBackException;
import 'package:preppsuite_flutter/local_db/database.dart';
import 'package:preppsuite_flutter/core/emergency_access.dart';
import 'package:preppsuite_flutter/core/error_display.dart';
import 'package:preppsuite_flutter/core/error_log.dart';
import 'package:preppsuite_flutter/features/settings/presentation/error_log_card.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';

/// Errors are kept on the device, and a failed part of a screen says so
/// (#141).
void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('errorlog'));
  tearDown(() => dir.deleteSync(recursive: true));

  for (final background in [false, true]) {
    test(
      'SQLite bind values never enter the log (background: $background)',
      () async {
        final db = AppDatabase.forTesting(
          background
              ? NativeDatabase.createInBackground(
                  File('${dir.path}/test.sqlite'),
                )
              : NativeDatabase.memory(),
        );
        addTearDown(db.close);
        await db.customStatement(
          'CREATE TABLE private_values (data TEXT CHECK(length(data) < 3))',
        );
        Object? failure;
        try {
          await db.customStatement(
            'INSERT INTO private_values (data) VALUES (?)',
            ['private-probe-value'],
          );
        } catch (error) {
          failure = error;
        }
        expect(failure, isNotNull);
        final log = ErrorLog.forTesting()..attach(dir);
        log.record(failure!, StackTrace.current);
        log.record(
          DriftWrappedException(message: 'private-probe-value', cause: failure),
          StackTrace.current,
        );
        log.record(
          CouldNotRollBackException(failure, StackTrace.current, failure),
          StackTrace.current,
        );
        final text = await log.read();
        expect(text, contains('SqliteException(code:'));
        expect(text, isNot(contains('private-probe-value')));
        expect(text, isNot(contains('INSERT INTO')));
        expect(text, isNot(contains('parameters')));
      },
    );
  }

  test('an entry says when, what and where, without the home folder', () {
    final entry = ErrorLog.format(
      const FileSystemException('cannot open', '/Users/jemand/Library/x.db'),
      StackTrace.fromString(
        '#0 open (package:preppsuite_flutter/a.dart:1)\n'
        '#1 load (/Users/jemand/code/b.dart:2)',
      ),
      at: DateTime.utc(2026, 10, 9, 12),
      context: 'widgets library',
      home: '/Users/jemand',
    );
    expect(entry, startsWith('=== 2026-10-09T12:00:00.000Z · '));
    expect(entry, contains('widgets library'));
    expect(entry, contains('FileSystemException'));
    expect(entry, contains('~/Library/x.db'));
    expect(entry, isNot(contains('/Users/jemand')));
    expect(entry, contains('#0 open'));
  });

  test('entries before the folder is known are not lost', () async {
    final log = ErrorLog.forTesting();
    log.record(StateError('early'), null);
    log.attach(dir);
    log.record(StateError('later'), null);
    final text = await log.read();
    expect(text, contains('early'));
    expect(text, contains('later'));
    expect(await log.count(), 2);
    await log.clear();
    expect(await log.count(), 0);
  });

  test('the log stays small, and cut between whole entries', () async {
    final log = ErrorLog.forTesting()..attach(dir);
    for (var i = 0; i < 400; i++) {
      log.record(StateError('Fehler $i ${'x' * 200}'), null);
    }
    final text = await log.read();
    expect(text.length, lessThanOrEqualTo(ErrorLog.maxBytes));
    expect(text, startsWith('=== '));
    expect(text, contains('Fehler 399'));
    expect(text, isNot(contains('Fehler 0 ')));
  });

  testWidgets('a part that fails says so and leads to the emergency help', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (_) => friendlyErrorWidget(
              FlutterErrorDetails(exception: StateError('kaputt')),
            ),
          ),
        ),
      ),
    );
    expect(
      find.textContaining('konnte nicht angezeigt werden'),
      findsOneWidget,
    );
    await tester.tap(find.text('Notfall: 112 und Erste Hilfe'));
    await tester.pumpAndSettle();
    expect(find.byType(EmergencyAccessScreen), findsOneWidget);
  });

  testWidgets('and still says something with nothing above it', (
    tester,
  ) async {
    await tester.pumpWidget(
      friendlyErrorWidget(FlutterErrorDetails(exception: StateError('x'))),
    );
    expect(
      find.text('Dieser Teil der App konnte nicht angezeigt werden.'),
      findsOneWidget,
    );
  });

  testWidgets('the settings card counts the entries', (tester) async {
    final log = ErrorLog.forTesting()..attach(dir);
    log.record(StateError('eins'), null);
    await tester.runAsync(() async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: ErrorLogCard(log: log)),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump();
    expect(find.textContaining('Ein Eintrag'), findsOneWidget);
    expect(find.text('Teilen'), findsOneWidget);
  });
}
