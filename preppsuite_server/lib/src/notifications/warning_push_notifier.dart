import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../warnings/services/warning_severity_rank.dart';
import '../warnings/warning_service.dart';
import 'push_device_service.dart';
import 'services/push_sender.dart';

/// Pushes newly-issued warnings to the devices they concern.
///
/// This is what the local notification in the app could never be: the app
/// only learns about a warning while it is running and syncing, so a phone
/// in a pocket at night stayed quiet. Reaching a closed app needs the
/// platform push services, and reaching them needs the server to decide
/// who a warning is for — which is the same relevance question the pull
/// already answers, reused here rather than reimplemented.
class WarningPushNotifier {
  const WarningPushNotifier({
    required this.sender,
    this.deviceService = const PushDeviceService(),
  });

  final PushSender sender;
  final PushDeviceService deviceService;

  /// Warnings below this are not pushed. A steady trickle of "minor"
  /// notifications is how people learn to ignore the channel, and the app
  /// applies the same floor to its own local notifications.
  static const minSeverity = WarningSeverity.moderate;

  /// Most notifications one device may receive from a single poll.
  ///
  /// Matters on a cold start: the first poll of an empty database inserts
  /// every currently-active warning in the country at once, and every one
  /// of them counts as new. Without a cap, an already-registered device
  /// would get dozens of notifications in a row — and the person would
  /// turn the feature off, permanently.
  static const maxPerDevicePerRun = 3;

  /// Sends [warnings] to every device whose household they are relevant
  /// to. Returns how many notifications went out.
  Future<int> notify(Session session, List<Warning> warnings) async {
    if (!sender.isConfigured) return 0;

    final now = DateTime.now().toUtc();
    // Deduplicated by id: a BBK warning can come back from both the
    // nationwide poll and the per-Kreis one in the same run, and nobody
    // needs to be told about it twice.
    final seen = <UuidValue>{};
    final worthSending =
        [
          for (final warning in warnings)
            if (warningSeverityRank(warning.severity) >=
                    warningSeverityRank(minSeverity) &&
                !(warning.expires?.isBefore(now) ?? false) &&
                seen.add(warning.id!))
              warning,
        ]..sort(
          (a, b) =>
              warningSeverityRank(b.severity) - warningSeverityRank(a.severity),
        );
    if (worthSending.isEmpty) return 0;

    final households = await Household.db.find(session);
    if (households.isEmpty) return 0;

    final subscriptionsByHousehold =
        <UuidValue, List<WarningRegionSubscription>>{};
    for (final subscription in await WarningRegionSubscription.db.find(
      session,
    )) {
      subscriptionsByHousehold
          .putIfAbsent(subscription.householdId, () => [])
          .add(subscription);
    }

    // Selected once for all households rather than per warning: the same
    // device is usually a recipient of several warnings in a run, and this
    // keeps it to one query.
    final devicesByHousehold = <UuidValue, List<PushDevice>>{};
    for (final device in await deviceService.devicesForHouseholds(
      session,
      households.map((h) => h.id!).toSet(),
    )) {
      devicesByHousehold.putIfAbsent(device.householdId, () => []).add(device);
    }
    if (devicesByHousehold.isEmpty) return 0;

    final sentPerDevice = <UuidValue, int>{};
    // A token FCM has rejected is gone for the rest of this run too —
    // without this, every remaining warning would attempt a send to a row
    // that has already been deleted.
    final deadDevices = <UuidValue>{};
    var capped = 0;
    var sent = 0;

    // Most severe first (sorted above), so if the cap does bite, what got
    // through is the part that mattered.
    for (final warning in worthSending) {
      for (final household in households) {
        if (household.countryCode != warning.countryCode) continue;

        final devices = devicesByHousehold[household.id!];
        if (devices == null) continue;

        if (!isWarningRelevant(
          warning,
          household,
          subscriptionsByHousehold[household.id!] ?? const [],
        )) {
          continue;
        }

        for (final device in devices) {
          if (deadDevices.contains(device.id!)) continue;

          final already = sentPerDevice[device.id!] ?? 0;
          if (already >= maxPerDevicePerRun) {
            capped++;
            continue;
          }
          sentPerDevice[device.id!] = already + 1;

          final status = await sender.send(
            session,
            device: device,
            message: PushMessage(
              title: warning.headline,
              body: warning.eventType,
              data: {
                'type': 'warning',
                'externalId': warning.externalId,
                'severity': warning.severity.name,
              },
            ),
          );

          switch (status) {
            case PushDeliveryStatus.delivered:
              sent++;
            case PushDeliveryStatus.tokenDead:
              deadDevices.add(device.id!);
              await deviceService.delete(session, device);
            case PushDeliveryStatus.failed:
            case PushDeliveryStatus.skipped:
              break;
          }
        }
      }
    }

    if (capped > 0) {
      session.log(
        'Warning push: suppressed $capped notification(s) over the '
        'per-device cap of $maxPerDevicePerRun',
      );
    }

    return sent;
  }
}
