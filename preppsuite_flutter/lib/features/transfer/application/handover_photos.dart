import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import '../../../core/portable_paths.dart';
import '../../../local_db/database.dart';
import '../../inventory/application/inventory_photo_service.dart';
import '../../../core/photo_vault.dart';

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
    this.slot = 0,
  });

  final PhotoOwner owner;

  /// The row this belongs to, in the household both sides now share.
  final String clientId;

  /// Which of the row's photos this is, 0 to 2 (#211); 0 is the one the
  /// list shows, and the only one a possession has.
  ///
  /// Left out of the JSON when it is 0, which is also what a copy from
  /// before #211 reads: an older device sends what it has, the first
  /// photo, and takes a later one as a first one only where it has none.
  final int slot;

  /// The file's own name, which is a UUID the photo service made. Never a
  /// path: see [safeName] for why that matters.
  final String name;

  final Uint8List bytes;

  Map<String, Object?> toJson() => {
    'owner': owner.marker,
    'clientId': clientId,
    'name': name,
    if (slot != 0) 'slot': slot,
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
    final slot = safeSlot(owner, raw['slot']);
    if (owner == null || clientId is! String || clientId.isEmpty) return null;
    if (name == null || bytes is! String || slot == null) return null;
    try {
      return HandoverPhoto(
        owner: owner,
        clientId: clientId,
        name: name,
        bytes: base64Decode(bytes),
        slot: slot,
      );
    } on FormatException {
      return null;
    }
  }

  /// The photo's place on its row, or null when the row has no such place.
  ///
  /// Missing is 0, the way a copy from before #211 sends every picture.
  static int? safeSlot(PhotoOwner? owner, Object? raw) {
    final slot = raw ?? 0;
    if (slot is! int) return null;
    final places = owner == PhotoOwner.inventory ? maxItemPhotos : 1;
    return slot >= 0 && slot < places ? slot : null;
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
/// large inventory instead of sending the same first twenty again. Every
/// first photo before any second or third one: when the budget runs out,
/// the pictures the list shows are the ones that made it.
Future<List<HandoverPhoto>> readHouseholdPhotos(
  AppDatabase db, {
  required String householdId,
  PhotoRequest skip = const {},
  int budgetBytes = handoverPhotoBudgetBytes,
}) async {
  final found = await _photoPaths(db, householdId: householdId);
  found.sort(_bySlotThenPath);

  final photos = <HandoverPhoto>[];
  var used = 0;
  for (final row in found) {
    final file = File(InventoryPhotoService.resolvePhotoPath(row.path));
    final name = p.basename(file.path);
    if (skip.contains(name)) continue;
    if (!await file.exists()) continue;

    // Opened before it goes: the other device holds a different key, and
    // the handover payload is sealed for this one exchange anyway.
    Uint8List? bytes;
    try {
      bytes = await const PhotoVault().read(file);
    } on Object {
      bytes = null;
    }
    // Unreadable on this machine. One missing picture is not worth
    // failing a handover somebody is standing there waiting for.
    if (bytes == null) continue;
    if (used + bytes.length > budgetBytes) continue;
    used += bytes.length;
    photos.add(
      HandoverPhoto(
        owner: row.owner,
        clientId: row.clientId,
        name: name,
        bytes: bytes,
        slot: row.slot,
      ),
    );
  }
  return photos;
}

/// Writes [photos] into this device's photo folder and points the rows at
/// them. Answers how many pictures the household gained.
///
/// A row that already has a picture on this machine keeps it, place by
/// place (#211). The alternative — letting whichever device spoke last
/// decide — would mean a photo somebody replaced here coming back on the
/// next handover. A picture the row already shows in another place is not
/// taken a second time: somebody here moved it, and a restored backup asks
/// for nothing to be left out the way a handover does.
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

  final held = await _photoPaths(db, householdId: householdId);
  final existing = {
    for (final row in held) (row.owner, row.clientId, row.slot): row.path,
  };
  final shown = <(PhotoOwner, String), Set<String>>{};
  for (final row in held) {
    final file = File(InventoryPhotoService.resolvePhotoPath(row.path));
    if (!await file.exists()) continue;
    (shown[(row.owner, row.clientId)] ??= {}).add(p.basename(file.path));
  }

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
    final place = existing[(photo.owner, photo.clientId, photo.slot)];
    if (place != null &&
        await File(InventoryPhotoService.resolvePhotoPath(place)).exists()) {
      continue;
    }
    if (shown[(photo.owner, photo.clientId)]?.contains(photo.name) ?? false) {
      continue;
    }

    final target = File(p.join(directory.path, photo.name));
    try {
      if (!await target.exists()) {
        await const PhotoVault().write(target, photo.bytes);
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
        slot: photo.slot,
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
    if (written > 0) {
      taken++;
      existing[(photo.owner, photo.clientId, photo.slot)] = stored;
      (shown[(photo.owner, photo.clientId)] ??= {}).add(photo.name);
    }
  }
  return taken;
}

/// Every picture file this device holds for [householdId], with the row
/// it belongs to. Files that are not there are left out.
///
/// For the backup, which takes the pictures one at a time instead of in
/// a budgeted batch the way a handover does.
Future<List<({PhotoOwner owner, String clientId, int slot, File file})>>
householdPhotoFiles(AppDatabase db, {required String householdId}) async {
  final found = await _photoPaths(db, householdId: householdId);
  found.sort(_bySlotThenPath);
  return [
    for (final row in found)
      if (File(InventoryPhotoService.resolvePhotoPath(row.path)) case final file
          when file.existsSync())
        (owner: row.owner, clientId: row.clientId, slot: row.slot, file: file),
  ];
}

typedef _PhotoRow = ({
  PhotoOwner owner,
  String clientId,
  int slot,
  String path,
});

int _bySlotThenPath(_PhotoRow a, _PhotoRow b) {
  final bySlot = a.slot.compareTo(b.slot);
  return bySlot != 0 ? bySlot : a.path.compareTo(b.path);
}

/// Every picture the rows name, each with its place. The place is the
/// column it is in, not its position among the filled ones: a row that
/// lacks its second photo still has its third in place 2.
Future<List<_PhotoRow>> _photoPaths(
  AppDatabase db, {
  required String householdId,
}) async => [
  for (final row in await db.inventoryItemsForSync(householdId))
    for (final (slot, stored) in [
      row.photoPath,
      row.secondPhotoPath,
      row.thirdPhotoPath,
    ].indexed)
      if (stored case final path? when path.isNotEmpty)
        (
          owner: PhotoOwner.inventory,
          clientId: row.clientId,
          slot: slot,
          path: path,
        ),
  for (final row in await db.possessionsForSync(householdId))
    if (row.photoPath case final path?)
      if (path.isNotEmpty)
        (
          owner: PhotoOwner.possession,
          clientId: row.clientId,
          slot: 0,
          path: path,
        ),
];
