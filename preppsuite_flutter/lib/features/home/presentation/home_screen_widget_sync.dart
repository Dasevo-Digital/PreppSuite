import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../model/household_profile.dart';
import '../../inventory/application/inventory_providers.dart';
import '../../inventory/application/supply_calculator.dart';
import '../../warnings/application/warning_providers.dart';
import '../../warnings/application/warning_relevance.dart';
import '../application/home_screen_widget.dart';
import '../application/status_lights.dart';

/// Keeps the home screen widget in step with the overview's two lamps
/// (#105). Draws nothing.
///
/// It sits in the shell beside the warning banner, so it runs whichever
/// tab is open, and it reads exactly what `StatusLightsRow` reads. The
/// publisher skips a snapshot that changed nothing, so a rebuild for an
/// unrelated reason costs a comparison and no platform call.
class HomeScreenWidgetSync extends ConsumerStatefulWidget {
  const HomeScreenWidgetSync({super.key, required this.profile});

  final HouseholdProfile profile;

  @override
  ConsumerState<HomeScreenWidgetSync> createState() =>
      _HomeScreenWidgetSyncState();
}

class _HomeScreenWidgetSyncState extends ConsumerState<HomeScreenWidgetSync> {
  final _publisher = HomeWidgetPublisher();

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final items = ref.watch(inventoryItemsProvider(profile.id)).value;
    final active = ref.watch(activeWarningsProvider).value;
    // Nothing until both have arrived: a first frame with an empty list
    // would put "nothing entered" on the home screen for a moment.
    if (items != null && active != null) {
      final supply = supplyStatus(
        items: items,
        household: SupplyHousehold(
          adults: profile.personCount,
          children: profile.children,
          dogs: profile.dogs,
          cats: profile.cats,
        ),
      );
      final situation = situationStatus([
        for (final warning in active)
          if (isWarningRelevant(
            warning: warning,
            filter: profile.warningFilter,
          ))
            warning,
      ]);
      final snapshot = buildHomeWidgetSnapshot(
        supply: supply,
        situation: situation,
        l10n: AppLocalizations.of(context)!,
        time: TimeOfDay.now().format(context),
      );
      unawaited(_publisher.publish(snapshot));
    }
    return const SizedBox.shrink();
  }
}
