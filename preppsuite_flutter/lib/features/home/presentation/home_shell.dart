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
import '../../knowledge/presentation/knowledge_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../shelters/presentation/shelter_map_screen.dart';
import '../../warnings/presentation/warning_banner.dart';
import '../application/shell_layout.dart';

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
      const KnowledgeScreen(),
    ];

    final navigation = shellNavigationFor(MediaQuery.sizeOf(context).width);
    final content = IndexedStack(index: _index, children: screens);

    return Scaffold(
      // The warning banner sits above every tab, which puts it at the very
      // top of the body — underneath the status bar, where iOS draws the
      // clock straight through it. Consuming the inset here rather than in
      // the banner keeps it right when no warning is showing either: the
      // tab below would otherwise be handed a top inset that nothing above
      // it had used. The bottom is only ours when there is no bar down
      // there to have dealt with it.
      body: SafeArea(
        bottom: navigation != ShellNavigation.bar,
        child: Column(
          children: [
            // Zero-sized; keeps scheduled expiry reminders in step with the
            // inventory for as long as any tab is open.
            ExpiryReminderScheduler(householdId: householdId),
            // Above the rail as well as the tabs: a warning concerns the
            // whole app, so it gets the whole width.
            WarningBanner(profile: widget.profile),
            Expanded(
              child: navigation == ShellNavigation.bar
                  ? content
                  : Row(
                      children: [
                        _rail(l10n, attentionCount, navigation),
                        const VerticalDivider(width: 1, thickness: 1),
                        Expanded(child: content),
                      ],
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: navigation != ShellNavigation.bar
          ? null
          : NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: _select,
              destinations: [
                for (final destination in _destinations(l10n, attentionCount))
                  NavigationDestination(
                    icon: destination.icon,
                    selectedIcon: destination.selectedIcon,
                    label: destination.label,
                  ),
              ],
            ),
    );
  }

  void _select(int index) => setState(() => _index = index);

  /// The rail, made to scroll rather than overflow.
  ///
  /// Seven destinations do not fit above each other in a window someone
  /// has dragged short, and a rail has no scrolling of its own. The
  /// minimum height is what keeps its background filling the side when
  /// they do fit.
  Widget _rail(
    AppLocalizations l10n,
    int attentionCount,
    ShellNavigation navigation,
  ) {
    final extended = navigation == ShellNavigation.extendedRail;

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: IntrinsicHeight(
            child: NavigationRail(
              extended: extended,
              // An extended rail writes its labels beside the icons and
              // refuses to be told to do both.
              labelType: extended ? null : NavigationRailLabelType.all,
              selectedIndex: _index,
              onDestinationSelected: _select,
              destinations: [
                for (final destination in _destinations(l10n, attentionCount))
                  NavigationRailDestination(
                    icon: destination.icon,
                    selectedIcon: destination.selectedIcon,
                    label: Text(destination.label),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Written once and drawn two ways, so a destination cannot end up in
  /// the bar and not the rail.
  List<_Destination> _destinations(AppLocalizations l10n, int attentionCount) {
    return [
      _Destination(
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
      _Destination(
        icon: const Icon(Icons.checklist_outlined),
        selectedIcon: const Icon(Icons.checklist),
        label: l10n.navChecklists,
      ),
      _Destination(
        icon: const Icon(Icons.savings_outlined),
        selectedIcon: const Icon(Icons.savings),
        label: l10n.navBudget,
      ),
      _Destination(
        icon: const Icon(Icons.home_outlined),
        selectedIcon: const Icon(Icons.home),
        label: l10n.navHousehold,
      ),
      _Destination(
        icon: const Icon(Icons.settings_outlined),
        selectedIcon: const Icon(Icons.settings),
        label: l10n.navSettings,
      ),
      _Destination(
        icon: const Icon(Icons.shield_outlined),
        selectedIcon: const Icon(Icons.shield),
        label: l10n.navShelters,
      ),
      _Destination(
        icon: const Icon(Icons.menu_book_outlined),
        selectedIcon: const Icon(Icons.menu_book),
        label: l10n.navKnowledge,
      ),
    ];
  }
}

/// One place to go, independent of what draws it.
class _Destination {
  const _Destination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final Widget icon;
  final Widget selectedIcon;
  final String label;
}
