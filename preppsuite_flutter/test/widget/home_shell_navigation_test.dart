import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/checklists/application/checklist_providers.dart';
import 'package:preppsuite_flutter/features/home/presentation/home_shell.dart';
import 'package:preppsuite_flutter/features/inventory/application/inventory_providers.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_providers.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:preppsuite_flutter/local_db/database.dart';
import 'package:preppsuite_flutter/model/household_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<void> pumpPhoneShell(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          inventoryItemsProvider('h').overrideWith((ref) => Stream.value([])),
          activeWarningsProvider.overrideWith((ref) => Stream.value([])),
          checklistTemplatesProvider(
            'h',
          ).overrideWith((ref) => Stream.value([])),
          allChecklistItemsProvider(
            'h',
          ).overrideWith((ref) => Stream.value([])),
        ],
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const HomeShell(
            profile: HouseholdProfile(
              id: 'h',
              name: 'Zuhause',
              countryCode: 'DE',
            ),
          ),
        ),
      ),
    );
    // Do not settle through the reminder schedulers' debounce interval:
    // their platform-notification implementation is intentionally not part
    // of this navigation test.
    await tester.pump();
    await tester.pump();
  }

  Finder barDestinations() => find.descendant(
    of: find.byType(NavigationBar),
    matching: find.byType(NavigationDestination),
  );

  Future<void> openMore(WidgetTester tester) async {
    await tester.tap(barDestinations().last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }

  testWidgets('phone overflow can scroll as far as Settings', (tester) async {
    // This catches the Android regression where the fixed-height More sheet
    // ended above Settings and left the entry unreachable.
    await pumpPhoneShell(tester);

    expect(find.byType(NavigationBar), findsOneWidget);
    await openMore(tester);

    final settings = find.text('Einstellungen');
    await tester.dragUntilVisible(
      settings,
      find.byType(DraggableScrollableSheet),
      const Offset(0, -280),
    );

    await tester.pump();

    expect(settings, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a screen behind More leaves the bar as it was', (tester) async {
    // The bar used to hand its last slot to whatever was open, which meant
    // that slot had to hold "Einstellungen" — thirteen characters in a fifth
    // of a phone. It wrapped, and the bar's fixed height cut the second line
    // off. Now the bar stands still and the More button says where you are.
    await pumpPhoneShell(tester);

    List<String> barLabels() => tester
        .widgetList<NavigationDestination>(barDestinations())
        .map((destination) => destination.label)
        .toList();

    const before = ['Übersicht', 'Notfall', 'Vorrat', 'Listen', 'Mehr'];
    expect(barLabels(), before);

    await openMore(tester);
    final settings = find.text('Einstellungen');
    await tester.dragUntilVisible(
      settings,
      find.byType(DraggableScrollableSheet),
      const Offset(0, -280),
    );
    // The tap sets the shell's state directly, so one frame is enough —
    // and the reminder scheduler's 500 ms debounce must not be crossed,
    // because its platform notifications are no part of this test.
    await tester.tap(settings);
    await tester.pump();

    expect(barLabels(), before, reason: 'the bar rearranged itself');
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      before.length - 1,
      reason: 'the More button should be the place you are',
    );
    expect(tester.takeException(), isNull);
  });
}
