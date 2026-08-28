import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How long a household may go without a successful sync before it is
/// worth saying so.
///
/// Being offline is the normal case for this app, not a fault — it is
/// built to work without a server, and a "no connection" banner would be
/// noise on every train ride. What deserves saying is the other thing:
/// that edits made here have not reached the other devices *for a while*,
/// so nobody keeps believing the household is in step when it is not.
const syncStaleAfter = Duration(minutes: 30);

/// What the last round of sync passes did.
class SyncStatus {
  const SyncStatus({this.lastSuccessAt, this.lastFailureAt});

  /// When all entities last synced without error. Null until the first
  /// successful pass — a fresh install that has never reached the server.
  final DateTime? lastSuccessAt;

  final DateTime? lastFailureAt;

  bool get hasFailed => lastFailureAt != null;

  SyncStatus copyWith({DateTime? lastSuccessAt, DateTime? lastFailureAt}) {
    return SyncStatus(
      lastSuccessAt: lastSuccessAt ?? this.lastSuccessAt,
      lastFailureAt: lastFailureAt ?? this.lastFailureAt,
    );
  }
}

/// Whether the user should be told that sync is behind.
///
/// Pure so the rule can be tested without waiting for real clocks. Two
/// cases warrant it, and nothing else does:
///
/// * a sync has failed and none has ever succeeded — the server address is
///   probably wrong, and nothing this device holds has ever left it;
/// * a sync has failed and the last success is longer ago than
///   [syncStaleAfter].
///
/// A failure on its own stays quiet: one dropped request between two good
/// ones says nothing worth interrupting for.
bool isSyncStale(SyncStatus status, DateTime now, {Duration? staleAfter}) {
  if (!status.hasFailed) return false;

  final lastSuccess = status.lastSuccessAt;
  if (lastSuccess == null) return true;

  return now.difference(lastSuccess) > (staleAfter ?? syncStaleAfter);
}

/// Coarse buckets for "how long ago", so the message can be phrased
/// without pulling in date formatting. Deliberately blunt: the difference
/// between 41 and 47 minutes changes nothing for the reader.
enum SyncAgeUnit { minutes, hours, days }

class SyncAge {
  const SyncAge(this.value, this.unit);

  final int value;
  final SyncAgeUnit unit;

  @override
  bool operator ==(Object other) =>
      other is SyncAge && other.value == value && other.unit == unit;

  @override
  int get hashCode => Object.hash(value, unit);

  @override
  String toString() => '$value ${unit.name}';
}

/// Rounds a gap down to whole minutes, hours or days. Anything under a
/// minute reports as one minute rather than zero — "vor 0 Minuten" reads
/// like a bug.
SyncAge syncAge(Duration since) {
  if (since.inDays >= 1) return SyncAge(since.inDays, SyncAgeUnit.days);
  if (since.inHours >= 1) return SyncAge(since.inHours, SyncAgeUnit.hours);
  return SyncAge(
    since.inMinutes < 1 ? 1 : since.inMinutes,
    SyncAgeUnit.minutes,
  );
}

class SyncStatusController extends Notifier<SyncStatus> {
  @override
  SyncStatus build() => const SyncStatus();

  void recordSuccess(DateTime at) {
    // Clears the failure mark: a good pass means the household is in step
    // again, whatever went wrong before.
    state = SyncStatus(lastSuccessAt: at);
  }

  void recordFailure(DateTime at) {
    state = state.copyWith(lastFailureAt: at);
  }
}

final syncStatusProvider = NotifierProvider<SyncStatusController, SyncStatus>(
  SyncStatusController.new,
);
