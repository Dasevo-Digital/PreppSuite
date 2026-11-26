import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/checklists/application/checklist_providers.dart';
import 'package:preppsuite_flutter/features/home/presentation/emergency_screen.dart';
import 'package:preppsuite_flutter/features/household/application/household_member_controller.dart';
import 'package:preppsuite_flutter/features/household/application/household_plan_controller.dart';
import 'package:preppsuite_flutter/features/inventory/application/inventory_providers.dart';
import 'package:preppsuite_flutter/features/knowledge/application/knowledge_providers.dart';
import 'package:preppsuite_flutter/features/maps/application/offline_map_providers.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_freshness.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_poll_status_store.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_providers.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:preppsuite_flutter/model/household_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NoMap extends OfflineMapController {
  @override
  Future<OfflineMapState> build() async => const OfflineMapState();
}

class _NoKnowledge extends KnowledgeController {
  @override
  Future<KnowledgeState> build() async => const KnowledgeState();
}

/// The crisis screen in English.
///
/// Its offline section was written in German straight into the code, so an
/// English locale showed "Offline-Pakete" over English subtitles.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  const profile = HouseholdProfile(
    id: 'home',
    name: 'Home',
    countryCode: 'DE',
  );

  Future<void> show(
    WidgetTester tester,
    Locale locale, {
    HouseholdProfile profile = profile,
    WarningPollStatus? polled,
  }) async {
    await tester.binding.setSurfaceSize(const Size(600, 3000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inventoryItemsProvider('home').overrideWith(
            (ref) => Stream.value(const []),
          ),
          allChecklistItemsProvider('home').overrideWith(
            (ref) => Stream.value(const []),
          ),
          householdPlanProvider('home').overrideWith(
            (ref) => Stream.value(null),
          ),
          householdMembersProvider('home').overrideWith(
            (ref) => Stream.value(const []),
          ),
          activeWarningsProvider.overrideWith((ref) => Stream.value(const [])),
          offlineMapProvider.overrideWith(_NoMap.new),
          knowledgeProvider.overrideWith(_NoKnowledge.new),
          warningPollStatusProvider.overrideWith(
            (ref) async =>
                polled ??
                WarningPollStatus(
                  lastComplete: DateTime.now().subtract(
                    const Duration(minutes: 1),
                  ),
                ),
          ),
        ],
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: EmergencyScreen(profile: profile, onNavigate: (_) {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('110 is offered in Germany', (tester) async {
    await show(tester, const Locale('de'));

    expect(find.text('Polizei 110'), findsOneWidget);
  });

  testWidgets('and nowhere else, where it can be somebody else (#339)', (
    tester,
  ) async {
    await show(
      tester,
      const Locale('es'),
      profile: const HouseholdProfile(
        id: 'home',
        name: 'Casa',
        countryCode: 'ES',
      ),
    );

    expect(find.text('Policía 110'), findsNothing);
    expect(find.textContaining('112'), findsWidgets);
  });

  group('no warning (#394)', () {
    testWidgets('is said with the time, and without a tick', (tester) async {
      await show(tester, const Locale('de'));

      final none = find.text('Keine relevanten aktiven Warnungen');
      expect(none, findsOneWidget);
      expect(find.textContaining('Stand: heute'), findsOneWidget);
      expect(
        find.descendant(
          of: find.ancestor(of: none, matching: find.byType(ListTile)),
          matching: find.byIcon(Icons.check_circle_outline),
        ),
        findsNothing,
      );
    });

    testWidgets('is not said when the feeds are out of date', (tester) async {
      await show(
        tester,
        const Locale('de'),
        polled: WarningPollStatus(
          lastComplete: DateTime.now().subtract(const Duration(hours: 5)),
        ),
      );

      expect(find.text('Keine relevanten aktiven Warnungen'), findsNothing);
      expect(find.text('Warnungen nicht aktuell'), findsOneWidget);
      expect(
        find.textContaining('Es können Warnungen fehlen.'),
        findsOneWidget,
      );
    });

    testWidgets('nor before they have ever answered', (tester) async {
      await show(tester, const Locale('en'), polled: const WarningPollStatus());

      expect(find.text('No relevant active warnings'), findsNothing);
      expect(find.text('Warnings not up to date'), findsOneWidget);
    });
  });

  testWidgets('the offline section is English on an English locale', (
    tester,
  ) async {
    await show(tester, const Locale('en'));

    expect(find.text('Offline packages'), findsOneWidget);
    expect(find.text('Offline map'), findsOneWidget);
    expect(find.text('Knowledge archives'), findsOneWidget);
    expect(find.text('Offline-Pakete'), findsNothing);
  });

  testWidgets('and German on a German one', (tester) async {
    await show(tester, const Locale('de'));

    expect(find.text('Offline-Pakete'), findsOneWidget);
    expect(find.text('Offline-Karte'), findsOneWidget);
    expect(find.text('Wissensarchive'), findsOneWidget);
  });

  testWidgets('the comic has an entry of its own and opens from it', (
    tester,
  ) async {
    // It used to be the nineteenth section of the crisis organisation,
    // three screens down. A child has to be able to find it.
    await show(tester, const Locale('de'));

    expect(find.text('Mila und Nuss'), findsOneWidget);
    await tester.tap(find.text('Mila und Nuss'));
    await tester.pumpAndSettle();

    expect(find.text('Nuss legt Vorräte an'), findsOneWidget);
  });

  testWidgets('and is named in English on an English locale', (tester) async {
    await show(tester, const Locale('en'));

    expect(find.text('Mila and Nuss'), findsOneWidget);
  });

  testWidgets('Morse and the other ways of being understood are on the tab', (
    tester,
  ) async {
    // They were three screens down under "Notruf, Kontakte & Funk", and
    // somebody looking for the Morse translator did not find it (#187).
    await show(tester, const Locale('de'));

    expect(find.text('Verständigen ohne Netz'), findsOneWidget);
    for (final title in [
      'Notsignal',
      'Morsecode',
      'Sprachführer',
      'Übersetzer',
      'Funk-Notfallfrequenzen',
    ]) {
      expect(find.text(title), findsOneWidget, reason: title);
    }
    expect(find.text('Orientierung ohne Netz'), findsOneWidget);

    await tester.tap(find.text('Morsecode'));
    await tester.pumpAndSettle();
    expect(find.byType(BackButton), findsOneWidget);
  });
}
