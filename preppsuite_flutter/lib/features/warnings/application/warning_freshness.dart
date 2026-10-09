import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../l10n/generated/app_localizations.dart';
import 'warning_poll_status_store.dart';

/// How old the warnings on this device are, said wherever their absence
/// could be read as good news (#138).
///
/// An empty list said "no warnings for your region" whether the feeds had
/// been asked a minute ago or not for two days. On the day the network
/// goes down -- the day there is most likely to be something to warn
/// about -- that sentence is the opposite of the truth: nothing has
/// arrived because nothing could. The app knew when it last heard from
/// the feeds and said it only in the settings.
enum WarningFreshness {
  /// The household's feed answered within [warningStaleAfter].
  current,

  /// It did, but longer ago than that.
  stale,

  /// It never has on this device.
  never,
}

/// Four missed rounds of the fifteen-minute poll. One missed round is a
/// tunnel or a lift; an hour is no longer a hiccup.
const warningStaleAfter = Duration(hours: 1);

/// The freshness of [status] for [countryCode] at [now], and the time it
/// is measured from.
({WarningFreshness freshness, DateTime? at}) warningFreshness(
  WarningPollStatus status, {
  required String countryCode,
  required DateTime now,
}) {
  final at = status.currentAt(countryCode);
  if (at == null) return (freshness: WarningFreshness.never, at: null);
  final age = now.toUtc().difference(at.toUtc());
  return (
    freshness: age > warningStaleAfter
        ? WarningFreshness.stale
        : WarningFreshness.current,
    at: at,
  );
}

/// The poll bookkeeping, read again after every poll this app runs.
final warningPollStatusProvider = FutureProvider<WarningPollStatus>(
  (ref) => const WarningPollStatusStore().load(),
);

/// "heute 14:32", or a date with the time for anything older.
String formatWarningTime(AppLocalizations l10n, DateTime at, DateTime now) {
  final local = at.toLocal();
  final today = now.toLocal();
  final time = DateFormat.Hm(l10n.localeName).format(local);
  final sameDay =
      local.year == today.year &&
      local.month == today.month &&
      local.day == today.day;
  return sameDay
      ? l10n.warningsTimeToday(time)
      : '${DateFormat.yMMMd(l10n.localeName).format(local)} $time';
}
