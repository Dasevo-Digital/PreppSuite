/// The app's own vocabulary for categories and warning metadata.
///
/// These used to come from the generated Serverpod client, which meant the
/// words the UI speaks were defined by a backend the app no longer has.
/// They are stored in the local database as plain enum names, so the names
/// here are load-bearing: renaming a value orphans every row that used it.
library;

/// Broad storage category for a supply item. Also used for budget entries,
/// which are categorised the same way.
enum InventoryItemCategory {
  water,
  food,
  medical,
  tools,
  documents,
  energy,
  hygiene,
  other;

  /// Drift stores these as their plain name.
  static InventoryItemCategory fromName(String name) =>
      values.asNameMap()[name] ?? InventoryItemCategory.other;
}

/// Broad grouping for a checklist template.
///
/// Declaration order is display order — the list groups by it, roughly
/// from "keeps you alive indoors" to "you are leaving". Adding a value is
/// safe; an older app reading a newer row falls back to [custom] rather
/// than throwing. Renaming or removing one orphans every row that used
/// it.
enum ChecklistCategory {
  water,
  food,
  firstAid,
  hygiene,
  energy,
  information,
  documents,
  evacuation,
  safety,
  pets,
  custom;

  static ChecklistCategory fromName(String name) =>
      values.asNameMap()[name] ?? ChecklistCategory.custom;
}

/// Normalized severity — both feeds already use the CAP standard's
/// Minor/Moderate/Severe/Extreme scale.
enum WarningSeverity {
  minor,
  moderate,
  severe,
  extreme;

  static WarningSeverity fromName(String name) =>
      values.asNameMap()[name.toLowerCase()] ?? WarningSeverity.minor;
}

/// Which upstream feed a warning came from.
enum WarningSource {
  /// German BBK (warnung.bund.de) — MoWaS, DWD, Katwarn and the rest.
  bbk,

  /// EUMETNET's MeteoAlarm weather warnings.
  meteoalarm;

  static WarningSource fromName(String name) =>
      values.asNameMap()[name] ?? WarningSource.bbk;
}
