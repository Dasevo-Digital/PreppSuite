import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_region_filter.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_relevance.dart';
import 'package:preppsuite_flutter/local_db/database.dart' as db;

void main() {
  /// Aachen, in North Rhine-Westphalia.
  WarningRegionFilter filter({
    String? regionKey = '053340000000',
    List<WarningRegion> extra = const [],
    String countryCode = 'DE',
  }) {
    return WarningRegionFilter(
      countryCode: countryCode,
      ownRegionKey: regionKey,
      extraRegions: extra,
    );
  }

  db.Warning warning({String? regionKey, String countryCode = 'DE'}) {
    return db.Warning(
      source: 'bbk',
      externalId: 'x',
      countryCode: countryCode,
      regionKey: regionKey,
      severity: 'moderate',
      eventType: 'Test',
      headline: 'Test',
      effective: DateTime.utc(2026),
      sent: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
      notified: false,
    );
  }

  group('warningRelevanceRank', () {
    test('a nationwide warning (no regionKey) ranks lowest', () {
      expect(
        warningRelevanceRank(
          warning: warning(regionKey: null),
          filter: filter(),
        ),
        0,
      );
    });

    test("a warning in the device's own Kreis ranks highest", () {
      expect(
        warningRelevanceRank(
          warning: warning(regionKey: '05334'),
          filter: filter(),
        ),
        2,
      );
    });

    test("a warning in the device's own state ranks mid", () {
      expect(
        warningRelevanceRank(
          warning: warning(regionKey: 'NW'),
          filter: filter(),
        ),
        1,
      );
    });

    test('a followed Kreis ranks highest even outside the own state', () {
      expect(
        warningRelevanceRank(
          warning: warning(regionKey: '09162'),
          filter: filter(
            extra: const [
              WarningRegion(kind: WarningRegionKind.kreis, value: '09162'),
            ],
          ),
        ),
        2,
      );
    });

    test('a followed Bundesland ranks mid', () {
      expect(
        warningRelevanceRank(
          warning: warning(regionKey: 'BY'),
          filter: filter(
            extra: const [
              WarningRegion(kind: WarningRegionKind.bundesland, value: 'BY'),
            ],
          ),
        ),
        1,
      );
    });

    test('an unrelated region ranks lowest', () {
      expect(
        warningRelevanceRank(
          warning: warning(regionKey: 'SN'),
          filter: filter(),
        ),
        0,
      );
    });
  });

  group('isWarningRelevant', () {
    /// The distinction the rank cannot make, and the reason this function
    /// exists: without a server pre-filtering, rank 0 would silently hide
    /// nationwide warnings from everyone.
    test('a warning without a region concerns everyone', () {
      expect(
        isWarningRelevant(
          warning: warning(regionKey: null),
          filter: filter(),
        ),
        isTrue,
      );
    });

    test('a warning for another region does not', () {
      expect(
        isWarningRelevant(
          warning: warning(regionKey: 'SN'),
          filter: filter(),
        ),
        isFalse,
      );
    });

    test("a warning in the device's own Kreis does", () {
      expect(
        isWarningRelevant(
          warning: warning(regionKey: '05334'),
          filter: filter(),
        ),
        isTrue,
      );
    });

    test('everything is relevant when no region has been set', () {
      // Someone who has not told the app where they are gets the whole
      // country rather than nothing — the safe reading for a
      // civil-protection alert.
      expect(
        isWarningRelevant(
          warning: warning(regionKey: 'SN'),
          filter: filter(regionKey: null),
        ),
        isTrue,
      );
    });

    test('a warning from another country is never relevant', () {
      expect(
        isWarningRelevant(
          warning: warning(regionKey: null, countryCode: 'AT'),
          filter: filter(),
        ),
        isFalse,
      );
    });
  });

  group('WarningRegion encoding', () {
    test('round-trips through preferences', () {
      // The background isolate reads these back as plain strings.
      const region = WarningRegion(
        kind: WarningRegionKind.bundesland,
        value: 'BY',
      );

      expect(WarningRegion.decode(region.encode()), region);
    });

    test('a value containing a colon survives', () {
      const region = WarningRegion(
        kind: WarningRegionKind.kreis,
        value: 'a:b',
      );

      expect(WarningRegion.decode(region.encode()), region);
    });

    test('rubbish decodes to null rather than a bogus region', () {
      expect(WarningRegion.decode('nonsense'), isNull);
      expect(WarningRegion.decode('kreis:'), isNull);
      expect(WarningRegion.decode(':05334'), isNull);
    });
  });
}
