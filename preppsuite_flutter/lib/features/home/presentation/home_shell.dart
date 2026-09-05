import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../model/household_profile.dart';
import '../../budget/presentation/budget_list_screen.dart';
import '../../checklists/presentation/checklist_list_screen.dart';
import '../../household/presentation/household_overview_screen.dart';
import '../../inventory/application/inventory_providers.dart';
import '../../inventory/presentation/expiry_reminder_scheduler.dart';
import '../../inventory/presentation/inventory_list_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../shelters/presentation/shelter_map_screen.dart';
import '../../warnings/presentation/warning_banner.dart';

/// Top-level navigation once a profile exists. Only lists destinations
/// that have real content — the warning banner sits above every tab rather
/// than being its own destination, since it's meant to be seen regardless
/// of which tab is open, not sought out.
///
/// The sync scheduler and its status banner used to live here too. Both
/// are gone with the server: there is no pass to schedule and no "last
/// sync failed" state to report.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key, required this.profile});

  final HouseholdProfile profile;

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final householdId = widget.profile.id;
    final attentionCount = ref.watch(
      inventoryAttentionCountProvider(householdId),
    );

    final screens = [
      InventoryListScreen(householdId: householdId),
      ChecklistListScreen(householdId: householdId),
      BudgetListScreen(householdId: householdId),
      HouseholdOverviewScreen(profile: widget.profile),
      SettingsScreen(profile: widget.profile),
      const ShelterMapScreen(),
    ];

    return Scaffold(
      body: Column(
        children: [
          // Zero-sized; keeps scheduled expiry reminders in step with the
          // inventory for as long as any tab is open.
          ExpiryReminderScheduler(householdId: householdId),
          WarningBanner(profile: widget.profile),
          Expanded(
            child: IndexedStack(index: _index, children: screens),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: [
          NavigationDestination(
            icon: attentionCount == 0
                ? const Icon(Icons.inventory_2_outlined)
                : Tooltip(
                    message: l10n.inventoryAttentionTooltip(attentionCount),
                    child: Badge(
                      label: Text('$attentionCount'),
                      child: const Icon(Icons.inventory_2_outlined),
                    ),
                  ),
            selectedIcon: const Icon(Icons.inventory_2),
            label: l10n.navInventory,
          ),
          NavigationDestination(
            icon: const Icon(Icons.checklist_outlined),
            selectedIcon: const Icon(Icons.checklist),
            label: l10n.navChecklists,
          ),
          NavigationDestination(
            icon: const Icon(Icons.savings_outlined),
            selectedIcon: const Icon(Icons.savings),
            label: l10n.navBudget,
          ),
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: l10n.navHousehold,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l10n.navSettings,
          ),
          NavigationDestination(
            icon: const Icon(Icons.shield_outlined),
            selectedIcon: const Icon(Icons.shield),
            label: l10n.navShelters,
          ),
        ],
      ),
    );
  }
}
