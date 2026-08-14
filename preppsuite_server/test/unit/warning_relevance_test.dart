import 'package:preppsuite_server/src/generated/protocol.dart';
import 'package:preppsuite_server/src/warnings/warning_service.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

void main() {
  Household household({String countryCode = 'DE', String? regionKey}) {
    return Household(
      name: 'Test',
      countryCode: countryCode,
      regionKey: regionKey,
      inviteCode: 'TEST1234',
      createdAt: DateTime.utc(2026),
    );
  }

  Warning warning({String? regionKey}) {
    return Warning(
      source: WarningSource.bbk,
      externalId: 'x',
      countryCode: 'DE',
      regionKey: regionKey,
      severity: WarningSeverity.moderate,
      eventType: 'Test',
      headline: 'Test',
      effective: DateTime.utc(2026),
      sent: DateTime.utc(2026),
      rawPayload: '{}',
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );
  }

  group('isWarningRelevant', () {
    test('a warning with no regionKey is always relevant', () {
      expect(
        isWarningRelevant(warning(regionKey: null), household(), const []),
        isTrue,
      );
    });

    test(
      'a household with no region and no subscriptions sees everything',
      () {
        expect(
          isWarningRelevant(
            warning(regionKey: '05334'),
            household(regionKey: null),
            const [],
          ),
          isTrue,
        );
      },
    );

    test('a warning in the household\'s own Kreis is relevant', () {
      expect(
        isWarningRelevant(
          warning(regionKey: '05334'),
          household(regionKey: '053340000000'),
          const [],
        ),
        isTrue,
      );
    });

    test('a warning in a different Kreis, same state, is relevant', () {
      // 05334 (Städteregion Aachen) and 05315 (Köln) are both NW.
      expect(
        isWarningRelevant(
          warning(regionKey: '05315'),
          household(regionKey: '053340000000'),
          const [],
        ),
        isTrue,
      );
    });

    test('a warning in an unrelated state is not relevant', () {
      expect(
        isWarningRelevant(
          warning(regionKey: '09162'), // Bayern
          household(regionKey: '053340000000'), // NW
          const [],
        ),
        isFalse,
      );
    });

    test('a nationwide id-parsed state-code warning matches by state', () {
      expect(
        isWarningRelevant(
          warning(regionKey: 'NW'),
          household(regionKey: '053340000000'),
          const [],
        ),
        isTrue,
      );
    });

    test('a kreis subscription makes that Kreis relevant beyond own region', () {
      expect(
        isWarningRelevant(
          warning(regionKey: '09162'),
          household(regionKey: '053340000000'),
          [
            WarningRegionSubscription(
              householdId: UuidValue.fromString(const Uuid().v4()),
              kind: WarningRegionKind.kreis,
              value: '09162',
              label: 'München',
              createdAt: DateTime.utc(2026),
            ),
          ],
        ),
        isTrue,
      );
    });

    test(
      'a bundesland subscription matches both the 2-letter and numeric '
      'warning regionKey forms',
      () {
        final subscription = WarningRegionSubscription(
          householdId: UuidValue.fromString(const Uuid().v4()),
          kind: WarningRegionKind.bundesland,
          value: 'BY',
          label: 'Bayern',
          createdAt: DateTime.utc(2026),
        );

        expect(
          isWarningRelevant(
            warning(regionKey: 'BY'),
            household(regionKey: '053340000000'),
            [subscription],
          ),
          isTrue,
        );
        expect(
          isWarningRelevant(
            warning(regionKey: '09162'),
            household(regionKey: '053340000000'),
            [subscription],
          ),
          isTrue,
        );
      },
    );

    test('a warning matching no region and no subscription is not relevant', () {
      expect(
        isWarningRelevant(
          warning(regionKey: '14612'), // Sachsen
          household(regionKey: '053340000000'), // NW
          [
            WarningRegionSubscription(
              householdId: UuidValue.fromString(const Uuid().v4()),
              kind: WarningRegionKind.bundesland,
              value: 'BY',
              label: 'Bayern',
              createdAt: DateTime.utc(2026),
            ),
          ],
        ),
        isFalse,
      );
    });
  });
}
