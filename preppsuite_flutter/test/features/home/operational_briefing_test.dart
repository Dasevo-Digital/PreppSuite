import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/home/application/operational_briefing.dart';
import 'package:preppsuite_flutter/features/home/application/status_lights.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_freshness.dart';

/// The one answer at the top of the overview.
void main() {
  OperationalBriefing briefing({
    int warnings = 0,
    WarningFreshness? freshness = WarningFreshness.current,
    bool inventoryEmpty = false,
    int inventoryAttention = 0,
    SupplyLight supply = SupplyLight.covered,
    bool chargeDue = false,
  }) => operationalBriefing(
    warnings: warnings,
    freshness: freshness,
    inventoryEmpty: inventoryEmpty,
    inventoryAttention: inventoryAttention,
    supply: supply,
    chargeDue: chargeDue,
  );

  group('the feeds (#394)', () {
    test('no warning from feeds a day out of reach is not "no warning"', () {
      expect(
        briefing(freshness: WarningFreshness.stale),
        OperationalBriefing.unheard,
      );
    });

    test('nor from feeds this device has never reached', () {
      expect(
        briefing(freshness: WarningFreshness.never),
        OperationalBriefing.unheard,
      );
    });

    test('it comes before anything to do at home', () {
      expect(
        briefing(
          freshness: WarningFreshness.stale,
          inventoryEmpty: true,
          chargeDue: true,
        ),
        OperationalBriefing.unheard,
      );
    });

    test('a warning in force is named however old the feeds are', () {
      expect(
        briefing(warnings: 1, freshness: WarningFreshness.stale),
        OperationalBriefing.warning,
      );
    });

    test('while the bookkeeping is being read, nothing is claimed', () {
      expect(briefing(freshness: null), OperationalBriefing.ready);
    });
  });

  test('current feeds and nothing to do is the quiet answer', () {
    expect(briefing(), OperationalBriefing.ready);
    expect(
      briefing(inventoryEmpty: true, supply: SupplyLight.unknown),
      OperationalBriefing.inventoryMissing,
    );
    expect(briefing(chargeDue: true), OperationalBriefing.chargeDue);
  });

  group('"Grundlagen angelegt" is earned (#394)', () {
    test('one candle is not the basics', () {
      // One entry, no water and no food to count: it read "basics in
      // place" above "lasts 0 of 10 days".
      expect(
        briefing(supply: SupplyLight.unknown),
        OperationalBriefing.supplyUnknown,
      );
    });

    test('a supply short of the ten days is the next thing to do', () {
      expect(
        briefing(supply: SupplyLight.short),
        OperationalBriefing.supplyShort,
      );
    });

    test('expired or low stock comes first, even on a full shelf', () {
      expect(
        briefing(inventoryAttention: 3, supply: SupplyLight.short),
        OperationalBriefing.inventoryAttention,
      );
      expect(
        briefing(inventoryAttention: 1),
        OperationalBriefing.inventoryAttention,
      );
    });

    test('the equipment check still counts on a covered supply', () {
      expect(briefing(chargeDue: true), OperationalBriefing.chargeDue);
      expect(
        briefing(chargeDue: true, supply: SupplyLight.short),
        OperationalBriefing.supplyShort,
      );
    });
  });
}
