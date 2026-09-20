import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import '../../../core/portable_paths.dart';
import '../../../local_db/database.dart';
import '../../inventory/application/inventory_photo_service.dart';

/// The pictures of the stock, travelling with it.
///
/// They are the one part of a household that is not in the snapshot, and
/// for a good reason: what the database holds is a *path* into one
/// device's own directory, which means nothing on another machine. So the
/// snapshot carries no photo at all, and a second device used to show an
/// inventory of grey placeholders.
///
/// These travel beside the snapshot rather than inside it, and only on a
/// local handover. That is deliberate:
///
///  * The **QR chain** paints the payload on screen as a run of pictures.
///    A single 300 kB photo is some two hundred more frames to film; the
///    inventory would never finish.
///  * The **shared folder** republishes a whole snapshot per device per
///    sync. Photos in there would be re-uploaded every few minutes,
///    forever, to say the same thing.
///
/// A handover is neither: two devices in one room, one request, once. So
/// the bytes go there and nowhere else.
///
/// The receiving side asks for what it lacks — see [PhotoRequest] — so a
/// second handover between the same two devices carries nothing twice.

/// How much picture data one handover will carry.
///
/// A cap and not a promise. Photos are stored at up to 2000 pixels, so
/// this is roughly a hundred of them; what does not fit is left for the
/// next handover, which will ask for exactly the ones still missing.
const handoverPhotoBudgetBytes = 20 * 1024 * 1024;

/// Which table a picture belongs to.
///
/// Stored as a short marker rather than the Dart enum name so that
/// renaming the enum cannot change the wire format.
enum PhotoOwner {
  inventory('inventory'),
  possession('possession');

  const PhotoOwner(this.marker);
  final String marker;

  static PhotoOwner? fromMarker(Object? raw) {
    for (final value in values) {
      if (value.marker == raw) return value;
    }
    return null;
  }
}

/// One picture, and the row it belongs to.
class HandoverPhoto {
  const HandoverPhoto({
    required this.owner,
    required this.clientId,
    required this.name,
    required this.bytes,
  });

  final PhotoOwner owner;

  /// The row this belongs to, in the household both sides now share.
  final String clientId;

  /// The file's own name, which is a UUID the photo service made. Never a
  /// path: see [safeName] for why that matters.
  final String name;

  final Uint8List bytes;

  Map<String, Object?> toJson() => {
    'owner': owner.marker,
    'clientId': clientId,
    'name': name,
    'bytes': base64Encode(bytes),
  };

  /// Null for anything that is not a picture this app would have written.
  ///
  /// The far side is not trusted here even though it held up a QR code:
  /// the name goes into a file path, and a name that climbs out of the
  /// photo directory would write wherever it liked.
  static HandoverPhoto? fromJson(Object? raw) {
    if (raw is! Map<String, Object?>) return null;
    final owner = PhotoOwner.fromMarker(raw['owner']);
    final clientId = raw['clientId'];
    final name = safeName(raw['name']);
    final bytes = raw['bytes'];
    if (owner == null || clientId is! String || clientId.isEmpty) return null;
    if (name == null || bytes is! String) return null;
    try {
      return HandoverPhoto(
        owner: owner,
        clientId: clientId,
        name: name,
        bytes: base64Decode(bytes),
      );
    } on FormatException {
      return null;
    }
  }

