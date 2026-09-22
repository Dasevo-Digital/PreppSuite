import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import '../../../local_db/database.dart';
import '../../sharing/application/carried_settings.dart';
import '../../sharing/application/folder_crypto.dart';
import '../../sharing/application/snapshot_exchange.dart';
import 'handover_payload.dart';
import 'handover_photos.dart';

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

/// How large a handover body may be.
///
/// **Derived from the photo budget rather than picked**, because picking
/// it is what went wrong. It was set to a flat 32 MB with a comment
/// saying base64 "adds a third" — but base64 runs **twice** on the way
/// out, and nobody did the second multiplication:
///
///   1. every picture's bytes become base64 to sit in the JSON — ×4/3;
///   2. the whole thing is encrypted and the ciphertext comes back as
///      base64 as well — ×4/3 again.
///
/// Sixteen ninths, not four thirds. A full budget of twenty megabytes of
/// photographs therefore arrives as **35.6 MB** against a 32 MB ceiling,
/// the host answers 413 while the guest is still uploading, the
/// connection breaks mid-write, and the guest reports a handover that
/// started and did not finish. Measured, not reasoned about: see
/// `local_handover_test.dart`.
///
/// The slack on top is for the rows, which travel in the same body and
/// are small beside the pictures but not nothing.
const localHandoverMaxRequestBytes =
    handoverPhotoBudgetBytes * 16 ~/ 9 + _rowsHeadroom;

