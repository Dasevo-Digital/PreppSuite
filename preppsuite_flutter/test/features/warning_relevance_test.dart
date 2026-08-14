import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_client/preppsuite_client.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_relevance.dart';
import 'package:preppsuite_flutter/local_db/database.dart' as db;

void main() {
  Household household({String? regionKey}) {
    return Household(
      name: 'Test',
      countryCode: 'DE',
      regionKey: regionKey,
      inviteCode: 'TEST1234',
      createdAt: DateTime.utc(2026),
    );
  }

  db.Warning warning({String? regionKey}) {
    return db.Warning(
      serverId: 'x',
      source: 'bbk',
      externalId: 'x',
      countryCode: 'DE',
      regionKey: regionKey,
      severity: 'moderate',
      eventType: 'Test',
      headline: 'Test',
      effective: DateTime.utc(2026),
      sent: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );
  }

  WarningRegionSubscription subscription({
    required WarningRegionKind kind,
    required String value,
  }) {
    return WarningRegionSubscription(
      householdId: UuidValue.fromString('00000000-0000-0000-0000-000000000000'),
      kind: kind,
      value: value,
      label: value,
      createdAt: DateTime.utc(2026),
    );
  }

  group('warningRelevanceRank', () {
    test('a nationwide warning (no regionKey) ranks lowest', () {
      expect(
        warningRelevanceRank(
          warning: warning(regionKey: null),
          household: household(regionKey: '053340000000'),
          subscriptions: const [],
        ),
        0,
      );
    });

    test("a warning in the household's own Kreis ranks highest", () {
      expect(
        warningRelevanceRank(
          warning: warning(regionKey: '05334'),
          household: household(regionKey: '053340000000'),
          subscriptions: const [],
        ),
        2,
      );
    });

    test("a warning in the household's own state ranks mid", () {
      expect(
        warningRelevanceRank(
          warning: warning(regionKey: 'NW'),
          household: household(regionKey: '053340000000'),
          subscriptions: const [],
        ),
        1,
      );
    });

    test('a subscribed Kreis ranks highest even outside the own state', () {
      expect(
        warningRelevanceRank(
          warning: warning(regionKey: '09162'),
          household: household(regionKey: '053340000000'),
          subscriptions: [
            subscription(kind: WarningRegionKind.kreis, value: '09162'),
          ],
        ),
        2,
      );
    });

    test('a subscribed Bundesland ranks mid', () {
      expect(
        warningRelevanceRank(
          warning: warning(regionKey: 'BY'),
          household: household(regionKey: '053340000000'),
          subscriptions: [
            subscription(kind: WarningRegionKind.bundesland, value: 'BY'),
          ],
        ),
        1,
      );
    });

    test('an unrelated region ranks lowest', () {
      expect(
        warningRelevanceRank(
          warning: warning(regionKey: 'SN'),
          household: household(regionKey: '053340000000'),
          subscriptions: const [],
        ),
        0,
      );
    });
  });
}
