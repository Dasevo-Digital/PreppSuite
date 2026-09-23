import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../model/household_profile.dart';
import 'additional_regions_card.dart';
import 'my_region_card.dart';

/// One place for the regions whose warnings matter to this household.
///
/// Map markers remain device-local personal places. This screen is only for
/// warning subscriptions, so an additional region can never accidentally
/// become a published contact or a navigation destination.
class FollowedPlacesScreen extends StatelessWidget {
  const FollowedPlacesScreen({super.key, required this.profile});

  final HouseholdProfile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.followedPlacesTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Card(
            color: theme.colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.followedPlacesIntro,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(l10n.followedPlacesPrimary, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          MyRegionCard(profile: profile, l10n: l10n),
          const SizedBox(height: 24),
          Text(
            l10n.followedPlacesAdditional,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          AdditionalRegionsCard(profile: profile, l10n: l10n),
        ],
      ),
    );
  }
}
