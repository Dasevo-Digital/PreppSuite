import 'dart:convert';

import '../../sharing/application/carried_settings.dart';
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
