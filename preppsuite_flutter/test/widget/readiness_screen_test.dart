import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/checklists/application/checklist_providers.dart';
import 'package:preppsuite_flutter/features/home/presentation/readiness_screen.dart';
import 'package:preppsuite_flutter/features/household/application/household_member_controller.dart';
import 'package:preppsuite_flutter/features/household/application/household_plan_controller.dart';
import 'package:preppsuite_flutter/features/inventory/application/inventory_providers.dart';
import 'package:preppsuite_flutter/features/knowledge/application/knowledge_providers.dart';
import 'package:preppsuite_flutter/features/maps/application/offline_map_providers.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:preppsuite_flutter/local_db/database.dart';
import 'package:preppsuite_flutter/model/household_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'accessibility.dart';

class _NoMap extends OfflineMapController {
  @override
  Future<OfflineMapState> build() async => const OfflineMapState();
}

class _NoArchive extends KnowledgeController {
  @override
  Future<KnowledgeState> build() async => const KnowledgeState();
}

/// Whether the six readiness checks answer for the household in front of
/// them.
///
/// The checklist check is the one with any reasoning in it: an item counts
/// as done either because somebody ticked it or because the inventory
/// covers what it asks for. The rest are "is there anything at all".
void main() {
  const householdId = 'household-1';

  const profile = HouseholdProfile(
    id: householdId,
    name: 'Testhaushalt',
    countryCode: 'DE',
    regionKey: '03241',
    personCount: 2,
  );

  setUp(() => SharedPreferences.setMockInitialValues({}));

  InventoryItem stock({required String clientId, required double quantity}) =>
      InventoryItem(
        clientId: clientId,
        householdId: householdId,
        name: 'Trinkwasser',
        category: 'water',
        quantity: quantity,
        unit: 'L',
        storageLocation: 'Keller',
        updatedAt: DateTime.utc(2026),
        dirty: false,
      );

  ChecklistItem task({
    required String clientId,
    bool isChecked = false,
    String? linkedInventoryItemId,
    double? targetQuantity,
  }) => ChecklistItem(
    clientId: clientId,
    templateClientId: 'template-1',
    householdId: householdId,
    title: 'Wasser einlagern',
    isChecked: isChecked,
    linkedInventoryItemId: linkedInventoryItemId,
    targetQuantity: targetQuantity,
    sortOrder: 0,
    updatedAt: DateTime.utc(2026),
    dirty: false,
  );

  Future<void> show(
    WidgetTester tester, {
    List<InventoryItem> inventory = const [],
    List<ChecklistItem> checklist = const [],
  }) async {
    await tester.binding.setSurfaceSize(const Size(500, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inventoryItemsProvider(
            householdId,
          ).overrideWith((ref) => Stream.value(inventory)),
          allChecklistItemsProvider(
            householdId,
          ).overrideWith((ref) => Stream.value(checklist)),
          householdPlanProvider(
            householdId,
          ).overrideWith((ref) => Stream.value(null)),
          householdMembersProvider(
            householdId,
          ).overrideWith((ref) => Stream.value(const [])),
          offlineMapProvider.overrideWith(_NoMap.new),
          knowledgeProvider.overrideWith(_NoArchive.new),
        ],
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ReadinessScreen(profile: profile),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('an empty household is ready for nothing', (tester) async {
    await show(tester);

    expect(find.textContaining('0 von 6'), findsOneWidget);
  });

  testWidgets('a ticked task counts, even with an empty pantry', (
    tester,
  ) async {
    await show(tester, checklist: [task(clientId: 'a', isChecked: true)]);

    expect(find.textContaining('1 von 6'), findsOneWidget);
  });

  testWidgets('stock that covers a linked task counts it as done', (
    tester,
  ) async {
    // The point of linking a task to an item: nobody should have to tick
    // off what the shelf already answers. Two checks pass here, the
    // inventory one and the checklist one.
    await show(
      tester,
      inventory: [stock(clientId: 'water', quantity: 40)],
      checklist: [
        task(
          clientId: 'a',
          linkedInventoryItemId: 'water',
          targetQuantity: 20,
        ),
      ],
    );

    expect(find.textContaining('2 von 6'), findsOneWidget);
  });

  testWidgets('stock below the target does not count the task', (
    tester,
  ) async {
    // Only the inventory check passes: there is something on the shelf,
    // but not as much as the task asks for.
    await show(
      tester,
      inventory: [stock(clientId: 'water', quantity: 5)],
      checklist: [
        task(
          clientId: 'a',
          linkedInventoryItemId: 'water',
          targetQuantity: 20,
        ),
      ],
    );

    expect(find.textContaining('1 von 6'), findsOneWidget);
  });

  testWidgets('a task linked to nothing on the shelf does not count', (
    tester,
  ) async {
    await show(
      tester,
      inventory: [stock(clientId: 'water', quantity: 40)],
      checklist: [task(clientId: 'a', linkedInventoryItemId: 'batteries')],
    );

    expect(find.textContaining('1 von 6'), findsOneWidget);
  });

  testWidgets('the screen meets the accessibility guidelines', (tester) async {
    await show(tester, inventory: [stock(clientId: 'water', quantity: 40)]);
    await expectAccessible(tester);
  });

  testWidgets('the screen survives twice the font size', (tester) async {
    useLargeText(tester);
    await show(tester, inventory: [stock(clientId: 'water', quantity: 40)]);
  });
}
