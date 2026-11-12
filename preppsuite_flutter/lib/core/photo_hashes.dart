/// Which pictures a row has, as every device can say it (#376).
///
/// A row stores its photos as paths into this machine's own folder, which
/// mean nothing anywhere else. What does mean something everywhere is the
/// picture itself, so each place of a row is also named by the SHA-256 of
/// its picture, and those names travel with the row. The pictures follow
/// through an encrypted shared folder, under names derived from these
/// (`features/sharing/application/folder_photos.dart`).
///
/// A list is stored and sent as JSON: one entry per place -- three for an
/// inventory item, one for a possession -- each a hash or null for an empty
/// place. The list as a whole can also be missing, and that is a separate
/// statement: "not known", for a row from before #376 or one whose photos
/// changed here and have not been read since. The merge keeps the two
/// apart. Three empty places clear a picture on another device; an
/// unknown list never does, because the device saying it may simply never
/// have had the picture.
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

/// The stored column as a list; null for a missing or unreadable one.
List<String?>? decodePhotoHashes(String? stored, {required int places}) {
  if (stored == null) return null;
  try {
    return photoHashesFromJson(jsonDecode(stored), places: places);
  } on FormatException {
    return null;
  }
}

String encodePhotoHashes(List<String?> hashes) => jsonEncode(hashes);

/// Which of two different lists for the same version of a row stays.
///
/// Positive when [candidate] replaces [stored]. Two devices can hold one
/// version with different pictures: a handover before #376 left every
/// device the photo it had. Both then announce theirs, and without one
/// rule that every device applies the same way they would trade them back
/// and forth for ever. The list with more pictures stays -- losing a
/// picture is the worse mistake -- and between two equally full ones the
/// text decides, which is arbitrary but the same everywhere.
int comparePhotoHashes(String candidate, String stored) {
  int count(String encoded) {
    try {
      final raw = jsonDecode(encoded);
      return raw is List ? raw.where(isPhotoHash).length : 0;
    } on FormatException {
      return 0;
    }
  }

  final byCount = count(candidate).compareTo(count(stored));
  return byCount != 0 ? byCount : candidate.compareTo(stored);
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
