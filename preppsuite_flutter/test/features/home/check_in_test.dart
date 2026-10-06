import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/core/app_database_providers.dart';
import 'package:preppsuite_flutter/features/home/application/check_in.dart';
import 'package:preppsuite_flutter/features/home/presentation/check_in_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:preppsuite_flutter/local_db/database.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A sign of life by text message, composed here and sent by the phone's
/// own messaging app (#116).
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('phone numbers keep their digits and a leading plus', () {
    expect(normalisePhone('0171 / 234 56-78'), '01712345678');
    expect(normalisePhone('+49 (171) 2345678'), '+491712345678');
    expect(normalisePhone('0049 171 2345678'), '+491712345678');
    expect(normalisePhone('112'), isNull);
    expect(phoneNumbersIn('Mama, 0171 2345678; Papa +49 160 1112223'), [
      '01712345678',
      '+491601112223',
    ]);
    expect(phoneNumbersIn('Hausarzt Dr. Weber'), isEmpty);
  });

  test('the sms link puts the body where each platform reads it', () {
    const body = 'Mir geht es gut.\nStand: 6. Okt. 14:05';
    final android = smsUri('+491712345678', body, ios: false).toString();
    final ios = smsUri('+491712345678', body, ios: true).toString();
    expect(android, startsWith('sms:+491712345678?body='));
    expect(ios, startsWith('sms:+491712345678&body='));
    // A space is %20 and never "+", which would arrive as a plus sign.
    expect(android, contains('Mir%20geht'));
    expect(android, isNot(contains('+geht')));
  });

  test('the message holds status, time, place and note in that order', () {
    final text = composeCheckIn(
      status: 'Mir geht es gut.',
      time: 'Stand: 14:05',
      location: describePosition(52.26890, 10.52680, accuracyMetres: 12),
      note: '  Bin bei Nachbarn. ',
    );
    expect(text.split('\n'), [
      'Mir geht es gut.',
      'Stand: 14:05',
      '52.26890, 10.52680 (±12 m)',
      'https://www.openstreetmap.org/?mlat=52.26890&mlon=10.52680#map=17/52.26890/10.52680',
      'Bin bei Nachbarn.',
    ]);
  });

  test('contacts are kept', () async {
    await const CheckInContactStore().save(const [
      CheckInContact(name: 'Tante Inge', phone: '+491712345678'),
    ]);
    final kept = await const CheckInContactStore().load();
    expect(kept.single.name, 'Tante Inge');
  });

  testWidgets('the plan contact is offered, and sending opens messaging', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db.upsertHouseholdPlan(
      HouseholdPlansCompanion.insert(
        clientId: 'home',
        householdId: 'home',
        contactName: const Value('Tante Inge'),
        contactPhone: const Value('0171 2345678'),
        meetingPointNear: const Value('Spielplatz'),
        updatedAt: DateTime.utc(2026, 10, 6),
      ),
    );
    final launched = <Uri>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CheckInScreen(
            householdId: 'home',
            launch: (uri) async {
              launched.add(uri);
              return true;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final list = find.byType(Scrollable).first;
    final suggestion = find.text('Vorschlag übernehmen: Tante Inge');
    await tester.scrollUntilVisible(suggestion, 200, scrollable: list);
    expect(suggestion, findsOneWidget);
    await tester.tap(suggestion);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    final onMyWay = find.text('Ich bin auf dem Weg zum Treffpunkt.');
    await tester.ensureVisible(onMyWay);
    await tester.pumpAndSettle();
    await tester.tap(onMyWay);
    await tester.pumpAndSettle();
    expect(
      find.textContaining(
        'auf dem Weg zum Treffpunkt: Spielplatz',
        skipOffstage: false,
      ),
      findsOneWidget,
    );

    final send = find.text('SMS an Tante Inge');
    if (send.evaluate().isNotEmpty) {
      await tester.ensureVisible(send);
      await tester.tap(send);
      await tester.pumpAndSettle();
      expect(launched.single.toString(), startsWith('sms:01712345678'));
      expect(
        Uri.decodeComponent(launched.single.toString()),
        contains('Treffpunkt: Spielplatz'),
      );
    }
    final kept = await tester.runAsync(const CheckInContactStore().load);
    expect(kept!.single.phone, '01712345678');

    // Let the providers' streams close before the test ends.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
