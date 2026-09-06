import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_filter.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_region_filter.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

void main() {
  final now = DateTime.utc(2026, 9, 6, 12);

  Warning warning({
    String externalId = 'w1',
    String headline = 'Sturmböen',
    String? description,
    String eventType = 'Wind',
    String severity = 'moderate',
    String? regionKey,
    DateTime? expires,
    String countryCode = 'DE',
  }) => Warning(
    source: 'bbk',
    externalId: externalId,
    countryCode: countryCode,
    regionKey: regionKey,
    severity: severity,
    eventType: eventType,
    headline: headline,
    description: description,
    effective: now.subtract(const Duration(hours: 2)),
    expires: expires,
    sent: now.subtract(const Duration(hours: 2)),
    updatedAt: now,
    notified: false,
  );

  const noRegions = WarningRegionFilter(countryCode: 'DE');
  const hannover = WarningRegionFilter(
    countryCode: 'DE',
    ownRegionKey: '03241',
  );

  bool matches(
    WarningFilter filter,
    Warning w, {
    WarningRegionFilter? regions,
  }) => filter.matches(w, regions: regions ?? noRegions, now: now);

  group('status', () {
    test('an unfiltered list keeps everything', () {
      const filter = WarningFilter();
      expect(filter.isEmpty, isTrue);
      expect(filter.activeCount, 0);
      expect(matches(filter, warning()), isTrue);
      expect(
        matches(
          filter,
          warning(expires: now.subtract(const Duration(days: 1))),
        ),
        isTrue,
      );
    });

    test('active hides what has already run out', () {
      const filter = WarningFilter(status: WarningStatus.active);

      expect(
        matches(filter, warning(expires: now.add(const Duration(hours: 3)))),
        isTrue,
      );
      expect(
        matches(
          filter,
          warning(expires: now.subtract(const Duration(hours: 1))),
        ),
        isFalse,
      );
    });

    test('a warning with no expiry counts as active', () {
      // The safe reading: a feed that left the field empty must not cause
      // a civil-protection alert to be hidden from the one view that is
      // meant to show it.
      expect(
        matches(const WarningFilter(status: WarningStatus.active), warning()),
        isTrue,
      );
      expect(
        matches(const WarningFilter(status: WarningStatus.expired), warning()),
        isFalse,
      );
    });

    test('expired shows exactly the other half', () {
      const filter = WarningFilter(status: WarningStatus.expired);

      expect(
        matches(
          filter,
          warning(expires: now.subtract(const Duration(days: 1))),
        ),
        isTrue,
      );
      expect(
        matches(filter, warning(expires: now.add(const Duration(days: 1)))),
        isFalse,
      );
    });
  });

  group('severity', () {
    test('only severe keeps severe and extreme', () {
      const filter = WarningFilter(onlySevere: true);

      expect(matches(filter, warning(severity: 'extreme')), isTrue);
      expect(matches(filter, warning(severity: 'severe')), isTrue);
      expect(matches(filter, warning(severity: 'moderate')), isFalse);
      expect(matches(filter, warning(severity: 'minor')), isFalse);
    });
  });

  group('regions', () {
    test('own district and own state survive, another state does not', () {
      const filter = WarningFilter(onlyMyRegions: true);

      expect(
        matches(filter, warning(regionKey: '03241'), regions: hannover),
        isTrue,
      );
      expect(
        matches(filter, warning(regionKey: '03'), regions: hannover),
        isTrue,
      );
      expect(
        matches(filter, warning(regionKey: '09162'), regions: hannover),
        isFalse,
      );
    });

    test('a warning without a region stays, because it concerns everyone', () {
      // The distinction `isWarningRelevant` exists for: the rank cannot
      // tell "nationwide" from "somewhere else", and filtering on the rank
      // would hide every nationwide alert.
      expect(
        matches(
          const WarningFilter(onlyMyRegions: true),
          warning(regionKey: null),
          regions: hannover,
        ),
        isTrue,
      );
    });
  });

  group('search', () {
    test('matches the headline, description, event type and region', () {
      const filter = WarningFilter(query: 'hannover');

      expect(matches(filter, warning(headline: 'Hochwasser Hannover')), isTrue);
      expect(
        matches(filter, warning(description: 'Betroffen ist Hannover')),
        isTrue,
      );
      expect(matches(filter, warning(eventType: 'Hannover-Test')), isTrue);
      expect(matches(filter, warning(headline: 'Sturm in Bremen')), isFalse);
    });

    test('case and surrounding whitespace do not matter', () {
      expect(
        matches(
          const WarningFilter(query: '  STURM '),
          warning(headline: 'Schwere Sturmböen'),
        ),
        isTrue,
      );
    });

    test('two places that differ only in an umlaut stay apart', () {
      // Folding diacritics would answer a search for Münster with Munster
      // and the other way round. They are different towns.
      expect(
        matches(
          const WarningFilter(query: 'münster'),
          warning(headline: 'Warnung Munster'),
        ),
        isFalse,
      );
    });
  });

  group('combining', () {
    test('conditions narrow together, not instead of each other', () {
      const filter = WarningFilter(
        query: 'hochwasser',
        status: WarningStatus.active,
        onlySevere: true,
        onlyMyRegions: true,
      );
      expect(filter.activeCount, 4);
      expect(filter.isEmpty, isFalse);

      Warning candidate({
        String headline = 'Hochwasser',
        String severity = 'severe',
        String? regionKey = '03241',
        DateTime? expires,
      }) => warning(
        headline: headline,
        severity: severity,
        regionKey: regionKey,
        expires: expires ?? now.add(const Duration(hours: 5)),
      );

      expect(matches(filter, candidate(), regions: hannover), isTrue);

      for (final failing in [
        candidate(headline: 'Sturm'),
        candidate(severity: 'minor'),
        candidate(regionKey: '09162'),
        candidate(expires: now.subtract(const Duration(hours: 1))),
      ]) {
        expect(matches(filter, failing, regions: hannover), isFalse);
      }
    });

    test('applyWarningFilter keeps the order it was given', () {
      final warnings = [
        warning(externalId: 'a', headline: 'Sturm'),
        warning(externalId: 'b', headline: 'Hochwasser'),
        warning(externalId: 'c', headline: 'Sturmflut'),
      ];

      final kept = applyWarningFilter(
        warnings,
        filter: const WarningFilter(query: 'sturm'),
        regions: noRegions,
        now: now,
      );

      expect(kept.map((w) => w.externalId), ['a', 'c']);
    });
  });
}
