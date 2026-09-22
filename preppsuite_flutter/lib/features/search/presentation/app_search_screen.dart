import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_destinations.dart';
import '../../../core/content_swap.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../model/household_profile.dart';
import '../../checklists/application/checklist_providers.dart';
import '../../checklists/presentation/checklist_detail_screen.dart';
import '../../home/application/shell_layout.dart';
import '../../inventory/application/inventory_providers.dart';
import '../../inventory/presentation/inventory_item_form_screen.dart';
import '../../possessions/application/possession_controller.dart';
import '../../possessions/presentation/possession_form_screen.dart';
import '../application/app_search.dart';

/// One place to ask where something is.
///
/// It searches four things: the screens themselves, the stock, what is
/// written on the checklists, and the household inventory. Those are the
/// lists somebody keeps adding to, and the ones that therefore stop
/// being findable by scrolling.
///
/// **The emergency cards are deliberately not in it.** They are health
/// data, and a general-purpose result list that puts a diagnosis two
/// rows under a tin of beans is the wrong place for them to turn up —
/// including in front of whoever happens to be holding the phone. They
/// have their own screen, which says what they are before anything is
/// typed into it.
class AppSearchScreen extends ConsumerStatefulWidget {
  const AppSearchScreen({
    super.key,
    required this.profile,
    required this.onNavigate,
  });

  final HouseholdProfile profile;

  /// Switching tab, for the results that are a tab rather than a screen
  /// to push. The search closes first either way.
  final ValueChanged<ShellDestination> onNavigate;

  @override
  ConsumerState<AppSearchScreen> createState() => _AppSearchScreenState();
}

class _AppSearchScreenState extends ConsumerState<AppSearchScreen> {
  final _controller = TextEditingController();
  var _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final householdId = widget.profile.id;

    final destinations = appDestinations();
    final inventory =
        ref.watch(inventoryItemsProvider(householdId)).value ?? const [];
    final templates =
        ref.watch(checklistTemplatesProvider(householdId)).value ?? const [];
    final checklistItems =
        ref.watch(allChecklistItemsProvider(householdId)).value ?? const [];
    final possessions =
        ref.watch(possessionsProvider(householdId)).value ?? const [];

    final templatesById = {for (final t in templates) t.clientId: t};
    final candidates = <String, _Target>{};
    final list = <SearchCandidate>[];

    void offer(SearchCandidate candidate, _Target target) {
      candidates[candidate.key] = target;
      list.add(candidate);
    }

    for (final destination in destinations) {
      offer(
        SearchCandidate(
          key: 'screen:${destination.id}',
          label: destination.title(l10n),
          context: _areaName(l10n, destination.area),
          aliases: destination.aliases,
        ),
        _Target(icon: destination.icon, open: () => _go(destination)),
      );
    }

    for (final item in inventory) {
      offer(
        SearchCandidate(
          key: 'stock:${item.clientId}',
          label: item.name,
          context: item.storageLocation,
        ),
        _Target(
          icon: Icons.inventory_2_outlined,
          group: l10n.searchGroupInventory,
          open: () => _push(
            InventoryItemFormScreen(householdId: householdId, existing: item),
          ),
        ),
      );
    }

    for (final template in templates) {
      offer(
        SearchCandidate(
          key: 'list:${template.clientId}',
          label: template.title,
          context: l10n.checklistsTitle,
        ),
        _Target(
          icon: Icons.checklist_outlined,
          group: l10n.searchGroupChecklists,
          open: () => _push(
            ChecklistDetailScreen(
              template: template,
              householdId: householdId,
            ),
          ),
        ),
      );
    }

    for (final item in checklistItems) {
      final template = templatesById[item.templateClientId];
      if (template == null) continue;
      offer(
        SearchCandidate(
          key: 'entry:${item.clientId}',
          label: item.title,
          // The list it belongs to, which is both where it is and the
          // only way to tell two identical entries apart.
          context: template.title,
        ),
        _Target(
          icon: Icons.check_box_outlined,
          group: l10n.searchGroupChecklists,
          open: () => _push(
            ChecklistDetailScreen(
              template: template,
              householdId: householdId,
            ),
          ),
        ),
      );
    }

