import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import 'push_device_service.dart';

/// Registration of device push tokens. Accessed through
/// `client.pushDevice`.
class PushDeviceEndpoint extends Endpoint {
  final _service = const PushDeviceService();

  @override
  bool get requireLogin => true;

  /// Registers (or refreshes) this device's push token for [householdId].
  Future<PushDevice> registerDevice(
    Session session,
    UuidValue householdId,
    String token,
    PushPlatform platform,
  ) {
    return _service.register(
      session,
      householdId: householdId,
      token: token,
      platform: platform,
    );
  }

  /// Stops pushes to [token].
  Future<void> unregisterDevice(Session session, String token) {
    return _service.unregister(session, token: token);
  }
}
