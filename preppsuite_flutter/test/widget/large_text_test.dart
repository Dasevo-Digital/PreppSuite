import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/budget/application/budget_providers.dart';
import 'package:preppsuite_flutter/features/budget/presentation/budget_entry_form_screen.dart';
import 'package:preppsuite_flutter/features/budget/presentation/budget_list_screen.dart';
import 'package:preppsuite_flutter/features/checklists/application/checklist_providers.dart';
import 'package:preppsuite_flutter/features/checklists/presentation/checklist_detail_screen.dart';
import 'package:preppsuite_flutter/features/checklists/presentation/checklist_list_screen.dart';
import 'package:preppsuite_flutter/features/household/application/household_member_controller.dart';
import 'package:preppsuite_flutter/features/household/application/household_providers.dart';
import 'package:preppsuite_flutter/features/household/application/household_plan_controller.dart';
import 'package:preppsuite_flutter/features/household/presentation/emergency_card_form_screen.dart';
import 'package:preppsuite_flutter/features/household/presentation/emergency_cards_screen.dart';
import 'package:preppsuite_flutter/features/household/presentation/household_overview_screen.dart';
import 'package:preppsuite_flutter/features/household/presentation/household_plan_screen.dart';
import 'package:preppsuite_flutter/features/household/presentation/profile_setup_screen.dart';
import 'package:preppsuite_flutter/features/inventory/application/inventory_providers.dart';
import 'package:preppsuite_flutter/features/inventory/presentation/inventory_csv_import_screen.dart';
import 'package:preppsuite_flutter/features/inventory/presentation/inventory_item_form_screen.dart';
import 'package:preppsuite_flutter/features/first_aid/application/first_aid_providers.dart';
import 'package:preppsuite_flutter/features/first_aid/presentation/compression_pacer_screen.dart';
import 'package:preppsuite_flutter/features/first_aid/presentation/first_aid_guide_screen.dart';
import 'package:preppsuite_flutter/features/first_aid/presentation/first_aid_screen.dart';
import 'package:preppsuite_flutter/features/first_aid/presentation/first_aid_videos_screen.dart';
import 'package:preppsuite_flutter/features/energy/presentation/outage_screen.dart';
import 'package:preppsuite_flutter/features/inventory/presentation/medication_range_screen.dart';
import 'package:preppsuite_flutter/features/inventory/presentation/rotation_screen.dart';
import 'package:preppsuite_flutter/features/possessions/application/possession_controller.dart';
import 'package:preppsuite_flutter/features/possessions/presentation/possession_form_screen.dart';
import 'package:preppsuite_flutter/features/possessions/presentation/possessions_screen.dart';
import 'package:preppsuite_flutter/features/inventory/presentation/shopping_list_screen.dart';
import 'package:preppsuite_flutter/features/settings/presentation/settings_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:preppsuite_flutter/local_db/database.dart';
import 'package:preppsuite_flutter/model/household_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'accessibility.dart';

/// Stands in for the real profile, which loads from preferences.
class _FixedProfile extends HouseholdProfileController {
  _FixedProfile(this.profile);

  final HouseholdProfile profile;

  @override
  Future<HouseholdProfile?> build() async => profile;
}

