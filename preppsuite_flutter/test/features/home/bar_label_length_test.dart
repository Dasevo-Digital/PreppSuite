import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/home/application/shell_layout.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations_de.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations_en.dart';

/// How long a label in the bottom bar may be.
///
/// Not a style rule but a measurement. A phone of 393 logical pixels — a
/// OnePlus Nord, 1080 physical at 2.75 — divided by [barSlotLimit] gives
/// each destination about seventy pixels, and at the bar's label size
/// that is ten characters or so. Beyond it the word wraps, and the bar's
/// fixed height cuts the second line off: "Checklisten" showed up as
/// "Checkliste" above a lone "n".
///
/// It cannot be fixed anywhere else. Flutter builds the label as a bare
/// `Text` with neither `maxLines` nor `overflow`, and a `DefaultTextStyle`
/// around the bar never reaches it, because the bar's own `Material`
/// resets one. The label has to fit.
///
/// A widget test cannot stand in for this: the test environment measures
/// text with its own font, so a pixel assertion there would be about that
/// font and not about Roboto on a phone.
const _maxBarLabel = 10;

void main() {
  // The destinations the bar always shows. The last slot goes to the
  // "more" button, and the sheet behind it has room for any word.
  final fixed = ShellDestination.values.take(barSlotLimit - 1);

  for (final AppLocalizations l10n in [
    AppLocalizationsDe(),
    AppLocalizationsEn(),
  ]) {
    test('[${l10n.localeName}] every bar label fits its slot', () {
      final labels = <String>[
        for (final destination in fixed) _labelOf(l10n, destination),
        l10n.navMore,
      ];

      for (final label in labels) {
        expect(
          label.length,
          lessThanOrEqualTo(_maxBarLabel),
          reason: '"$label" ist zu lang fuer den Balken',
        );
      }
    });
  }
}

String _labelOf(AppLocalizations l10n, ShellDestination destination) =>
    switch (destination) {
      ShellDestination.overview => l10n.navOverview,
      ShellDestination.emergency => l10n.navEmergency,
      ShellDestination.inventory => l10n.navInventory,
      ShellDestination.checklists => l10n.navChecklists,
      ShellDestination.warnings => l10n.navWarnings,
      ShellDestination.shelters => l10n.navShelters,
      ShellDestination.map => l10n.navMap,
      ShellDestination.knowledge => l10n.navKnowledge,
      ShellDestination.household => l10n.navHousehold,
      ShellDestination.settings => l10n.navSettings,
    };