/// Room for the household's rows beside the pictures, after the same two
/// base64 passes.
const _rowsHeadroom = 8 * 1024 * 1024;

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
///
/// [household] is the far side's own setup, and is deliberately **not**
/// applied here: this layer does not know whether this device is being set
/// up or has been in use for a year, and that is the whole difference
/// between a convenience and a device losing its own configuration. The
/// screen decides — see `QrReceiveScreen`.
typedef LocalHandoverResult = ({
  int received,
  int sent,
  int photos,
  CarriedHousehold household,
});

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

  /// The other device answered and the exchange then did not finish.
  ///
  /// Kept apart from [unreachable] because the two send somebody to look
  /// in completely different places. "Not reachable" asks whether both
  /// are on the same network; this one means they are, the socket was
  /// open, and something after that went wrong — so the answer is to try
  /// again, not to go and check the wifi.
  interrupted,
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
  /// [offering] is how this device is set up, for a guest that is being
  /// set up from it. Handed in rather than read here on purpose: this file
  /// is the protocol and knows about a database and a socket, and reaching
  /// into the platform's preferences from inside it would make every test
  /// of the wire need a plugin binding. The screen knows where settings
  /// live; this does not have to.
  static Future<LocalHandoverHost> start({
    required AppDatabase db,
    required String deviceId,
    required String householdId,
    CarriedHousehold offering = const CarriedHousehold(),
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
      host._serve(
        db: db,
        deviceId: deviceId,
        householdId: householdId,
        offering: offering,
      ),
    );
    return host;
  }

  Future<void> _serve({
    required AppDatabase db,
    required String deviceId,
    required String householdId,
    required CarriedHousehold offering,
  }) async {
    await for (final request in _server) {
      try {
        if (request.method != 'POST' || request.uri.path != '/handover') {
          request.response.statusCode = HttpStatus.notFound;
          await request.response.close();
          continue;
        }

        final raw = await _readRequest(request);
        final read = await HandoverPayload.unseal(raw, invitation.key);
        if (!read.opened) {
          // Wrong key: somebody on the network who did not see the
          // screen. Nothing to explain to them.
          request.response.statusCode = HttpStatus.forbidden;
          await request.response.close();
          continue;
        }

        final incoming = read.payload;
        if (incoming == null || incoming.snapshot.householdId != householdId) {
          request.response.statusCode = HttpStatus.conflict;
          await request.response.close();
          continue;
        }

        final received = await applyHouseholdSnapshot(db, incoming.snapshot);
        // After the rows and not before: a picture belongs to a row, and
        // on a device being set up that row arrived a moment ago.
        final tookPhotos = await applyHouseholdPhotos(
          db,
          householdId: householdId,
          photos: incoming.photos,
        );

        // Answer with ours, so both sides end up agreeing rather than one
        // being copied onto the other.
        final ours = await readHouseholdSnapshot(
          db,
          deviceId: deviceId,
          householdId: householdId,
        );
        final answer = HandoverPayload(
          snapshot: ours,
          household: offering,
          // Only what the other side said it was missing.
          photos: await readHouseholdPhotos(
            db,
            householdId: householdId,
            skip: incoming.knownPhotos,
          ),
        );
        final body = await answer.seal(invitation.key);
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.text
          ..write(body);
        await request.response.close();

        _done.add((
          received: received,
          sent: ours.rowCount,
          photos: tookPhotos,
          household: const CarriedHousehold(),
        ));
      } on _HandoverTooLarge {
        try {
          // No draining needed: [_readRequest] has already read to the
          // end, which is what makes this answer reach the guest at all.
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

  /// The body, or [_HandoverTooLarge] if it is over the ceiling.
  ///
  /// **Read to the end either way**, and that is the point of it. Bailing
  /// out mid-stream leaves the guest still uploading into a socket the
  /// host has stopped listening to, so the 413 never lands: the guest
  /// gets a broken pipe and reports a handover that started and did not
  /// finish, which sends somebody to look at their network. What is
  /// dropped is the *buffer*, not the reading — nothing is held on to
  /// past the ceiling, so an oversized body costs the time to receive it
  /// and no memory.
  Future<String> _readRequest(HttpRequest request) async {
    final bytes = BytesBuilder(copy: false);
    var tooLarge = request.contentLength > _maxRequestBytes;
    var seen = 0;

    await for (final chunk in request) {
      seen += chunk.length;
      if (!tooLarge && seen > _maxRequestBytes) {
        tooLarge = true;
        bytes.clear();
      }
      if (!tooLarge) bytes.add(chunk);
    }

    if (tooLarge) throw const _HandoverTooLarge();
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

  /// How long one address gets to answer at all.
  ///
  /// Short on purpose: this is the figure that decides "nothing here",
  /// and a device that is not listening says so at once. It is **not**
  /// how long the exchange may take — see [exchangeTimeoutFor], which is
  /// the distinction this used to lack.
  Duration connectTimeout = const Duration(seconds: 8),

  /// How long the exchange itself may take. Worked out from the body
  /// when left out.
  Duration? exchangeTimeout,

  /// Where arriving pictures are written. The app's own photo folder when
  /// left out; a test hands in a temporary one so that exercising a real
  /// socket needs no platform directory plugin.
  Directory? into,
}) async {
  if (invitation.householdId != householdId) {
    throw const LocalHandoverException(LocalHandoverFailure.otherHousehold);
  }

  final ours = await readHouseholdSnapshot(
    db,
    deviceId: deviceId,
    householdId: householdId,
  );
  final mine = await localPhotoNames(db, householdId: householdId);
  final offer = HandoverPayload(
    snapshot: ours,
    // No settings going this way. Only a device being set up applies what
    // it is handed, and that is never the host — so sending the guest's
    // own would put its configuration on the wire for nothing.
    // Everything this device has. It cannot know what the host is
    // missing, so it offers the lot and the host keeps what is new.
    photos: await readHouseholdPhotos(db, householdId: householdId),
    // What it already holds, so the answer leaves those out.
    knownPhotos: mine,
  );
  final body = await offer.seal(invitation.key);

  final exchange = exchangeTimeout ?? exchangeTimeoutFor(body.length);

  /// Whether any address answered at all. What separates "nothing there"
  /// from "something there that did not finish", which are two different
  /// things to go and do.
  var connected = false;

  final client = HttpClient()..connectionTimeout = connectTimeout;
  try {
    for (final address in invitation.addresses) {
      final HttpClientRequest request;
      try {
        request = await client
            .post(address, invitation.port, '/handover')
            .timeout(connectTimeout);
      } on Object {
        // This address did not answer. A machine can have several and
        // only one of them reaches the other device, so the next one
        // gets a turn.
        continue;
      }

      // Past here the address answered, so "not reachable" is already
      // ruled out however this ends — a device that plainly was there
      // must never be reported as absent.
      //
      // The remaining addresses still get their turn, though: a machine
      // can have a VPN or a second interface that accepts a connection
      // and leads nowhere useful, and giving up on the first one to
      // answer would strand a handover the second address would have
      // completed.
      connected = true;
      final String answer;
      try {
        request.headers.contentType = ContentType.text;
        request.write(body);
        final response = await request.close().timeout(exchange);

        if (response.statusCode == HttpStatus.conflict) {
          throw const LocalHandoverException(
            LocalHandoverFailure.otherHousehold,
          );
        }
        if (response.statusCode != HttpStatus.ok) {
          throw const LocalHandoverException(LocalHandoverFailure.unreadable);
        }
        answer = await utf8.decoder.bind(response).join().timeout(exchange);
      } on LocalHandoverException {
        rethrow;
      } on Object {
        continue;
      }

      final theirs = (await HandoverPayload.unseal(
        answer,
        invitation.key,
      )).payload;
      if (theirs == null || theirs.snapshot.householdId != householdId) {
        throw const LocalHandoverException(LocalHandoverFailure.unreadable);
      }

      final received = await applyHouseholdSnapshot(db, theirs.snapshot);
      return (
        received: received,
        sent: ours.rowCount,
        photos: await applyHouseholdPhotos(
          db,
          householdId: householdId,
          photos: theirs.photos,
          into: into,
        ),
        household: theirs.household,
      );
    }
  } finally {
    client.close(force: true);
  }

  throw LocalHandoverException(
    connected
        ? LocalHandoverFailure.interrupted
        : LocalHandoverFailure.unreachable,
  );
}

/// How long an exchange of [bodyBytes] is allowed to take.
///
/// The handover is one request carrying everything, and since the
/// photographs began travelling that is up to
/// [localHandoverMaxRequestBytes] — some thirty megabytes once base64 and
/// the encryption have had their share. It used to get the same eight
/// seconds as the connection, which is roughly the time the upload alone
/// needs on a good day; the exchange therefore timed out, the timeout was
/// read as "this address did not answer", and a household standing next
/// to its own router was told to check the network.
///
/// A floor for the far side's own work — decrypting, writing pictures to
/// disk, reading its own household back — plus an allowance at a
/// deliberately pessimistic half a megabyte a second. Generous rather
/// than tight: the cost of waiting too long is a person watching a
/// spinner they can cancel, and the cost of waiting too little is a
/// handover that fails while blaming the wrong thing.
Duration exchangeTimeoutFor(int bodyBytes) =>
    const Duration(seconds: 30) +
    Duration(milliseconds: (bodyBytes / 500).round());

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