    for (final possession in possessions) {
      offer(
        SearchCandidate(
          key: 'owned:${possession.clientId}',
          label: possession.name,
          context: possession.room,
        ),
        _Target(
          icon: Icons.chair_outlined,
          group: l10n.searchGroupPossessions,
          open: () => _push(
            PossessionFormScreen(
              householdId: householdId,
              existing: possession,
            ),
          ),
        ),
      );
    }

    final matches = searchCandidates(_query, list);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: l10n.searchHint,
            border: InputBorder.none,
            filled: false,
          ),
          onChanged: (value) => setState(() => _query = value),
        ),
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: MaterialLocalizations.of(context).cancelButtonLabel,
              onPressed: () {
                _controller.clear();
                setState(() => _query = '');
              },
            ),
        ],
      ),
      body: ContentSwap(
        child: _query.trim().isEmpty
            ? _Message(text: l10n.searchStartHint, key: const ValueKey('hint'))
            : matches.isEmpty
            ? _Message(
                text: l10n.searchNothingFound(_query.trim()),
                key: const ValueKey('none'),
              )
            : ListView.builder(
                key: const ValueKey('results'),
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: matches.length,
                itemBuilder: (context, index) {
                  final match = matches[index];
                  final target = candidates[match.candidate.key]!;
                  final where = [
                    ?target.group,
                    ?match.candidate.context,
                  ].join(' · ');

                  return ListTile(
                    leading: Icon(target.icon),
                    title: Text(match.candidate.label),
                    subtitle: where.isEmpty
                        ? null
                        : Text(
                            where,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                    onTap: target.open,
                  );
                },
              ),
      ),
    );
  }

  /// A screen to push, or a tab to switch to. Either way the search
  /// closes first: it is a way to somewhere, not somewhere to come back
  /// to, and a back button that lands on a stale result list would be.
  void _go(AppDestination destination) {
    final navigator = Navigator.of(context);
    final profile = widget.profile;
    navigator.pop();
    if (destination.isTab) {
      widget.onNavigate(destination.area);
    } else {
      navigator.push(
        MaterialPageRoute<void>(builder: (_) => destination.open!(profile)),
      );
    }
  }

  void _push(Widget screen) {
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  static String _areaName(AppLocalizations l10n, ShellDestination area) {
    return switch (area) {
      ShellDestination.overview => l10n.navOverview,
      ShellDestination.emergency => l10n.emergencyTitle,
      ShellDestination.inventory => l10n.inventoryTitle,
      ShellDestination.checklists => l10n.checklistsTitle,
      ShellDestination.warnings => l10n.warningsTitle,
      ShellDestination.shelters => l10n.shelterMapTitle,
      ShellDestination.map => l10n.navMap,
      ShellDestination.knowledge => l10n.knowledgeTitle,
      ShellDestination.household => l10n.navHousehold,
      ShellDestination.settings => l10n.navSettings,
    };
  }
}

/// What a result does when it is tapped, and what it looks like.
class _Target {
  const _Target({required this.icon, required this.open, this.group});

  final IconData icon;
  final VoidCallback open;

  /// Which of the four lists it came from. Null for a screen, whose
  /// tab name says it better.
  final String? group;
}

class _Message extends StatelessWidget {
  const _Message({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// Opens the search, from wherever asked.
///
/// One function rather than a route constant, because two callers want
/// it for different reasons — a button on the first screen, and a
/// keyboard shortcut that works on any of them — and both should land in
/// exactly the same place.
Future<void> openAppSearch(
  BuildContext context,
  HouseholdProfile profile,
  ValueChanged<ShellDestination> onNavigate,
) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => AppSearchScreen(profile: profile, onNavigate: onNavigate),
    ),
  );
}
