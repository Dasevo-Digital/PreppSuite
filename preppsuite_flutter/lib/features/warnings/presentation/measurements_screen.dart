import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import 'air_quality_screen.dart';
import 'fire_danger_screen.dart';
import 'heavy_rain_screen.dart';
import 'pegel_screen.dart';
import 'radiation_screen.dart';
import 'road_closure_screen.dart';

/// The live readings and hazard maps, in one place under the warnings
/// (#187).
///
/// They used to be the second half of "Notruf, Kontakte & Funk", where
/// nobody looking for a river level would think to open them, and the
/// warnings tab -- which is where they are filed in the app's own list of
/// destinations -- did not link a single one. Each of them is a figure
/// whose meaning comes from the authority that measures it, the same as a
/// warning, and each is worthless out of date, the same as a warning.
class MeasurementsScreen extends StatelessWidget {
  const MeasurementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    Widget entry(
      IconData icon,
      String title,
      String hint,
      Widget Function() screen,
    ) => ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(hint),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => screen())),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.measurementsTitle)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          entry(
            Icons.water_outlined,
            l10n.pegelTitle,
            l10n.pegelEntryHint,
            () => const PegelScreen(),
          ),
          entry(
            Icons.radar_outlined,
            l10n.radiationTitle,
            l10n.radiationEntryHint,
            () => const RadiationScreen(),
          ),
          entry(
            Icons.air_outlined,
            l10n.airQualityTitle,
            l10n.airQualityEntryHint,
            () => const AirQualityScreen(),
          ),
          entry(
            Icons.local_fire_department_outlined,
            l10n.fireDangerTitle,
            l10n.fireDangerEntryHint,
            () => const FireDangerScreen(),
          ),
          entry(
            Icons.thunderstorm_outlined,
            l10n.heavyRainTitle,
            l10n.heavyRainEntryHint,
            () => const HeavyRainScreen(),
          ),
          // Not a measurement: this one is about leaving. "Which way is
          // open" is the question a household has when it can no longer
          // stay, and it is read the way the others are -- now, from the
          // authority, out of date by tomorrow.
          entry(
            Icons.alt_route_outlined,
            l10n.roadClosureTitle,
            l10n.roadClosureEntryHint,
            () => const RoadClosureScreen(),
          ),
        ],
      ),
    );
  }
}

/// The way into [MeasurementsScreen] from the warnings list: a card that
/// scrolls with the list, after the warnings, so it never pushes one of
/// them down.
class MeasurementsCard extends StatelessWidget {
  const MeasurementsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      child: ListTile(
        leading: const Icon(Icons.sensors_outlined),
        title: Text(l10n.measurementsTitle),
        subtitle: Text(l10n.measurementsHint),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const MeasurementsScreen()),
        ),
      ),
    );
  }
}
