import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_providers.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_sync_controller.dart';
import 'package:preppsuite_flutter/features/warnings/presentation/warning_banner.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:preppsuite_flutter/local_db/database.dart' as db;
import 'package:preppsuite_flutter/model/household_profile.dart';

/// What the banner is allowed to put across the top of every tab.
///
/// The case behind these: a household in Braunschweig (03101) had a minor
/// bomb disposal in Dulmen, North Rhine-Westphalia, pinned above every
/// screen with "+7 more" behind it — while the warnings badge beside it
/// showed 1. The banner was the only reader of `activeWarningsProvider`
/// that did not filter by region.
/// The banner keeps the warning poll alive for as long as any screen is
/// showing. A widget test has no network and wants none, so the poll is
/// replaced by a notifier that schedules nothing.
class _IdleSync extends WarningSyncController {
  _IdleSync(super.profile);

  @override
  AsyncValue<void> build() => const AsyncData(null);
}

void main() {
  /// Braunschweig, Lower Saxony — the twelve-digit form the app stores.
  final household = HouseholdProfile(
    id: 'household-1',
    name: 'Testhaushalt',
    countryCode: 'DE',
    regionKey: '031010000000',
  );

  db.Warning warning({
    required String id,
    required String headline,
    String? regionKey,
    String severity = 'minor',
    DateTime? effective,
  }) {
    return db.Warning(
      source: 'bbk',
      externalId: id,
      countryCode: 'DE',
      regionKey: regionKey,
      severity: severity,
      eventType: 'Test',
      headline: headline,
      effective: effective ?? DateTime.utc(2026),
      sent: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
      notified: false,
    );
  }

  Future<void> pump(
    WidgetTester tester,
    List<db.Warning> warnings, {
    HouseholdProfile? profile,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeWarningsProvider.overrideWith(
            (ref) => Stream.value(warnings),
          ),
          // The banner keeps the poll alive while any screen is showing;
          // a widget test has no network and wants none.
          warningSyncControllerProvider.overrideWith2(_IdleSync.new),
        ],
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: WarningBanner(profile: profile ?? household),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a warning for another state is not put on the banner', (
    tester,
  ) async {
    await pump(tester, [
      warning(id: 'nw', headline: 'Kampfmittelfund Dülmen', regionKey: 'NW'),
    ]);

    expect(find.textContaining('Dülmen'), findsNothing);
  });

  testWidgets('a warning for the household\'s own district is shown', (
    tester,
  ) async {
    await pump(tester, [
      warning(
        id: 'bs',
        headline: 'Stromausfall Braunschweig',
        regionKey: '03101',
      ),
    ]);

    expect(find.textContaining('Stromausfall Braunschweig'), findsOneWidget);
  });

  testWidgets('the own Land counts when it is severe', (tester) async {
    // A warning known only by its Land may be for all of it or for a
    // district at the other end (#11). Severe is worth the banner either
    // way; a minor one waits in the list.
    await pump(tester, [
      warning(
        id: 'ni',
        headline: 'Sturm in Niedersachsen',
        regionKey: 'NI',
        severity: 'severe',
      ),
      warning(id: 'ni-minor', headline: 'Glätte', regionKey: 'NI'),
    ]);

    expect(find.textContaining('Sturm in Niedersachsen'), findsOneWidget);
    expect(find.textContaining('weitere'), findsNothing);
  });

  testWidgets('another district of the Land only when extreme (#11)', (
    tester,
  ) async {
    // Emsland is in the same Land as Braunschweig and two hundred
    // kilometres away.
    await pump(tester, [
      warning(
        id: 'el',
        headline: 'Sturm im Emsland',
        regionKey: '03454',
        severity: 'severe',
      ),
    ]);
    expect(find.byType(InkWell), findsNothing);
  });

  testWidgets('and an extreme one there still is shown', (tester) async {
    await pump(tester, [
      warning(
        id: 'el',
        headline: 'Chemieunfall im Emsland',
        regionKey: '03454',
        severity: 'extreme',
      ),
    ]);
    expect(find.textContaining('Chemieunfall im Emsland'), findsOneWidget);
  });

  testWidgets('a warning that has not begun waits in the list (#11)', (
    tester,
  ) async {
    await pump(tester, [
      warning(
        id: 'morgen',
        headline: 'Sturm ab morgen',
        regionKey: '03101',
        severity: 'severe',
        effective: DateTime.now().add(const Duration(hours: 20)),
      ),
    ]);
    expect(find.byType(InkWell), findsNothing);
  });

  testWidgets('a warning that could not be placed still reaches everyone', (
    tester,
  ) async {
    // The safe reading, unchanged: no region means "concerns everyone",
    // and for a civil-protection alert too many people is the safe
    // error. This is the one the placement work narrows where it can —
    // but where it cannot, the banner must still carry it.
    await pump(tester, [
      warning(id: 'anywhere', headline: 'Bundesweite Meldung'),
    ]);

    expect(find.textContaining('Bundesweite Meldung'), findsOneWidget);
  });

  testWidgets('the count behind it counts only what concerns the household', (
    tester,
  ) async {
    // The disagreement that gave this away: eight active warnings, one of
    // them here, and the banner said "+7 weitere".
    await pump(tester, [
      warning(id: 'bs', headline: 'Hier', regionKey: '03101'),
      warning(id: 'nw', headline: 'Dülmen', regionKey: 'NW'),
      warning(id: 'by', headline: 'Bayern', regionKey: 'BY'),
      warning(id: 'rp', headline: 'Worms', regionKey: 'RP'),
    ]);

    expect(find.textContaining('Hier'), findsOneWidget);
    expect(find.textContaining('weitere'), findsNothing);
  });

  testWidgets('nothing relevant means no banner at all', (tester) async {
    await pump(tester, [
      warning(id: 'nw', headline: 'Dülmen', regionKey: 'NW'),
    ]);

    expect(find.byType(InkWell), findsNothing);
  });

  testWidgets('a household with no region set sees everything', (
    tester,
  ) async {
    await pump(
      tester,
      [warning(id: 'nw', headline: 'Dülmen', regionKey: 'NW')],
      profile: HouseholdProfile(
        id: 'household-2',
        name: 'Ohne Region',
        countryCode: 'DE',
      ),
    );

    expect(find.textContaining('Dülmen'), findsOneWidget);
  });

  testWidgets('severity still outranks nearness among relevant warnings', (
    tester,
  ) async {
    // Filtering must not have turned into sorting: an extreme warning for
    // the whole state must beat a minor one next door.
    await pump(tester, [
      warning(id: 'bs', headline: 'Kleinigkeit hier', regionKey: '03101'),
      warning(
        id: 'ni',
        headline: 'Unwetter im Land',
        regionKey: 'NI',
        severity: 'extreme',
      ),
    ]);

    expect(find.textContaining('Unwetter im Land'), findsOneWidget);
    expect(find.textContaining('Kleinigkeit hier'), findsNothing);
  });
}
