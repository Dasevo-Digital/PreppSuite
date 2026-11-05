import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/preparedness/application/resilience_plan.dart';

void main() {
  test(
    'keeps resilience planning local data serializable without contacts',
    () {
      final checked = DateTime(2026, 9, 23, 8);
      final plan = ResiliencePlan(
        warningChecks: {'cell': checked},
        support: IndividualSupportPlan(
          powerReviewed: true,
          transportReviewed: true,
          note: 'Ersatzenergie und Abholung sind geklärt.',
          checkedAt: checked,
        ),
        sources: [
          TrustedSource(
            id: 'source',
            label: 'Gemeinde',
            channel: 'Amtliche Website',
            offlineFallback: 'Radio',
            checkedAt: checked,
          ),
        ],
        learningChecks: {'water': checked},
        neighborhood: [
          NeighborhoodCapability(
            id: 'help',
            alias: 'Funkhilfe',
            skill: 'Kurbelradio',
            contactMethod: 'Treffpunkt',
            meetingPoint: 'Aushang',
            checkedAt: checked,
          ),
        ],
        maintenanceEveryDays: {'radio': 90},
      );

      final restored = ResiliencePlan.fromJson(plan.toJson());

      expect(restored.warningChecks['cell'], checked);
      expect(restored.support.powerReviewed, isTrue);
      expect(restored.sources.single.offlineFallback, 'Radio');
      expect(restored.learningChecks['water'], checked);
      expect(restored.neighborhood.single.alias, 'Funkhilfe');
      expect(restored.maintenanceEveryDays['radio'], 90);
    },
  );

  test(
    'merging preserves a local interval and joins independently added data',
    () {
      final older = DateTime(2026, 9, 1);
      final newer = DateTime(2026, 9, 20);
      final local = ResiliencePlan(
        warningChecks: {'radio': newer},
        sources: [
          TrustedSource(
            id: 'local',
            label: 'Radio',
            channel: 'UKW',
            offlineFallback: 'Kurbelradio',
            checkedAt: newer,
          ),
        ],
        maintenanceEveryDays: {'radio': 90},
      );
      final restored = ResiliencePlan(
        warningChecks: {'radio': older, 'cell': older},
        sources: [
          TrustedSource(
            id: 'backup',
            label: 'Kommune',
            channel: 'Website',
            offlineFallback: 'Aushang',
            checkedAt: older,
          ),
        ],
        maintenanceEveryDays: {'radio': 30, 'kit': 180},
      );

      final merged = local.mergeWith(restored);

      expect(merged.warningChecks['radio'], newer);
      expect(merged.warningChecks['cell'], older);
      expect(merged.sources.map((source) => source.id), ['local', 'backup']);
      expect(merged.maintenanceEveryDays, {'radio': 90, 'kit': 180});
    },
  );

  test('malformed untrusted local JSON is ignored', () {
    final restored = ResiliencePlan.fromJson({
      'sources': ['not-a-source'],
      'neighborhood': [null],
      'maintenanceEveryDays': {'radio': -1, 'kit': '90'},
    });

    expect(restored.sources, isEmpty);
    expect(restored.neighborhood, isEmpty);
    expect(restored.maintenanceEveryDays, isEmpty);
  });

  group('maintenance schedule (#291)', () {
    test('the water filter is looked up where the hub ticks it off', () {
      expect(maintenanceCheckKey('waterFilter'), 'water_filter');
      expect(maintenanceCheckKey('batteries'), 'batteries');
    });

    test('due counts calendar days, not the hour of the last check', () {
      final changed = DateTime(2026, 8, 7, 18);
      bool dueOn(DateTime now) =>
          isMaintenanceDue(lastChecked: changed, everyDays: 90, now: now);

      // Ninety days on, from the first minute of that day -- not from six
      // in the evening, when nothing redraws the screen.
      expect(dueOn(DateTime(2026, 11, 4, 23, 59)), isFalse);
      expect(dueOn(DateTime(2026, 11, 5, 0, 1)), isTrue);
      // Across the end of summer time, ninety days stay ninety days.
      expect(dueOn(DateTime(2026, 11, 5, 9)), isTrue);
    });

    test('nothing is due without an interval, everything without a check', () {
      final now = DateTime(2026, 11, 5);
      expect(
        isMaintenanceDue(lastChecked: null, everyDays: 0, now: now),
        isFalse,
      );
      expect(
        isMaintenanceDue(lastChecked: null, everyDays: 30, now: now),
        isTrue,
      );
    });
  });
}
