import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:preppsuite_flutter/features/home/application/home_screen_widget.dart';
import 'package:preppsuite_flutter/features/home/application/status_lights.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_region_filter.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations_de.dart';
import 'package:preppsuite_flutter/local_db/database.dart';
import 'package:preppsuite_flutter/model/categories.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The home screen widget shows the overview's two lamps (#105).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final l10n = AppLocalizationsDe();

  HomeWidgetSnapshot snapshot({
    SupplyStatus supply = const SupplyStatus(
      light: SupplyLight.short,
      daysCovered: 4,
    ),
    SituationStatus situation = const SituationStatus(),
  }) => buildHomeWidgetSnapshot(
    supply: supply,
    situation: situation,
    l10n: l10n,
    time: '14:05',
  );

  group('the snapshot', () {
    test('says how far the supply reaches, in the app language', () {
      final s = snapshot();
      expect(s.supplyState, 'short');
      expect(s.supplyText, 'Vorrat: Reicht 4 von 10 Tagen');
    });

    test('a quiet situation is called quiet, not safe', () {
      final s = snapshot();
      expect(s.situationState, 'none');
      expect(s.situationText, 'Lage: Keine amtliche Warnung');
    });

    test('warnings carry their count and the highest level', () {
      final s = snapshot(
        situation: const SituationStatus(
          highest: WarningSeverity.severe,
          count: 2,
        ),
      );
      expect(s.situationState, 'severe');
      expect(s.situationText, contains('2 Warnungen'));
      expect(s.situationText, contains('Schwer'));
    });

    test('nothing recorded is said as such', () {
      final s = snapshot(
        supply: const SupplyStatus(light: SupplyLight.unknown),
      );
      expect(s.supplyState, 'unknown');
      expect(s.supplyText, 'Vorrat: Noch nichts eingetragen');
    });

    test('never passes for live: it carries its time', () {
      expect(snapshot().updatedText, 'Stand: 14:05');
    });
  });

  group('the publisher', () {
    final calls = <MethodCall>[];

    setUp(() {
      calls.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('home_widget'), (
            call,
          ) async {
            calls.add(call);
            return true;
          });
    });

    test('writes every field and asks the widget to redraw', () async {
      final publisher = HomeWidgetPublisher(enabled: true);

      expect(await publisher.publish(snapshot()), isTrue);

      final saved = {
        for (final call in calls)
          if (call.method == 'saveWidgetData')
            (call.arguments as Map)['id']: (call.arguments as Map)['data'],
      };
      expect(saved['supplyState'], 'short');
      expect(saved['updatedText'], 'Stand: 14:05');
      expect(calls.last.method, 'updateWidget');
      expect(
        (calls.last.arguments as Map)['android'],
        'PreppSuiteWidgetProvider',
      );
    });

    test('the same snapshot twice is published once', () async {
      final publisher = HomeWidgetPublisher(enabled: true);
      await publisher.publish(snapshot());
      calls.clear();

      expect(await publisher.publish(snapshot()), isFalse);
      expect(calls, isEmpty);
    });

    test('the time carries its day (#332)', () async {
      await initializeDateFormatting('de');
      final stamp = homeWidgetStamp(DateTime(2026, 11, 9, 14, 5), 'de');
      expect(stamp, contains('9.11.'));
      expect(stamp, contains('14:05'));
    });

    test('the background worker sets the lamp it knows about (#332)', () async {
      SharedPreferences.setMockInitialValues({'localeOverride': 'de'});
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      await db.upsertWarning(
        WarningsCompanion.insert(
          source: 'bbk',
          externalId: 'one',
          countryCode: 'DE',
          regionKey: const Value('05334'),
          severity: 'extreme',
          eventType: 'Evakuierung',
          headline: 'Evakuierung',
          effective: DateTime.utc(2026),
          sent: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
        ),
      );

      await publishHomeWidgetSituation(
        database: db,
        filter: const WarningRegionFilter(
          countryCode: 'DE',
          ownRegionKey: '053340000000',
        ),
        publisher: HomeWidgetPublisher(enabled: true),
        now: DateTime(2026, 11, 9, 14, 5),
      );

      final saved = {
        for (final call in calls)
          if (call.method == 'saveWidgetData')
            (call.arguments as Map)['id']: (call.arguments as Map)['data'],
      };
      expect(saved['situationState'], 'extreme');
      expect(saved['updatedText'], contains('9.11.'));
      expect(
        saved.containsKey('supplyText'),
        isFalse,
        reason: 'that lamp needs a household the worker does not have',
      );
      expect(calls.last.method, 'updateWidget');
    });

    test('a deleted household empties the widget (#336)', () async {
      await HomeWidgetPublisher(enabled: true).clear();

      final cleared = [
        for (final call in calls)
          if (call.method == 'saveWidgetData')
            (call.arguments as Map)['id'] as String,
      ];
      expect(cleared, containsAll(['supplyText', 'situationText']));
      expect(
        calls
            .where((call) => call.method == 'saveWidgetData')
            .every((call) => (call.arguments as Map)['data'] == null),
        isTrue,
      );
      expect(calls.last.method, 'updateWidget');
    });

    test('where there is no widget, nothing is called', () async {
      final publisher = HomeWidgetPublisher(enabled: false);

      expect(await publisher.publish(snapshot()), isFalse);
      expect(calls, isEmpty);
    });
  });
}