  /// The bare file name, or null when it is anything else.
  ///
  /// `p.basename` alone is not enough: on Windows it leaves a drive
  /// letter in place, and `..` survives it untouched. So the result is
  /// checked rather than trusted.
  static String? safeName(Object? raw) {
    if (raw is! String || raw.isEmpty) return null;
    final name = p.basename(raw);
    if (name != raw) return null;
    if (name == '.' || name == '..') return null;
    if (name.contains('/') || name.contains(r'\') || name.contains(':')) {
      return null;
    }
    return name;
  }
}

/// What a device already has, so the other side does not send it again.
typedef PhotoRequest = Set<String>;

/// The names of every picture this device holds for [householdId].
Future<PhotoRequest> localPhotoNames(
  AppDatabase db, {
  required String householdId,
}) async {
  final names = <String>{};
  for (final stored in await _photoPaths(db, householdId: householdId)) {
    final file = InventoryPhotoService.resolvePhotoPath(stored.path);
    if (await File(file).exists()) names.add(p.basename(file));
  }
  return names;
}

/// The pictures this device can send, leaving out anything in [skip].
///
/// Sorted by name so that two handovers in a row make progress through a
/// large inventory instead of sending the same first twenty again.
Future<List<HandoverPhoto>> readHouseholdPhotos(
  AppDatabase db, {
  required String householdId,
  PhotoRequest skip = const {},
  int budgetBytes = handoverPhotoBudgetBytes,
}) async {
  final found = await _photoPaths(db, householdId: householdId);
  found.sort((a, b) => a.path.compareTo(b.path));

  final photos = <HandoverPhoto>[];
  var used = 0;
  for (final row in found) {
    final file = File(InventoryPhotoService.resolvePhotoPath(row.path));
    final name = p.basename(file.path);
    if (skip.contains(name)) continue;
    if (!await file.exists()) continue;

    final Uint8List bytes;
    try {
      bytes = await file.readAsBytes();
    } on Object {
      // Unreadable on this machine. One missing picture is not worth
      // failing a handover somebody is standing there waiting for.
      continue;
    }
    if (used + bytes.length > budgetBytes) continue;
    used += bytes.length;
    photos.add(
      HandoverPhoto(
        owner: row.owner,
        clientId: row.clientId,
        name: name,
        bytes: bytes,
      ),
    );
  }
  return photos;
}

/// Writes [photos] into this device's photo folder and points the rows at
/// them. Answers how many pictures the household gained.
///
/// A row that already has a picture on this machine keeps it. The
/// alternative — letting whichever device spoke last decide — would mean
/// a photo somebody replaced here coming back on the next handover.
/// [into] is where the files land. Left out, it is this copy's own photo
/// folder, which is what the app wants; a test hands in a temporary one so
/// that exercising this needs no platform directory plugin.
Future<int> applyHouseholdPhotos(
  AppDatabase db, {
  required String householdId,
  required List<HandoverPhoto> photos,
  Directory? into,
}) async {
  if (photos.isEmpty) return 0;

  final existing = {
    for (final row in await _photoPaths(db, householdId: householdId))
      (row.owner, row.clientId): row.path,
  };

  final Directory directory;
  try {
    directory = into ?? await const InventoryPhotoService().photosDirectory();
  } on Object {
    // No writable support directory. Nothing to do and nothing to say:
    // the rows travelled, only their pictures did not.
    return 0;
  }

  var taken = 0;
  for (final photo in photos) {
    final held = existing[(photo.owner, photo.clientId)];
    if (held != null &&
        await File(InventoryPhotoService.resolvePhotoPath(held)).exists()) {
      continue;
    }

    final target = File(p.join(directory.path, photo.name));
    try {
      if (!await target.exists()) {
        await target.writeAsBytes(photo.bytes, flush: true);
      }
    } on Object {
      continue;
    }

    final stored = storeLocation(target.path);
    final written = switch (photo.owner) {
      PhotoOwner.inventory => await db.setInventoryPhotoPath(
        householdId: householdId,
        clientId: photo.clientId,
        photoPath: stored,
      ),
      PhotoOwner.possession => await db.setPossessionPhotoPath(
        householdId: householdId,
        clientId: photo.clientId,
        photoPath: stored,
      ),
    };
    // Zero means the row is not here — an older snapshot, or a row that
    // was deleted between the two halves of the handover. The file stays
    // where it is; a stray picture costs a few kilobytes, and the next
    // handover will find the row.
    if (written > 0) taken++;
  }
  return taken;
}

typedef _PhotoRow = ({PhotoOwner owner, String clientId, String path});

Future<List<_PhotoRow>> _photoPaths(
  AppDatabase db, {
  required String householdId,
}) async => [
  for (final row in await db.inventoryItemsForSync(householdId))
    if (row.photoPath case final path?)
      if (path.isNotEmpty)
        (owner: PhotoOwner.inventory, clientId: row.clientId, path: path),
  for (final row in await db.possessionsForSync(householdId))
    if (row.photoPath case final path?)
      if (path.isNotEmpty)
        (owner: PhotoOwner.possession, clientId: row.clientId, path: path),
];
