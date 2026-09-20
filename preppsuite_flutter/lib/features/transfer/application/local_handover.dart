import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import '../../../local_db/database.dart';
import '../../sharing/application/device_snapshot.dart';
import '../../sharing/application/folder_crypto.dart';
import '../../sharing/application/snapshot_exchange.dart';

/// Two devices on the same network, swapping households directly.
///
/// The QR chain works with nothing at all and is slow; this is the other
/// end of the same idea. Both devices are already in the room, so one
/// opens a socket and the other connects to it, and the whole household
/// crosses in one request instead of sixteen pictures. No folder, no
/// cloud, no account — the packets never leave the local network.
///
/// **The QR code is the door key, not the road.** The host shows one
/// small code holding its address and a freshly made key; the guest films
/// it and connects. That is what makes this safe without any pairing
/// ceremony: whoever can see the screen can join, and nobody else. There
/// is no discovery to spoof, no name to guess, no default password.
///
/// The body is encrypted under that key even though it never leaves the
/// local network, because "local network" on a phone often means a café,
/// a hotel or a campsite. The key lives for one handover.
///
/// It goes **both** ways in the one request: the guest posts what it has,
/// the host merges it and answers with what *it* has. So the two devices
/// come out of it agreeing, rather than one having been copied onto the
/// other.

/// The marker an invitation starts with, so the receiving screen can tell
/// it from a QR chain frame or the barcode on a tin.
const localHandoverPrefix = 'PSL1';
const localHandoverMaxRequestBytes = 8 * 1024 * 1024;

/// What the host shows and the guest films.
class LocalHandoverInvitation {
  const LocalHandoverInvitation({
    required this.addresses,
    required this.port,
    required this.householdId,
    required this.key,
  });

  /// Every address this device can be reached on.
  ///
  /// All of them, not the "best" one: a laptop on cable and wireless at
  /// once has two, a phone sharing its connection has a different one
  /// again, and which of them the other device can actually reach is not
  /// something this side can know. The guest tries them in turn.
  final List<String> addresses;

  final int port;
  final String householdId;
  final FolderKey key;

  String encode() =>
      '$localHandoverPrefix:${addresses.join(',')}:$port:$householdId:'
      '${key.encode()}';

  static LocalHandoverInvitation? decode(String raw) {
    final parts = raw.split(':');
    if (parts.length != 5 || parts[0] != localHandoverPrefix) return null;

    final port = int.tryParse(parts[2]);
    final key = FolderKey.decode(parts[4]);
    if (port == null || key == null) return null;

    final addresses = parts[1].split(',').where((a) => a.isNotEmpty).toList();
    if (addresses.isEmpty) return null;

    return LocalHandoverInvitation(
      addresses: addresses,
      port: port,
      householdId: parts[3],
      key: key,
    );
  }
}

/// What came of a handover, from either side.
typedef LocalHandoverResult = ({int received, int sent});

class LocalHandoverException implements Exception {
  const LocalHandoverException(this.reason);

  final LocalHandoverFailure reason;

  @override
  String toString() => 'LocalHandoverException: $reason';
}

enum LocalHandoverFailure {
  /// Nothing answered on any of the addresses.
  unreachable,

  /// The other device is a different household.
  otherHousehold,

  /// The body did not decrypt, or was not a snapshot.
  unreadable,
}

/// The side that waits.
class LocalHandoverHost {
  LocalHandoverHost._(this._server, this.invitation, this._maxRequestBytes);

  final HttpServer _server;
  final LocalHandoverInvitation invitation;
  final int _maxRequestBytes;

  final _done = StreamController<LocalHandoverResult>.broadcast();

  /// Fires once for each guest that completes a handover.
  Stream<LocalHandoverResult> get handovers => _done.stream;

  /// Opens a socket and starts listening.
  ///
  /// Port zero: the operating system picks a free one and it goes in the
  /// invitation. A fixed port would be one more thing to collide with
  /// something else on the machine, for no gain — nobody types this.
  static Future<LocalHandoverHost> start({
    required AppDatabase db,
    required String deviceId,
    required String householdId,
    List<String>? addresses,
    int maxRequestBytes = localHandoverMaxRequestBytes,
  }) async {
    if (maxRequestBytes < 1) {
      throw ArgumentError.value(maxRequestBytes, 'maxRequestBytes');
    }
    final found = addresses ?? await localAddresses();
    if (found.isEmpty) {
      throw const LocalHandoverException(LocalHandoverFailure.unreachable);
    }

    final server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
    final host = LocalHandoverHost._(
      server,
      LocalHandoverInvitation(
        addresses: found,
        port: server.port,
        householdId: householdId,
        key: FolderKey(_freshKey()),
      ),
      maxRequestBytes,
    );

    unawaited(
      host._serve(db: db, deviceId: deviceId, householdId: householdId),
    );
    return host;
  }

