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
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import '../../../core/app_language.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../local_db/database.dart';
import '../../../model/categories.dart';
import '../../warnings/application/warning_region_filter.dart';
import '../../warnings/application/warning_relevance.dart';
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

  /// "Stand: 9.11., 14:05", so the widget never passes for live.
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

/// The moment in the widget's "as of" line: always with the day, or a line
/// written on Monday reads on Thursday as if it were today (#332).
String homeWidgetStamp(DateTime moment, String localeName) =>
    DateFormat.Md(localeName).add_jm().format(moment);

/// The situation lamp as the background worker can write it (#332).
///
/// Only that lamp and the "as of" line. The supply lamp needs the household
/// profile, which a background isolate does not have, and it is not what
/// changes while nobody has the app open. A warning is. Without this the
/// widget said "calm" under a notification announcing an extreme warning.
Future<void> publishHomeWidgetSituation({
  required AppDatabase database,
  required WarningRegionFilter filter,
  HomeWidgetPublisher? publisher,
  DateTime? now,
}) async {
  final out = publisher ?? HomeWidgetPublisher();
  if (!out.isActive) return;
  try {
    final moment = now ?? DateTime.now();
    final relevant = [
      for (final warning in await database.watchActiveWarnings().first)
        if ((warning.expires == null || warning.expires!.isAfter(moment)) &&
            isWarningRelevant(warning: warning, filter: filter))
          warning,
    ];
    final l10n = await _workerLocalizations();
    await initializeDateFormatting(l10n.localeName);
    final snapshot = buildHomeWidgetSnapshot(
      supply: const SupplyStatus(light: SupplyLight.unknown),
      situation: situationStatus(relevant),
      l10n: l10n,
      time: homeWidgetStamp(moment, l10n.localeName),
    );
    await out.publishSituation(snapshot);
  } on Object {
    // A widget left as it was must not cost the poll that tried.
  }
}

/// The app's language, for an isolate with no widget tree to ask.
Future<AppLocalizations> _workerLocalizations() async =>
    lookupAppLocalizations(await appLocaleWithoutContext());

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

  /// Whether this platform has a widget to publish to at all.
  bool get isActive => _enabled;

  var _groupSet = false;

  /// Writes only what the background worker knows about: the situation
  /// lamp and the time. Failures are swallowed, as in [publish].
  Future<void> publishSituation(HomeWidgetSnapshot snapshot) async {
    if (!_enabled) return;
    try {
      await HomeWidget.setAppGroupId(appGroup);
      await HomeWidget.saveWidgetData<String>(
        'situationState',
        snapshot.situationState,
      );
      await HomeWidget.saveWidgetData<String>(
        'situationText',
        snapshot.situationText,
      );
      await HomeWidget.saveWidgetData<String>(
        'updatedText',
        snapshot.updatedText,
      );
      await HomeWidget.updateWidget(
        androidName: androidProvider,
        iOSName: iosWidget,
      );
    } on Object {
      // See [publish].
    }
  }

  /// Empties the widget, for a household that is deleted (#336): the app
  /// is gone from the data, and the home screen should not still say how
  /// long its stock lasts.
  Future<void> clear() async {
    if (!_enabled) return;
    try {
      await HomeWidget.setAppGroupId(appGroup);
      for (final key in const HomeWidgetSnapshot(
        supplyState: '',
        supplyText: '',
        situationState: '',
        situationText: '',
        updatedText: '',
      ).toData().keys) {
        await HomeWidget.saveWidgetData<String>(key, null);
      }
      await HomeWidget.updateWidget(
        androidName: androidProvider,
        iOSName: iosWidget,
      );
    } on Object {
      // See [publish].
    }
  }

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
