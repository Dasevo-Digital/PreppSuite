import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';

/// What sending to one device produced.
///
/// The distinction that matters is [tokenDead] versus [failed]: a dead
/// token is a device that will never receive anything again (app deleted,
/// token rotated) and its row must go, while a failure is transient and the
/// row must stay — deleting on a network blip would silently unsubscribe
/// people whose only mistake was being pushed to during an outage.
enum PushDeliveryStatus {
  delivered,

  /// The push service rejected the token itself. Delete the device.
  tokenDead,

  /// Something else went wrong (network, quota, a 5xx from the service).
  /// Keep the device and try again on the next warning.
  failed,

  /// No credentials configured — nothing was attempted.
  skipped,
}

/// A notification as the sender needs it: already localized, already
/// truncated, no model objects. Keeps the transport free of any knowledge
/// about warnings.
class PushMessage {
  const PushMessage({
    required this.title,
    required this.body,
    this.data = const {},
  });

  final String title;
  final String body;

  /// Delivered alongside the visible notification so a tap can open the
  /// right screen. FCM only carries strings here.
  final Map<String, String> data;
}

/// Delivers a [PushMessage] to a single device.
///
/// An interface rather than a concrete class so the warning poller can be
/// tested without a network, and so a direct APNs transport can be added
/// later without touching anything above this line.
abstract interface class PushSender {
  /// Whether credentials are present. When false every [send] returns
  /// [PushDeliveryStatus.skipped] and callers should not bother selecting
  /// recipients.
  bool get isConfigured;

  Future<PushDeliveryStatus> send(
    Session session, {
    required PushDevice device,
    required PushMessage message,
  });
}

/// The sender used when no credentials are configured — which is the
/// normal state of a fresh self-hosted install, and of every test that
/// isn't specifically about pushing.
class DisabledPushSender implements PushSender {
  const DisabledPushSender();

  @override
  bool get isConfigured => false;

  @override
  Future<PushDeliveryStatus> send(
    Session session, {
    required PushDevice device,
    required PushMessage message,
  }) async => PushDeliveryStatus.skipped;
}
