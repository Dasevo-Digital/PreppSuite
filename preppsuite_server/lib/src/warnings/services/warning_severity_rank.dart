import '../../generated/protocol.dart';

/// Ordinal rank of [severity], low to high.
///
/// The enum's own `index` would do the same job today, but only by
/// accident of declaration order — this makes the ordering explicit, so
/// inserting a value into the model file cannot silently reorder it. The
/// app carries the same helper for its own comparisons.
int warningSeverityRank(WarningSeverity severity) {
  return switch (severity) {
    WarningSeverity.minor => 0,
    WarningSeverity.moderate => 1,
    WarningSeverity.severe => 2,
    WarningSeverity.extreme => 3,
  };
}
