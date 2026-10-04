import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/home/application/home_screen_widget.dart';
import 'package:preppsuite_flutter/features/home/application/status_lights.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations_de.dart';
import 'package:preppsuite_flutter/model/categories.dart';

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

    test('where there is no widget, nothing is called', () async {
      final publisher = HomeWidgetPublisher(enabled: false);

      expect(await publisher.publish(snapshot()), isFalse);
      expect(calls, isEmpty);
    });
  });
}
