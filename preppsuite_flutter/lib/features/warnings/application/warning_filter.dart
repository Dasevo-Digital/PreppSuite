import '../../../local_db/database.dart';
import '../../../model/categories.dart';
import 'warning_relevance.dart';
import 'warning_region_filter.dart';
import 'warning_severity_l10n.dart';

/// Whether a warning is still running.
///
/// A feed leaves an expired warning in place for a while, so a list that
/// shows everything mixes "the storm is now" with "the storm was on
/// Tuesday". Sorting cannot fix that — only hiding one or the other can.
enum WarningStatus {
  /// No opinion; both are shown.
  any,

  /// Still running: no expiry, or an expiry in the future. A warning
  /// without an expiry counts as active, which is the safe reading —
  /// hiding a civil-protection alert because its feed left a field empty
  /// would be the worst possible outcome here.
  active,

  /// Expired: an expiry that has passed.
  expired,
}

/// What the warning list is currently showing.
///
/// Kept as a value type with its own [matches], away from the widget
/// tree: the interesting part is which warning survives which
/// combination, and that is worth testing without pumping a screen.
class WarningFilter {
  const WarningFilter({
    this.query = '',
    this.status = WarningStatus.any,
    this.onlyMyRegions = false,
    this.onlySevere = false,
  });

  /// Free text, matched against the headline, the description, the event
  /// type and the region key.
  ///
  /// A place name is the obvious thing to search for and the only one
  /// that works across both feeds: BBK region keys are numbers, and
  /// MeteoAlarm's area is free text that the region filter never matches
  /// at all (see `docs/warning-feeds.md`). The place is in the headline
  /// either way.
  final String query;

  final WarningStatus status;

  /// Only warnings that concern the regions this household follows.
  ///
  /// Uses [isWarningRelevant], not the rank: "no region given" means
  /// "concerns everyone" and has to stay visible.
  final bool onlyMyRegions;

  /// Only severe and extreme.
  final bool onlySevere;

  bool get isEmpty =>
      query.trim().isEmpty &&
      status == WarningStatus.any &&
      !onlyMyRegions &&
      !onlySevere;

  /// How many conditions are set — for the badge on the filter button.
  int get activeCount => [
    query.trim().isNotEmpty,
    status != WarningStatus.any,
    onlyMyRegions,
    onlySevere,
  ].where((set) => set).length;

  WarningFilter copyWith({
    String? query,
    WarningStatus? status,
    bool? onlyMyRegions,
    bool? onlySevere,
  }) => WarningFilter(
    query: query ?? this.query,
    status: status ?? this.status,
    onlyMyRegions: onlyMyRegions ?? this.onlyMyRegions,
    onlySevere: onlySevere ?? this.onlySevere,
  );

  bool matches(
    Warning warning, {
    required WarningRegionFilter regions,
    required DateTime now,
  }) {
    if (!_matchesStatus(warning, now)) return false;

    if (onlySevere) {
      final rank = warningSeverityRank(
        warningSeverityFromName(warning.severity),
      );
      if (rank < warningSeverityRank(WarningSeverity.severe)) return false;
    }

    if (onlyMyRegions &&
        !isWarningRelevant(warning: warning, filter: regions)) {
      return false;
    }

    return _matchesQuery(warning);
  }

  bool _matchesStatus(Warning warning, DateTime now) {
    final expires = warning.expires;
    final expired = expires != null && expires.isBefore(now);
    return switch (status) {
      WarningStatus.any => true,
      WarningStatus.active => !expired,
      WarningStatus.expired => expired,
    };
  }

  bool _matchesQuery(Warning warning) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return true;

    // Diacritics are left alone deliberately: "Münster" and "Munster" are
    // different places, and folding them together would answer a search
    // for one with the other.
    return [
      warning.headline,
      warning.description ?? '',
      warning.eventType,
      warning.regionKey ?? '',
    ].any((field) => field.toLowerCase().contains(needle));
  }
}

/// The warnings [filter] leaves, in the order they came in.
List<Warning> applyWarningFilter(
  List<Warning> warnings, {
  required WarningFilter filter,
  required WarningRegionFilter regions,
  DateTime? now,
}) {
  final at = now ?? DateTime.now();
  return [
    for (final warning in warnings)
      if (filter.matches(warning, regions: regions, now: at)) warning,
  ];
}