  Future<void> _serve({
    required AppDatabase db,
    required String deviceId,
    required String householdId,
  }) async {
    await for (final request in _server) {
      try {
        if (request.method != 'POST' || request.uri.path != '/handover') {
          request.response.statusCode = HttpStatus.notFound;
          await request.response.close();
          continue;
        }

        final raw = await _readRequest(request);
        final plain = await decryptFromFolder(raw, invitation.key);
        if (plain == null) {
          // Wrong key: somebody on the network who did not see the
          // screen. Nothing to explain to them.
          request.response.statusCode = HttpStatus.forbidden;
          await request.response.close();
          continue;
        }

        final incoming = DeviceSnapshot.decode(plain);
        if (incoming == null || incoming.householdId != householdId) {
          request.response.statusCode = HttpStatus.conflict;
          await request.response.close();
          continue;
        }

        final received = await applyHouseholdSnapshot(db, incoming);

        // Answer with ours, so both sides end up agreeing rather than one
        // being copied onto the other.
        final ours = await readHouseholdSnapshot(
          db,
          deviceId: deviceId,
          householdId: householdId,
        );
        final body = await encryptForFolder(ours.encode(), invitation.key);
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.text
          ..write(body);
        await request.response.close();

        _done.add((received: received, sent: ours.rowCount));
      } on _HandoverTooLarge {
        try {
          request.response.statusCode = HttpStatus.requestEntityTooLarge;
          await request.response.close();
        } on Object {
          // The client went away after being told its request is too large.
        }
      } on Object {
        // One bad request must not take the socket down: the person is
        // still standing there with the other device.
        try {
          request.response.statusCode = HttpStatus.internalServerError;
          await request.response.close();
        } on Object {
          // The connection went away mid-answer. Nothing left to do.
        }
      }
    }
  }

  Future<String> _readRequest(HttpRequest request) async {
    if (request.contentLength > _maxRequestBytes) {
      throw const _HandoverTooLarge();
    }
    final bytes = BytesBuilder(copy: false);
    await for (final chunk in request) {
      if (bytes.length + chunk.length > _maxRequestBytes) {
        throw const _HandoverTooLarge();
      }
      bytes.add(chunk);
    }
    return utf8.decode(bytes.takeBytes());
  }

  Future<void> stop() async {
    await _server.close(force: true);
    await _done.close();
  }
}

class _HandoverTooLarge implements Exception {
  const _HandoverTooLarge();
}

/// The side that connects, having filmed the invitation.
Future<LocalHandoverResult> joinLocalHandover({
  required AppDatabase db,
  required String deviceId,
  required String householdId,
  required LocalHandoverInvitation invitation,
  Duration timeout = const Duration(seconds: 8),
}) async {
  if (invitation.householdId != householdId) {
    throw const LocalHandoverException(LocalHandoverFailure.otherHousehold);
  }

  final ours = await readHouseholdSnapshot(
    db,
    deviceId: deviceId,
    householdId: householdId,
  );
  final body = await encryptForFolder(ours.encode(), invitation.key);

  final client = HttpClient()..connectionTimeout = timeout;
  try {
    for (final address in invitation.addresses) {
      final String answer;
      try {
        final request = await client
            .post(address, invitation.port, '/handover')
            .timeout(timeout);
        request.headers.contentType = ContentType.text;
        request.write(body);
        final response = await request.close().timeout(timeout);

        if (response.statusCode == HttpStatus.conflict) {
          throw const LocalHandoverException(
            LocalHandoverFailure.otherHousehold,
          );
        }
        if (response.statusCode != HttpStatus.ok) {
          throw const LocalHandoverException(LocalHandoverFailure.unreadable);
        }
        answer = await utf8.decoder.bind(response).join();
      } on LocalHandoverException {
        rethrow;
      } on Object {
        // This address did not answer. A machine can have several and
        // only one of them reaches the other device.
        continue;
      }

      final plain = await decryptFromFolder(answer, invitation.key);
      final theirs = plain == null ? null : DeviceSnapshot.decode(plain);
      if (theirs == null || theirs.householdId != householdId) {
        throw const LocalHandoverException(LocalHandoverFailure.unreadable);
      }

      return (
        received: await applyHouseholdSnapshot(db, theirs),
        sent: ours.rowCount,
      );
    }
  } finally {
    client.close(force: true);
  }

  throw const LocalHandoverException(LocalHandoverFailure.unreachable);
}

/// Every address this device can be reached on from the same network.
///
/// Loopback is left out: a guest cannot reach it, and offering an address
/// that cannot work turns a handover that would have succeeded on the
/// second address into one that looks broken.
Future<List<String>> localAddresses() async {
  try {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
      includeLinkLocal: false,
    );
    return [
      for (final interface in interfaces)
        for (final address in interface.addresses) address.address,
    ];
  } on Object {
    return const [];
  }
}

/// A key for this one handover, from the platform's own randomness.
Uint8List _freshKey() {
  final random = Random.secure();
  return Uint8List.fromList([
    for (var index = 0; index < 32; index++) random.nextInt(256),
  ]);
}
