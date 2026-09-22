import 'dart:convert';
import 'dart:isolate';

import '../../sharing/application/carried_settings.dart';
import '../../sharing/application/folder_crypto.dart';
import '../../sharing/application/device_snapshot.dart';
import 'handover_photos.dart';

/// What actually crosses the wire in a local handover.
///
/// A **superset of the snapshot JSON**, not a wrapper around it. That
/// shape is the whole design: a device running an older version decodes
/// this with [DeviceSnapshot.decode], never sees the three extra keys,
/// and the handover works exactly as it did before. A wrapper would have
/// made the first handover between an old and a new install fail with
/// "different household", which is both wrong and frightening.
///
/// Three things ride along beside the rows:
///
///  * [household] — who lives here and what they have chosen, from the
///    allow-list in `carried_settings.dart`. Sent by both sides;
///    **applied only by a device being set up**, which is the one moment
///    it has nothing of its own to lose. See
///    `QrReceiveScreen.adoptHousehold`.
///  * [photos] — the pictures of the stock, which are in no snapshot.
///  * [knownPhotos] — the names the sender already holds, so the answer
///    leaves them out. This is what makes a second handover cheap.
class HandoverPayload {
  const HandoverPayload({
    required this.snapshot,
    this.household = const CarriedHousehold(),
    this.photos = const [],
    this.knownPhotos = const {},
  });

  final DeviceSnapshot snapshot;
  final CarriedHousehold household;
  final List<HandoverPhoto> photos;
  final PhotoRequest knownPhotos;

  String encode() => jsonEncode({
    ...snapshot.toJson(),
    'household': household.toJson(),
    'photos': [for (final photo in photos) photo.toJson()],
    'knownPhotos': knownPhotos.toList()..sort(),
  });

  /// [encode], sealed under [key], off the thread that draws the screen.
  ///
  /// Both halves are expensive and neither is interruptible. Twenty
  /// megabytes of photos become twenty-seven of base64 inside a
  /// thirty-five megabyte JSON string; AES-GCM here is plain Dart, which
  /// moves tens of megabytes a second rather than hundreds. Together
  /// that is seconds, and `async` does not help with any of it — an
  /// `await` on work that never yields is the same freeze with extra
  /// steps.
  ///
  /// The isolate is handed the payload and copies it, which costs one
  /// pass over the bytes against the several the encoding itself makes.
  /// It is also what keeps the progress indicator turning: a handover
  /// that appears to have hung is one somebody cancels halfway.
  Future<String> seal(FolderKey key) =>
      Isolate.run(() => encryptForFolder(encode(), key));

  /// The other direction, and the same reason.
  ///
  /// It runs on the device being set up, which is the one staring at the
  /// screen with nothing else to look at.
  ///
  /// The two ways this fails are kept apart, because the host answers
  /// them differently: a body that will not open belongs to somebody on
  /// the network who never saw the screen, and one that opens into
  /// something else is a device that did. Collapsing them would answer
  /// "forbidden" to a household that is merely mismatched.
  static Future<({bool opened, HandoverPayload? payload})> unseal(
    String raw,
    FolderKey key,
  ) => Isolate.run(() async {
    final plain = await decryptFromFolder(raw, key);
    if (plain == null) return (opened: false, payload: null);
    return (opened: true, payload: decode(plain));
  });

  /// Null only when there is no readable snapshot in [raw].
  ///
  /// Everything else degrades quietly: a body written by an older version
  /// carries no extra keys and comes back as a payload with empty ones,
  /// which is exactly what it is.
  static HandoverPayload? decode(String raw) {
    final snapshot = DeviceSnapshot.decode(raw);
    if (snapshot == null) return null;

    final Object? json;
    try {
      json = jsonDecode(raw);
    } on FormatException {
      return null;
    }
    if (json is! Map<String, Object?>) {
      return HandoverPayload(snapshot: snapshot);
    }

    return HandoverPayload(
      snapshot: snapshot,
      household: CarriedHousehold.fromJson(json['household']),
      photos: [
        for (final entry in _list(json['photos']))
          ?HandoverPhoto.fromJson(entry),
      ],
      knownPhotos: {
        for (final entry in _list(json['knownPhotos']))
          ?HandoverPhoto.safeName(entry),
      },
    );
  }

  static List<Object?> _list(Object? raw) => raw is List ? raw : const [];
}
