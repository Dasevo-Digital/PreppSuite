/// The two lamps of the overview, on the home screen (#105).
///
/// The widget shows exactly what the overview shows -- the same
/// `supplyStatus` and `situationStatus`, fed by the same relevance rule --
/// because a home screen that disagreed with the app would be the one
/// place nobody could tell which to believe. It carries its own "as of"
/// line for the same reason: it is drawn from the last time the app ran,
/// and a lamp that does not say how old it is reads as live.
///
/// The texts are built here, already translated, and the platform side
/// only draws them. That keeps the wording in the ARB files with every
/// other string and spares the native widget a translation of its own.
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../model/categories.dart';
import 'status_lights.dart';

/// What the home screen widget draws.
@immutable
class HomeWidgetSnapshot {
  const HomeWidgetSnapshot({
    required this.supplyState,
    required this.supplyText,
    required this.situationState,
    required this.situationText,
    required this.updatedText,
  });

  /// `covered`, `short` or `unknown` -- the supply lamp's colour.
  final String supplyState;
  final String supplyText;

  /// `none`, or the highest relevant severity's name.
  final String situationState;
  final String situationText;

  /// "Stand: 14:05", so the widget never passes for live.
  final String updatedText;

  Map<String, String> toData() => {
    'supplyState': supplyState,
    'supplyText': supplyText,
    'situationState': situationState,
    'situationText': situationText,
    'updatedText': updatedText,
  };

  @override
  bool operator ==(Object other) =>
      other is HomeWidgetSnapshot &&
      other.supplyState == supplyState &&
      other.supplyText == supplyText &&
      other.situationState == situationState &&
      other.situationText == situationText &&
      other.updatedText == updatedText;

  @override
  int get hashCode => Object.hash(
    supplyState,
    supplyText,
    situationState,
    situationText,
    updatedText,
  );
}

/// Builds the snapshot from the two lamps, in [l10n]'s language.
///
/// [time] is the formatted moment the data was read, so tests need no
/// clock and the widget no formatting.
HomeWidgetSnapshot buildHomeWidgetSnapshot({
  required SupplyStatus supply,
  required SituationStatus situation,
  required AppLocalizations l10n,
  required String time,
}) {
  final days = supply.daysCovered;
  final supplyText = switch (supply.light) {
    SupplyLight.unknown => l10n.statusSupplyUnknown,
    SupplyLight.covered => l10n.statusSupplyCovered(days ?? statusLightDays),
    SupplyLight.short => l10n.statusSupplyShort(days ?? 0, statusLightDays),
  };
  final highest = situation.highest;
  final situationText = highest == null
      ? l10n.statusSituationQuiet
      : '${l10n.statusSituationActive(situation.count)} · '
            '${_severity(l10n, highest)}';
  return HomeWidgetSnapshot(
    supplyState: supply.light.name,
    supplyText: '${l10n.statusSupplyTitle}: $supplyText',
    situationState: highest?.name ?? 'none',
    situationText: '${l10n.statusSituationTitle}: $situationText',
    updatedText: l10n.homeWidgetUpdated(time),
  );
}

String _severity(AppLocalizations l10n, WarningSeverity severity) =>
    switch (severity) {
      WarningSeverity.minor => l10n.warningSeverityMinor,
      WarningSeverity.moderate => l10n.warningSeverityModerate,
      WarningSeverity.severe => l10n.warningSeveritySevere,
      WarningSeverity.extreme => l10n.warningSeverityExtreme,
    };

/// Hands snapshots to the platform, skipping ones that changed nothing.
///
/// Android and iOS. On iOS the widget is an extension in its own process,
/// so the app writes into the App Group both share
/// (`ios/Runner/Runner.entitlements`). The desktop systems have no home
/// screen widgets of this kind.
class HomeWidgetPublisher {
  HomeWidgetPublisher({@visibleForTesting this.enabled});

  /// Overrides the platform check, for tests.
  final bool? enabled;

  HomeWidgetSnapshot? _last;

  static const androidProvider = 'PreppSuiteWidgetProvider';

  /// The `kind` of the WidgetKit widget in `ios/PreppSuiteWidget`.
  static const iosWidget = 'PreppSuiteWidget';

  /// Shared by the app and the widget extension; registered on the
  /// signing account, and named in both entitlements files.
  static const appGroup = 'group.de.dasevo.preppsuite';

  bool get _enabled =>
      enabled ?? (!kIsWeb && (Platform.isAndroid || Platform.isIOS));

  var _groupSet = false;

  /// Publishes [snapshot] unless it is the one already there. Failures are
  /// swallowed: a home screen widget that could not be refreshed must not
  /// cost the screen that tried.
  Future<bool> publish(HomeWidgetSnapshot snapshot) async {
    if (!_enabled || snapshot == _last) return false;
    _last = snapshot;
    try {
      if (!_groupSet) {
        await HomeWidget.setAppGroupId(appGroup);
        _groupSet = true;
      }
      for (final MapEntry(:key, :value) in snapshot.toData().entries) {
        await HomeWidget.saveWidgetData<String>(key, value);
      }
      await HomeWidget.updateWidget(
        androidName: androidProvider,
        iOSName: iosWidget,
      );
      return true;
    } on Object {
      _last = null;
      return false;
    }
  }
}
