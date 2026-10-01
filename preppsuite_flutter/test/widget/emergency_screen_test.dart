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

  Future<void> show(WidgetTester tester, Locale locale) async {
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
}
