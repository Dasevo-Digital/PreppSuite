/// Which pictures a row has, as every device can say it (#376).
///
/// A row stores its photos as paths into this machine's own folder, which
/// mean nothing anywhere else. What does mean something everywhere is the
/// picture itself, so each place of a row is also named by the SHA-256 of
/// its picture, and those names travel with the row. The pictures follow
/// through an encrypted shared folder, under names derived from these
/// (`features/sharing/application/folder_photos.dart`).
///
/// A list has one entry per place -- three for an inventory item, one for
/// a possession -- each a hash or null. There are two kinds, and keeping
/// them apart is what keeps pictures from being lost:
///
///  * **Set** by an edit. Somebody chose these pictures for this version
///    of the row, and an empty place is empty: it takes a picture out on
///    every device.
///  * **Seen** on one device: the pictures that device holds for the row,
///    read off its files. That is knowledge, not a decision. A device that
///    never got a picture sees an empty place where there is none, so a
///    seen list only ever adds: two seen lists join place by place, and a
///    seen list never overrules a set one.
///
/// The list as a whole can also be missing, which is "not known" -- a row
/// from before #376, or one whose pictures changed here and could not be
/// read. An unknown list never clears anything either.
///
/// Stored as JSON: a set list as the list itself, a seen one as
/// `{"seen": [...]}`.
library;

import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:cryptography/dart.dart';

/// How many places an inventory item's list has; a possession's has one.
const inventoryPhotoPlaces = 3;
const possessionPhotoPlaces = 1;

final _hash = RegExp(r'^[0-9a-f]{64}$');

/// Whether [value] is a picture's name as this app writes it: 64 lower-case
/// hexadecimal digits.
bool isPhotoHash(Object? value) => value is String && _hash.hasMatch(value);

/// The list in [raw], or null when it is not one this app would write --
/// the wrong length, an entry that is not a hash.
///
/// Read as "not known" rather than as an error: a list that cannot be read
/// says nothing about the pictures, and nothing is what the merge then
/// takes from it.
List<String?>? photoHashesFromJson(Object? raw, {required int places}) {
  if (raw is! List || raw.length != places) return null;
  final hashes = <String?>[];
  for (final entry in raw) {
    if (entry != null && !isPhotoHash(entry)) return null;
    hashes.add(entry as String?);
  }
  return hashes;
}

/// What a row knows of its pictures; see the library comment.
class PhotoList {
  const PhotoList(this.places, {this.seen = false});

  final List<String?> places;

  /// True for a list read off one device's files rather than set by an
  /// edit. Its empty places say only that this device has nothing there.
  final bool seen;

  /// The pictures named, without the empty places.
  Iterable<String> get pictures => places.whereType<String>();

  @override
  bool operator ==(Object other) =>
      other is PhotoList &&
      other.seen == seen &&
      other.places.length == places.length &&
      [
        for (var i = 0; i < places.length; i++) places[i] == other.places[i],
      ].every((same) => same);

  @override
  int get hashCode => Object.hash(seen, Object.hashAll(places));

  @override
  String toString() => encodePhotoList(this);
}

/// The stored column as a list; null for a missing or unreadable one.
PhotoList? decodePhotoList(String? stored, {required int places}) {
  if (stored == null) return null;
  final Object? raw;
  try {
    raw = jsonDecode(stored);
  } on FormatException {
    return null;
  }
  if (raw is Map) {
    final seen = photoHashesFromJson(raw['seen'], places: places);
    return seen == null ? null : PhotoList(seen, seen: true);
  }
  final set = photoHashesFromJson(raw, places: places);
  return set == null ? null : PhotoList(set);
}

String encodePhotoList(PhotoList list) =>
    list.seen ? jsonEncode({'seen': list.places}) : jsonEncode(list.places);

/// Two lists place by place: what either names. Where both name a picture
/// and not the same one, the greater name stays -- arbitrary, but the same
/// on every device, so that they settle instead of trading back and forth.
List<String?> joinPhotoPlaces(List<String?> a, List<String?> b) => [
  for (var i = 0; i < a.length; i++)
    switch ((a[i], i < b.length ? b[i] : null)) {
      (final x?, final y?) => x.compareTo(y) >= 0 ? x : y,
      (final x?, null) => x,
      (null, final y) => y,
    },
];

/// The list a row keeps when a newer version of it arrives with
/// [incoming]: a set list is the edit's, and stands; a seen one adds to
/// what was only seen, and leaves a set list alone. A version that brings
/// nothing -- an older app, a device that never knew the pictures -- keeps
/// what is stored.
PhotoList? photoListForNewer({PhotoList? stored, PhotoList? incoming}) {
  if (incoming == null) return stored;
  if (!incoming.seen) return incoming;
  if (stored == null) return incoming;
  if (!stored.seen) return stored;
  return PhotoList(joinPhotoPlaces(stored.places, incoming.places), seen: true);
}

/// The list a row keeps when the same version of it arrives with
/// [incoming]. A set list beats a seen one: it is the decision the version
/// was made with. Two seen lists join. Two set lists for one version are
/// two edits in the same second, and join as well.
PhotoList? photoListForSameVersion({PhotoList? stored, PhotoList? incoming}) {
  if (incoming == null) return stored;
  if (stored == null) return incoming;
  if (stored == incoming) return stored;
  if (stored.seen != incoming.seen) return stored.seen ? incoming : stored;
  return PhotoList(
    joinPhotoPlaces(stored.places, incoming.places),
    seen: stored.seen,
  );
}

/// The SHA-256 of [bytes] in hexadecimal: a picture's name everywhere.
///
/// On an isolate of its own, as the photo vault does its work: in pure
/// Dart this is a few milliseconds a megabyte, and a list of thumbnails
/// should not wait for it.
Future<String> photoContentHash(Uint8List bytes) =>
    Isolate.run(() => photoContentHashSync(bytes));

/// [photoContentHash] on the calling isolate, for code already on one.
String photoContentHashSync(List<int> bytes) {
  final digest = const DartSha256().hashSync(bytes).bytes;
  final out = StringBuffer();
  for (final byte in digest) {
    out.write(byte.toRadixString(16).padLeft(2, '0'));
  }
  return out.toString();
}