/// Every screen that has no widget test of its own, rendered at twice the
/// system font size.
///
/// Doubling the font is what somebody with low vision actually does first,
/// and it is the one setting that breaks layouts wholesale: a Row of two
/// labels that fitted at 100% overflows at 200%, and Flutter's answer to an
/// overflow is to clip — silently, in a release build. So this pumps each
/// screen and lets the framework's own overflow error fail the test.
///
/// It is deliberately shallow. These are not tests of what the screens do;
/// each one only has to render. The screens that carry their own widget
/// test check the same thing there, next to the behaviour.
///
/// Four screens are missing and stay missing: `ArticleScreen` needs a ZIM
/// archive open, `PhotoEditorScreen` an image on disk, `ShelterMapScreen`
/// reaches two web services from `initState` (its list is covered in
/// `shelter_list_test.dart`), and `BarcodeScannerScreen` wants a camera.
void main() {
  const householdId = 'household-1';
  late AppDatabase db;

  const profile = HouseholdProfile(
    id: householdId,
    name: 'Testhaushalt',
    countryCode: 'DE',
    regionKey: '03241',
    personCount: 2,
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  /// A phone in portrait, which is where the font size actually bites: on
  /// a desktop window there is room for almost anything.
  Future<void> pump(WidgetTester tester, Widget home) async {
    useLargeText(tester);
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          // Served as plain values: a real drift stream needs the event
          // loop to turn, which the tester's clock does not do, and
          // `pumpAndSettle` would spin on the spinner until it times out.
          inventoryItemsProvider(
            householdId,
          ).overrideWith((ref) => Stream.value(const [])),
          budgetEntriesProvider(
            householdId,
          ).overrideWith((ref) => Stream.value(const [])),
          checklistTemplatesProvider(
            householdId,
          ).overrideWith((ref) => Stream.value(const [])),
          householdMembersProvider(
            householdId,
          ).overrideWith((ref) => Stream.value(const [])),
          householdPlanProvider(
            householdId,
          ).overrideWith((ref) => Stream.value(null)),
          possessionsProvider(
            householdId,
          ).overrideWith((ref) => Stream.value(const [])),
          checklistItemsProvider(
            'template-1',
          ).overrideWith((ref) => Stream.value(const [])),
          householdProfileProvider.overrideWith(() => _FixedProfile(profile)),
          // The first aid screens read the download folder to find a
          // video pack, and path_provider has no implementation here.
          // Nothing installed is also the state that renders the most
          // text, which is what this test is looking at.
          installedFirstAidPackProvider.overrideWith(
            (ref) async => InstalledFirstAidPack.none,
          ),
          firstAidPackUrlProvider.overrideWith((ref) async => ''),
        ],
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: home,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the budget list', (tester) async {
    await pump(tester, const BudgetListScreen(householdId: householdId));
  });

  testWidgets('the budget entry form', (tester) async {
    await pump(tester, const BudgetEntryFormScreen(householdId: householdId));
  });

  testWidgets('the checklist list', (tester) async {
    await pump(tester, const ChecklistListScreen(householdId: householdId));
  });

  testWidgets('the emergency cards', (tester) async {
    await pump(tester, const EmergencyCardsScreen(householdId: householdId));
  });

  testWidgets('the emergency card form', (tester) async {
    await pump(
      tester,
      const EmergencyCardFormScreen(householdId: householdId),
    );
  });

  testWidgets('the household overview', (tester) async {
    await pump(tester, const HouseholdOverviewScreen(profile: profile));
  });

  testWidgets('the possessions list', (tester) async {
    await pump(tester, const PossessionsScreen(householdId: householdId));
  });

  testWidgets('the possession form', (tester) async {
    await pump(tester, const PossessionFormScreen(householdId: householdId));
  });

  testWidgets('the medication reach', (tester) async {
    await pump(tester, const MedicationRangeScreen(householdId: householdId));
  });

  testWidgets('the first aid list', (tester) async {
    await pump(tester, const FirstAidScreen());
  });

  testWidgets('a first aid guide with a drawing, figures and the pacer', (
    tester,
  ) async {
    // Resuscitation is the guide that carries every part this screen can
    // show at once, so it is the one that overflows first.
    await pump(tester, const FirstAidGuideScreen(guideId: 'cpr-adult'));
  });

  testWidgets('a first aid guide that is a list of telephone numbers', (
    tester,
  ) async {
    await pump(tester, const FirstAidGuideScreen(guideId: 'poisoning'));
  });

  testWidgets('the compression pacer', (tester) async {
    await pump(tester, const CompressionPacerScreen());
  });

  testWidgets('the video pack screen', (tester) async {
    await pump(tester, const FirstAidVideosScreen());
  });

  testWidgets('the blackout clock', (tester) async {
    await pump(tester, const OutageScreen());
  });

  testWidgets('the household plan', (tester) async {
    await pump(tester, const HouseholdPlanScreen(householdId: householdId));
  });

  testWidgets('the profile setup', (tester) async {
    await pump(tester, const ProfileSetupScreen());
  });

  testWidgets('the rotation list', (tester) async {
    await pump(tester, const RotationScreen(householdId: householdId));
  });

  testWidgets('the shopping list', (tester) async {
    await pump(tester, const ShoppingListScreen(householdId: householdId));
  });

  testWidgets('the CSV import', (tester) async {
    await pump(
      tester,
      const InventoryCsvImportScreen(householdId: householdId),
    );
  });

  testWidgets('the item form', (tester) async {
    await pump(
      tester,
      const InventoryItemFormScreen(householdId: householdId),
    );
  });

  testWidgets('the settings', (tester) async {
    await pump(tester, const SettingsScreen(profile: profile));
  });

  testWidgets('a checklist in detail', (tester) async {
    final template = ChecklistTemplate(
      clientId: 'template-1',
      householdId: householdId,
      title: 'Notgepäck',
      category: 'evacuation',
      kind: 'preparation',
      isBuiltIn: true,
      updatedAt: DateTime.utc(2026),
      dirty: false,
    );
    await pump(
      tester,
      ChecklistDetailScreen(template: template, householdId: householdId),
    );
  });
}
