import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

/// UDP port used only to announce that a screen is ready to show a transfer
/// QR code. It is intentionally separate from the encrypted TCP handover.
const localDiscoveryPort = 46381;
const _prefix = 'PSLD1';

/// An anonymous, short-lived local presence.
///
/// It carries no address list, household id, key, name or inventory. The
/// receiver only learns that a nearby PreppSuite screen is ready; it still
/// has to scan the visible QR invitation before a transfer can start.
class LocalTransferPresence {
  const LocalTransferPresence({
    required this.sessionId,
    required this.address,
    required this.seenAt,
  });

  final String sessionId;
  final InternetAddress address;
  final DateTime seenAt;

  static LocalTransferPresence? decode(
    String raw, {
    required InternetAddress address,
    required DateTime seenAt,
  }) {
    final parts = raw.split(':');
    if (parts.length != 2 || parts.first != _prefix) return null;
    if (!RegExp(r'^[a-f0-9]{16}$').hasMatch(parts.last)) return null;
    return LocalTransferPresence(
      sessionId: parts.last,
      address: address,
      seenAt: seenAt,
    );
  }
}

/// Sends an anonymous availability beacon while a transfer invitation is on
/// screen. Stopping the screen stops the beacon too.
class LocalTransferBroadcaster {
  LocalTransferBroadcaster._(this._socket, this.sessionId) {
    _socket.broadcastEnabled = true;
    _announce();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _announce());
  }

  final RawDatagramSocket _socket;
  final String sessionId;
  late final Timer _timer;

  static Future<LocalTransferBroadcaster> start() async {
    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    final random = Random.secure();
    final sessionId = List.generate(
      16,
      (_) => random.nextInt(16).toRadixString(16),
    ).join();
    return LocalTransferBroadcaster._(socket, sessionId);
  }

  void _announce() {
    final data = utf8.encode('$_prefix:$sessionId');
    _socket.send(data, InternetAddress('255.255.255.255'), localDiscoveryPort);
  }

  void dispose() {
    _timer.cancel();
    _socket.close();
  }
}

/// Listens for [LocalTransferBroadcaster] beacons on the current network.
///
/// Devices leave the list after a short quiet period. There is no persistent
/// discovery state and no device label, deliberately: a shared Wi-Fi should
/// not become a directory of households.
class LocalTransferDiscovery {
  LocalTransferDiscovery._(this._socket) {
    _socket.listen(_onEvent);
    _expiry = Timer.periodic(const Duration(seconds: 3), (_) => _expire());
  }

  final RawDatagramSocket _socket;
  final _devices = <String, LocalTransferPresence>{};
  final _updates = StreamController<List<LocalTransferPresence>>.broadcast();
  late final Timer _expiry;

  Stream<List<LocalTransferPresence>> get devices => _updates.stream;

  static Future<LocalTransferDiscovery> start() async {
    final socket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      localDiscoveryPort,
      reuseAddress: true,
    );
    socket.broadcastEnabled = true;
    return LocalTransferDiscovery._(socket);
  }

  void _onEvent(RawSocketEvent event) {
    if (event != RawSocketEvent.read) return;
    Datagram? datagram;
    while ((datagram = _socket.receive()) != null) {
      final found = LocalTransferPresence.decode(
        utf8.decode(datagram!.data, allowMalformed: true),
        address: datagram.address,
        seenAt: DateTime.now(),
      );
      if (found == null) continue;
      _devices[found.sessionId] = found;
      _publish();
    }
  }

  void _expire() {
    final cutoff = DateTime.now().subtract(const Duration(seconds: 10));
    final before = _devices.length;
    _devices.removeWhere((_, device) => device.seenAt.isBefore(cutoff));
    if (before != _devices.length) _publish();
  }

  void _publish() {
    if (_updates.isClosed) return;
    final current = _devices.values.toList()
      ..sort((a, b) => b.seenAt.compareTo(a.seenAt));
    _updates.add(current);
  }

  Future<void> dispose() async {
    _expiry.cancel();
    _socket.close();
    await _updates.close();
  }
}
