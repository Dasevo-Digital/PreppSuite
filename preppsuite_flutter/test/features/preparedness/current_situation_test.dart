import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/energy/application/outage_food_safety.dart';
import 'package:preppsuite_flutter/features/energy/application/outage_store.dart';
import 'package:preppsuite_flutter/features/preparedness/application/current_situation.dart';
import 'package:preppsuite_flutter/local_db/database.dart';
import 'package:preppsuite_flutter/model/household_profile.dart';

void main() {
  final now = DateTime.utc(2026, 9, 19, 12);

  Warning warning({
    required String id,
    required String severity,
    String countryCode = 'DE',
    String? regionKey = '03241',
    DateTime? sent,
  }) => Warning(
    source: 'bbk',
    externalId: id,
    countryCode: countryCode,
    regionKey: regionKey,
    severity: severity,
    eventType: 'storm',
    headline: id,
    effective: now,
    sent: sent ?? now,
    updatedAt: now,
    notified: false,
  );

  const profile = HouseholdProfile(
    id: 'home',
    name: 'Zuhause',
    countryCode: 'DE',
    regionKey: '03241',
  );

  test('a severe warning over the household counts as something running', () {
    final situation = currentSituation(
      warnings: [warning(id: 'storm', severity: 'severe')],
      profile: profile,
    );

    expect(situation.isQuiet, isFalse);
    expect(situation.leadWarning?.externalId, 'storm');
  });

  test('a minor warning does not', () {
    // Crying wolf over a wind advisory is how a household learns to
    // scroll past the one that matters.
    final situation = currentSituation(
      warnings: [
        warning(id: 'breeze', severity: 'minor'),
        warning(id: 'notice', severity: 'moderate'),
      ],
      profile: profile,
    );

    expect(situation.isQuiet, isTrue);
  });

  test('a warning somewhere else does not', () {
    final situation = currentSituation(
      warnings: [
        warning(id: 'far', severity: 'extreme', regionKey: '09162'),
        warning(id: 'abroad', severity: 'extreme', countryCode: 'AT'),
      ],
      profile: profile,
    );

    expect(situation.isQuiet, isTrue);
  });

  test('the most severe leads, and the newest of equals', () {
    final situation = currentSituation(
      warnings: [
        warning(id: 'severe', severity: 'severe'),
        warning(
          id: 'older-extreme',
          severity: 'extreme',
          sent: now.subtract(const Duration(hours: 3)),
        ),
        warning(id: 'newer-extreme', severity: 'extreme'),
      ],
      profile: profile,
    );

    expect(situation.leadWarning?.externalId, 'newer-extreme');
    expect(situation.warnings.last.externalId, 'severe');
  });

  test('a blackout counts even with no warning at all', () {
    final situation = currentSituation(
      warnings: const [],
      profile: profile,
      outage: OutageClock(
        startedAt: now.subtract(const Duration(hours: 3, minutes: 50)),
        freezerFill: FreezerFill.full,
      ),
    );

    expect(situation.isQuiet, isFalse);
    expect(situation.leadWarning, isNull);
    // Three, not four: the food-safety clock counts down in whole hours,
    // and rounding up is how somebody throws away food they could keep.
    expect(outageHours(situation.outage, now), 3);
  });

  test('a household with no profile still sees its own blackout', () {
    final situation = currentSituation(
      warnings: [warning(id: 'storm', severity: 'extreme')],
      profile: null,
      outage: OutageClock(startedAt: now, freezerFill: FreezerFill.half),
    );

    // Without a region there is nothing to judge a warning against, so
    // none is claimed to be relevant — but the blackout is this device's
    // own fact and needs no feed.
    expect(situation.warnings, isEmpty);
    expect(situation.outage, isNotNull);
  });

  test('quiet is quiet', () {
    expect(
      currentSituation(warnings: const [], profile: profile).isQuiet,
      isTrue,
    );
    expect(outageHours(null, now), isNull);
  });
}
