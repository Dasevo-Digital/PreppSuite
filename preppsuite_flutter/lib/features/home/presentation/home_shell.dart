import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../core/feature_activity.dart';
import '../../../model/household_profile.dart';
import '../../budget/presentation/budget_list_screen.dart';
import '../../checklists/presentation/checklist_list_screen.dart';
import '../../household/presentation/household_overview_screen.dart';
import '../../inventory/application/inventory_providers.dart';
import '../../inventory/presentation/expiry_reminder_scheduler.dart';
import '../../inventory/presentation/inventory_list_screen.dart';
import '../../knowledge/presentation/knowledge_screen.dart';
import '../../maps/presentation/map_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../shelters/presentation/shelter_map_screen.dart';
import '../../warnings/application/warning_providers.dart';
import '../../warnings/application/warning_relevance.dart';
import '../../warnings/presentation/warning_banner.dart';
import '../../warnings/presentation/warning_list_screen.dart';
import '../application/shell_layout.dart';
import 'overview_screen.dart';

/// Top-level navigation once a profile exists.
///
/// The warning banner still sits above every tab — a warning is meant to
/// be seen whatever is open, not sought out. Warnings are now *also* a
/// destination of their own, because the banner shows one warning and the
/// screen behind it shows the history, the filters and the ones that
/// concern somewhere else.
///
/// Ten destinations do not fit across a phone. `shellSlotsFor` decides
/// which ones the bar shows and which go behind "more"; the rail, which
/// has the room, shows all of them.
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
  ShellDestination _selected = ShellDestination.overview;
  final _visited = {ShellDestination.overview};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final householdId = widget.profile.id;

    final navigation = shellNavigationFor(MediaQuery.sizeOf(context).width);
    final slots = shellSlotsFor(navigation: navigation, selected: _selected);

    // Build destinations on first use and retain their navigation state.
    // Inactive maps release renderers through FeatureActivity.
    final content = IndexedStack(
      index: _selected.index,
      children: [
        for (final destination in ShellDestination.values)
          _visited.contains(destination)
              ? FeatureActivity(
                  active: destination == _selected,
                  child: TickerMode(
                    enabled: destination == _selected,
                    child: _screenFor(destination, householdId),
                  ),
                )
              : const SizedBox.shrink(),
      ],
    );

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
                        _rail(l10n, slots, navigation),
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
          : _bar(l10n, slots),
    );
  }

  Widget _screenFor(ShellDestination destination, String householdId) {
    return switch (destination) {
      ShellDestination.overview => OverviewScreen(
        profile: widget.profile,
        onNavigate: _select,
      ),
      ShellDestination.inventory => InventoryListScreen(
        householdId: householdId,
      ),
      ShellDestination.checklists => ChecklistListScreen(
        householdId: householdId,
      ),
      ShellDestination.warnings => WarningListScreen(profile: widget.profile),
      ShellDestination.shelters => const ShelterMapScreen(),
      ShellDestination.map => const MapScreen(),
      ShellDestination.knowledge => const KnowledgeScreen(),
      ShellDestination.budget => BudgetListScreen(householdId: householdId),
      ShellDestination.household => HouseholdOverviewScreen(
        profile: widget.profile,
      ),
      ShellDestination.settings => SettingsScreen(profile: widget.profile),
    };
  }

  void _select(ShellDestination destination) => setState(() {
    _selected = destination;
    _visited.add(destination);
  });

  Widget _bar(AppLocalizations l10n, ShellSlots slots) {
    final entries = [
      for (final destination in slots.visible) _entry(l10n, destination),
    ];

    // `shellSlotsFor` guarantees the open destination is among the
    // visible ones, so this never comes back -1.
    return NavigationBar(
      selectedIndex: slots.visible.indexOf(_selected),
      onDestinationSelected: (index) {
        if (slots.hasOverflow && index == entries.length) {
          _showMore(l10n, slots.overflow);
          return;
        }
        _select(slots.visible[index]);
      },
      destinations: [
        for (final entry in entries)
          NavigationDestination(
            icon: entry.icon,
            selectedIcon: entry.selectedIcon,
            label: entry.label,
          ),
        if (slots.hasOverflow)
          NavigationDestination(
            icon: const Icon(Icons.more_horiz),
            label: l10n.navMore,
          ),
      ],
    );
  }

  /// The destinations the bar had no room for.
  Future<void> _showMore(
    AppLocalizations l10n,
    List<ShellDestination> overflow,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final destination in overflow)
              ListTile(
                leading: _entry(l10n, destination).icon,
                title: Text(_entry(l10n, destination).label),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _select(destination);
                },
              ),
          ],
        ),
      ),
    );
  }

  /// The rail, made to scroll rather than overflow.
  ///
  /// Ten destinations do not fit above each other in a window someone
  /// has dragged short, and a rail has no scrolling of its own. The
  /// minimum height is what keeps its background filling the side when
  /// they do fit.
  Widget _rail(
    AppLocalizations l10n,
    ShellSlots slots,
    ShellNavigation navigation,
  ) {
    final extended = navigation == ShellNavigation.extendedRail;
    final entries = [
      for (final destination in slots.visible) _entry(l10n, destination),
    ];

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
              selectedIndex: slots.visible.indexOf(_selected),
              onDestinationSelected: (index) => _select(slots.visible[index]),
              destinations: [
                for (final entry in entries)
                  NavigationRailDestination(
                    icon: entry.icon,
                    selectedIcon: entry.selectedIcon,
                    label: Text(entry.label),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Written once and drawn three ways — bar, rail and "more" sheet — so
  /// a destination cannot end up in one and not the others.
  _Entry _entry(AppLocalizations l10n, ShellDestination destination) {
    return switch (destination) {
      ShellDestination.overview => _Entry(
        icon: const Icon(Icons.dashboard_outlined),
        selectedIcon: const Icon(Icons.dashboard),
        label: l10n.navOverview,
      ),
      ShellDestination.inventory => _inventoryEntry(l10n),
      ShellDestination.checklists => _Entry(
        icon: const Icon(Icons.checklist_outlined),
        selectedIcon: const Icon(Icons.checklist),
        label: l10n.navChecklists,
      ),
      ShellDestination.warnings => _warningEntry(l10n),
      ShellDestination.shelters => _Entry(
        icon: const Icon(Icons.shield_outlined),
        selectedIcon: const Icon(Icons.shield),
        label: l10n.navShelters,
      ),
      ShellDestination.map => _Entry(
        icon: const Icon(Icons.map_outlined),
        selectedIcon: const Icon(Icons.map),
        label: l10n.navMap,
      ),
      ShellDestination.knowledge => _Entry(
        icon: const Icon(Icons.menu_book_outlined),
        selectedIcon: const Icon(Icons.menu_book),
        label: l10n.navKnowledge,
      ),
      ShellDestination.budget => _Entry(
        icon: const Icon(Icons.savings_outlined),
        selectedIcon: const Icon(Icons.savings),
        label: l10n.navBudget,
      ),
      ShellDestination.household => _Entry(
        icon: const Icon(Icons.home_outlined),
        selectedIcon: const Icon(Icons.home),
        label: l10n.navHousehold,
      ),
      ShellDestination.settings => _Entry(
        icon: const Icon(Icons.settings_outlined),
        selectedIcon: const Icon(Icons.settings),
        label: l10n.navSettings,
      ),
    };
  }

  _Entry _inventoryEntry(AppLocalizations l10n) {
    final count = ref.watch(
      inventoryAttentionCountProvider(widget.profile.id),
    );

    return _Entry(
      icon: count == 0
          ? const Icon(Icons.inventory_2_outlined)
          : Tooltip(
              message: l10n.inventoryAttentionTooltip(count),
              child: Badge(
                label: Text('$count'),
                child: const Icon(Icons.inventory_2_outlined),
              ),
            ),
      selectedIcon: const Icon(Icons.inventory_2),
      label: l10n.navInventory,
    );
  }

  _Entry _warningEntry(AppLocalizations l10n) {
    // Counted with the same relevance rule the banner and the
    // notifications use, so the badge cannot say nothing while the banner
    // above it is showing one.
    final active = ref.watch(activeWarningsProvider).value ?? const [];
    final mine = active
        .where(
          (warning) => isWarningRelevant(
            warning: warning,
            filter: widget.profile.warningFilter,
          ),
        )
        .length;

    return _Entry(
      icon: mine == 0
          ? const Icon(Icons.warning_amber_outlined)
          : Badge(
              label: Text('$mine'),
              child: const Icon(Icons.warning_amber_outlined),
            ),
      selectedIcon: const Icon(Icons.warning_amber_rounded),
      label: l10n.navWarnings,
    );
  }
}

/// One place to go, independent of what draws it.
class _Entry {
  const _Entry({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final Widget icon;
  final Widget selectedIcon;
  final String label;
}
