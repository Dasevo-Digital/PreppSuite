import 'byte_size.dart';

/// How fast a download is going and how much longer it has.
///
/// Separate from [DownloadProgress] because it is not something the
/// downloader knows: it reports bytes on disk, and the same figure means
/// a different speed depending on when this run started. A resumed
/// download starts with gigabytes already there, so measuring from zero
/// would report a speed the connection has never managed.
class DownloadRate {
  const DownloadRate({required this.bytesPerSecond, this.remaining});

  final double bytesPerSecond;

  /// Null where the server never stated a total, which is the honest
  /// answer rather than a made-up one — a mirror behind a redirect
  /// sometimes gives no length at all.
  final Duration? remaining;

  String get formatted => '${formatByteSize(bytesPerSecond.round())}/s';
}

/// How long to watch before saying anything.
///
/// The first samples are nonsense: a quarter of a second of a connection
/// warming up reads as either nothing or ten times the real speed, and a
/// figure that swings by a factor of ten is worse than no figure. Two
/// seconds is long enough to settle and short enough that a download
/// says something about itself almost at once.
const rateSettleTime = Duration(seconds: 2);

/// The speed and remaining time of a run in progress, or null when there
/// is nothing trustworthy to say yet.
///
/// [startedFrom] is what was already on disk when this run began, and
/// [elapsed] is how long ago that was.
DownloadRate? downloadRate({
  required int received,
  required int? total,
  required int startedFrom,
  required Duration elapsed,
}) {
  if (elapsed < rateSettleTime) return null;

  final moved = received - startedFrom;
  if (moved <= 0) return null;

  final bytesPerSecond = moved * 1000000 / elapsed.inMicroseconds;
  if (bytesPerSecond <= 0) return null;

  Duration? remaining;
  if (total != null && total > received) {
    final seconds = (total - received) / bytesPerSecond;
    // Days rather than a number that has overflowed: a 52 GB archive on
    // a bad connection really is measured in days, and clamping it to
    // something comfortable would be a lie about when it will be usable.
    if (seconds.isFinite && seconds < 100 * 24 * 3600) {
      remaining = Duration(seconds: seconds.round());
    }
  }

  return DownloadRate(bytesPerSecond: bytesPerSecond, remaining: remaining);
}

/// A remaining time in words, rounded the way waiting is experienced.
///
/// Nobody waiting on a 52 GB archive needs seconds, and nobody waiting
/// on the last minute of one needs hours. The unit follows the distance:
/// seconds under a minute, minutes under an hour, hours and minutes
/// above.
({int? hours, int? minutes, int? seconds}) splitRemaining(
  Duration remaining,
) {
  if (remaining.inMinutes < 1) {
    return (hours: null, minutes: null, seconds: remaining.inSeconds);
  }
  if (remaining.inHours < 1) {
    return (hours: null, minutes: remaining.inMinutes, seconds: null);
  }
  return (
    hours: remaining.inHours,
    minutes: remaining.inMinutes % 60,
    seconds: null,
  );
}
