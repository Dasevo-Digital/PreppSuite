import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../model/household_profile.dart';
import '../application/household_providers.dart';
import '../application/household_plan_controller.dart';
import 'household_plan_screen.dart';
import '../application/household_member_controller.dart';
import 'emergency_cards_screen.dart';

/// The household's own details.
///
/// What used to be here — invite code, member list, roles, sign out — was
/// all server machinery. What is left is what the app actually needs to
/// know: who this household is, where it is, and how many people it feeds.
class HouseholdOverviewScreen extends ConsumerWidget {
  const HouseholdOverviewScreen({super.key, required this.profile});

  final HouseholdProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(profile.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Consumer(
              builder: (context, ref, _) {
                final plan = ref.watch(householdPlanProvider(profile.id)).value;
                return ListTile(
                  leading: const Icon(Icons.emergency_share_outlined),
                  title: Text(l10n.householdPlanTitle),
                  // Says whether there is one, because a plan nobody wrote
                  // is the case this screen exists to make visible.
                  subtitle: Text(
                    plan?.meetingPointNear ??
                        plan?.contactName ??
                        l10n.householdPlanEmpty,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          HouseholdPlanScreen(householdId: profile.id),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Consumer(
              builder: (context, ref, _) {
                final members =
                    ref.watch(householdMembersProvider(profile.id)).value ??
                    const [];
                return ListTile(
                  leading: const Icon(Icons.medical_information_outlined),
                  title: Text(l10n.emergencyCardsTitle),
                  subtitle: Text(
                    members.isEmpty
                        ? l10n.emergencyCardsEmpty
                        : l10n.emergencyCardsCount(members.length),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          EmergencyCardsScreen(householdId: profile.id),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.home_outlined),
                  title: Text(l10n.householdNameLabel),
                  subtitle: Text(profile.name),
                ),
                ListTile(
                  leading: const Icon(Icons.public),
                  title: Text(l10n.countryLabel),
                  subtitle: Text(profile.countryCode),
                ),
                ListTile(
                  leading: const Icon(Icons.place_outlined),
                  title: Text(l10n.regionKeyLabel),
                  subtitle: Text(profile.regionKey ?? l10n.settingsNoRegionSet),
                ),
                // Everyone the supply calculator has to plan for lives
                // here, and only here. The inventory screen used to keep
                // a second person count of its own.
                _CountTile(
                  icon: Icons.people_outline,
                  label: l10n.householdAdultsLabel,
                  value: profile.personCount,
                  minimum: 1,
                  onChanged: (value) => _save(
                    ref,
                    profile.copyWith(personCount: value),
                  ),
                ),
                _CountTile(
                  icon: Icons.child_care_outlined,
                  label: l10n.householdChildrenLabel,
                  value: profile.children,
                  onChanged: (value) =>
                      _save(ref, profile.copyWith(children: value)),
                ),
                _CountTile(
                  icon: Icons.pets_outlined,
                  label: l10n.householdDogsLabel,
                  value: profile.dogs,
                  onChanged: (value) =>
                      _save(ref, profile.copyWith(dogs: value)),
                ),
                _CountTile(
                  icon: Icons.pets,
                  label: l10n.householdCatsLabel,
                  value: profile.cats,
                  onChanged: (value) =>
                      _save(ref, profile.copyWith(cats: value)),
                ),
                ExpansionTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(l10n.supplyCalculatorSourceTitle),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    Text(
                      l10n.supplyCalculatorSourceBody,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void _save(WidgetRef ref, HouseholdProfile profile) =>
    ref.read(householdProfileProvider.notifier).save(profile);

class _CountTile extends StatelessWidget {
  const _CountTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    this.minimum = 0,
  });

  final IconData icon;
  final String label;
  final int value;
  final int minimum;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            tooltip: l10n.stepperDecrease(label),
            onPressed: value > minimum ? () => onChanged(value - 1) : null,
          ),
          Text(
            '$value',
            style: Theme.of(context).textTheme.titleMedium,
            semanticsLabel: l10n.stepperValue(label, value),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: l10n.stepperIncrease(label),
            onPressed: () => onChanged(value + 1),
          ),
        ],
      ),
    );
  }
}
