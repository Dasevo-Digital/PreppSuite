import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../model/household_profile.dart';
import '../application/household_providers.dart';

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
                ListTile(
                  leading: const Icon(Icons.people_outline),
                  title: Text(l10n.personCountLabel),
                  trailing: _PersonCountStepper(profile: profile),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonCountStepper extends ConsumerWidget {
  const _PersonCountStepper({required this.profile});

  final HouseholdProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> setCount(int value) => ref
        .read(householdProfileProvider.notifier)
        .save(profile.copyWith(personCount: value));

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: profile.personCount > 1
              ? () => setCount(profile.personCount - 1)
              : null,
        ),
        Text(
          '${profile.personCount}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: () => setCount(profile.personCount + 1),
        ),
      ],
    );
  }
}
