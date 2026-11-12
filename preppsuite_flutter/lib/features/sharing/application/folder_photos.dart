/// The household's pictures in an encrypted shared folder (#376).
///
/// Until #376 the pictures reached another device only by a handover or a
/// backup; a second device at the folder showed grey placeholders. They
/// could not ride in the device files: those are written whole on every
/// change, and a megabyte of photos in each would be uploaded again every
/// few minutes for ever. So each picture is a file of its own, written
/// once:
///
///     preppsuite/photos/<name>-<device>.json
///
/// sealed with the folder's key in the envelope the device files use.
/// `<name>` is derived from the picture's SHA-256 with a key of its own,
/// so the folder says nothing about which pictures they are, and a device
/// that holds a row's list (`photo_hashes.dart`) knows what to look for.
/// `<device>` is the device that wrote it: no two devices write or delete
/// the same path, which is the folder's one rule. A picture two devices
/// hold is in the folder once, from whichever put it there first.
///
/// Only in an encrypted folder. A plain one is readable by the cloud
/// provider and anyone with the account, and the possessions list exists
/// to photograph valuables with their serial numbers.
library;

import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart' show Value;
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../../core/photo_hashes.dart';
import '../../../core/photo_vault.dart';
import '../../../core/portable_paths.dart';
import '../../../core/resource_limits.dart';
import '../../../local_db/database.dart';
import '../../inventory/application/inventory_photo_service.dart';
import '../../inventory/application/photo_content_index.dart';
import 'folder_crypto.dart';
import 'sync_folder.dart';

/// How many megabytes of pictures one run sends, and how many it fetches.
///
/// A cap per run and not a promise: a household's first sync can hold a
/// few hundred pictures, and a run that sealed all of them would keep the
/// folder busy for minutes. What does not fit goes on the next run, two
/// minutes later.
const folderPhotoBudgetBytes = 32 * 1024 * 1024;

/// The names pictures have in one folder.
class FolderPhotoNames {
  FolderPhotoNames._(this._key);

  /// Derived from the folder's key under a label of its own, so the names
  /// and the seal never share a key.
  static Future<FolderPhotoNames> forKey(FolderKey key) async {
    final derived = await Hkdf(hmac: Hmac.sha256(), outputLength: 32).deriveKey(
      secretKey: SecretKey(key.bytes),
      info: utf8.encode('preppsuite.folder-photos.v1'),
    );
    return FolderPhotoNames._(Uint8List.fromList(await derived.extractBytes()));
  }

  final Uint8List _key;
  final _known = <String, String>{};

  /// The name picture [hash] has in the folder.
  Future<String> nameOf(String hash) async {
    final kept = _known[hash];
    if (kept != null) return kept;
    final mac = await Hmac.sha256().calculateMac(
      utf8.encode(hash),
      secretKey: SecretKey(_key),
    );
    final name = _hex(mac.bytes);
    _known[hash] = name;
    return name;
  }
}

String _hex(List<int> bytes) => [
  for (final byte in bytes) byte.toRadixString(16).padLeft(2, '0'),
].join();

final _photoFile = RegExp(r'^([0-9a-f]{64})-([A-Za-z0-9_-]+)\.json$');

/// The file a device writes for the picture named [name].
String folderPhotoFileName(String name, String deviceId) =>
    '$name-$deviceId.json';

/// The picture's name and the device that wrote it, or null for anything
/// that is not a picture file this app writes.
({String name, String deviceId})? parseFolderPhotoFileName(String fileName) {
  final match = _photoFile.firstMatch(fileName);
  if (match == null) return null;
  return (name: match.group(1)!, deviceId: match.group(2)!);
}

/// One place on a row: where its picture lies here, and which one it is.
typedef _Place = ({
  bool possession,
  String clientId,
  int slot,
  String? path,
  String? wanted,
});

/// Writes down which pictures this device holds, for the rows whose list
/// was not set by an edit. Answers how many lists it changed.
///
/// That is a row from before #376, or one whose pictures changed here
/// without the screen being able to read them. What comes out is a list
/// *seen* here: the places this device can show, and nothing about the
/// others -- a device that never got a picture sees an empty place where
/// there is none, and must not make it empty anywhere. A row this device
/// holds no picture of gets no list at all. A list set by an edit is left
/// alone; it knows more than these files.
///
/// Runs for every folder, plain ones too, and before this run reads the
/// other devices' files: what this device holds is in its own list before
/// anybody else's can be taken for it.
Future<int> fillSeenPhotoLists(
  AppDatabase db, {
  required String householdId,
  required PhotoContentIndex index,
}) async {
  Future<List<String?>> seenHere(List<String?> paths) async => [
    for (final path in paths)
      path == null || path.isEmpty
          ? null
          : await index.hashOf(
              File(InventoryPhotoService.resolvePhotoPath(path)),
            ),
  ];

  PhotoList? next(PhotoList? stored, List<String?> seen) {
    if (stored != null && !stored.seen) return null;
    if (seen.every((hash) => hash == null)) return null;
    final joined = PhotoList(
      stored == null ? seen : joinPhotoPlaces(stored.places, seen),
      seen: true,
    );
    return joined == stored ? null : joined;
  }

  var changed = 0;
  for (final row in await db.inventoryItemsForSync(householdId)) {
    if (row.deletedAt != null) continue;
    final stored = decodePhotoList(
      row.photoHashes,
      places: inventoryPhotoPlaces,
    );
    if (stored != null && !stored.seen) continue;
    final list = next(
      stored,
      await seenHere([row.photoPath, row.secondPhotoPath, row.thirdPhotoPath]),
    );
    if (list == null) continue;
    changed += await db.replaceInventoryPhotoHashes(
      householdId: householdId,
      clientId: row.clientId,
      expected: row.photoHashes,
      hashes: encodePhotoList(list),
    );
  }
  for (final row in await db.possessionsForSync(householdId)) {
    if (row.deletedAt != null) continue;
    final stored = decodePhotoList(
      row.photoHashes,
      places: possessionPhotoPlaces,
    );
    if (stored != null && !stored.seen) continue;
    final list = next(stored, await seenHere([row.photoPath]));
    if (list == null) continue;
    changed += await db.replacePossessionPhotoHashes(
      householdId: householdId,
      clientId: row.clientId,
      expected: row.photoHashes,
      hashes: encodePhotoList(list),
    );
  }
  await index.flush();
  return changed;
}

/// What one run did with the pictures.
class FolderPhotoResult {
  const FolderPhotoResult({
    this.fetched = 0,
    this.emptied = 0,
    this.sent = 0,
  });

  /// Places that now show the picture their row names.
  final int fetched;

  /// Places emptied because their row no longer has a picture there.
  final int emptied;

  /// Pictures this device put into the folder.
  final int sent;
}

/// Brings the pictures of one household into line with the rows, through
/// one encrypted folder.
///
/// Free of Riverpod, and of the platform's photo directory when a test
/// hands one in, so the whole exchange runs against an in-memory folder.
class FolderPhotoSync {
  FolderPhotoSync({
    required AppDatabase database,
    required this._folder,
    required this._key,
    required this.deviceId,
    required this.householdId,
    required this._index,
    this._vault = const PhotoVault(),
    Directory? photosDirectory,
    this.budgetBytes = folderPhotoBudgetBytes,
  }) : _db = database,
       _directory = photosDirectory;

  final AppDatabase _db;
  final SyncPhotoFolder _folder;
  final FolderKey _key;
  final String deviceId;
  final String householdId;
  final PhotoContentIndex _index;
  final PhotoVault _vault;
  final Directory? _directory;
  final int budgetBytes;

  FolderPhotoNames? _names;
  Future<FolderPhotoNames> _namer() async =>
      _names ??= await FolderPhotoNames.forKey(_key);

  Future<Directory> _photos() async =>
      _directory ?? await const InventoryPhotoService().photosDirectory();

  /// The picture files in the folder, by name.
  Future<Map<String, List<String>>> _listing() async {
    final byName = <String, List<String>>{};
    for (final fileName in await _folder.listPhotoFiles()) {
      final parsed = parseFolderPhotoFileName(fileName);
      if (parsed == null) continue;
      (byName[parsed.name] ??= []).add(fileName);
    }
    return byName;
  }

  /// Every place of every row still in the household.
  Future<List<_Place>> _places() async => [
    for (final row in await _db.inventoryItemsForSync(householdId))
      if (row.deletedAt == null)
        for (final (slot, path) in [
          row.photoPath,
          row.secondPhotoPath,
          row.thirdPhotoPath,
        ].indexed)
          (
            possession: false,
            clientId: row.clientId,
            slot: slot,
            path: path == null || path.isEmpty ? null : path,
            wanted: _wanted(
              decodePhotoList(row.photoHashes, places: inventoryPhotoPlaces),
              slot,
            ),
          ),
    for (final row in await _db.possessionsForSync(householdId))
      if (row.deletedAt == null)
        (
          possession: true,
          clientId: row.clientId,
          slot: 0,
          path: row.photoPath == null || row.photoPath!.isEmpty
              ? null
              : row.photoPath,
          wanted: _wanted(
            decodePhotoList(row.photoHashes, places: possessionPhotoPlaces),
            0,
          ),
        ),
  ];

  /// What a place wants when nothing can be said about it -- its row's list
  /// is not known, or was only seen somewhere and names nothing here -- and
  /// nothing is done to it.
  static const _unknown = '?';

  /// The picture [list] wants in [slot]: a hash, null for a place an edit
  /// emptied, or [_unknown].
  static String? _wanted(PhotoList? list, int slot) {
    if (list == null) return _unknown;
    final hash = list.places[slot];
    return hash == null && list.seen ? _unknown : hash;
  }

  /// Sends what the folder lacks and fetches what this device lacks.
  Future<FolderPhotoResult> exchange() async {
    final names = await _namer();
    final listing = await _listing();
    final directory = await _photos();
    final places = await _places();

    // Each picture the rows want and this device holds, to send where the
    // folder lacks it; and each place that does not show what its row
    // wants, to fetch for. Every first picture before any second one: when
    // a budget runs out, the ones the lists show are the ones that made it.
    final held = <({String hash, File file, int slot})>[];
    final mismatched = <_Place>[];
    for (final place in places) {
      if (place.wanted == _unknown) continue;
      final file = place.path == null
          ? null
          : File(InventoryPhotoService.resolvePhotoPath(place.path!));
      final holds = file == null ? null : await _index.hashOf(file);
      if (holds != null && holds == place.wanted) {
        held.add((hash: holds, file: file!, slot: place.slot));
      } else if (place.wanted != null || place.path != null) {
        mismatched.add(place);
      }
    }
    held.sort((a, b) => a.slot.compareTo(b.slot));
    mismatched.sort((a, b) => a.slot.compareTo(b.slot));

    var sent = 0;
    var budget = budgetBytes;
    final offered = <String>{};
    for (final picture in held) {
      if (!offered.add(picture.hash)) continue;
      final name = await names.nameOf(picture.hash);
      if (listing[name]?.isNotEmpty ?? false) continue;
      // Looked at before it is opened: a picture the folder would refuse
      // sealed -- Base64 makes four bytes of three -- would otherwise be
      // read and sealed again on every run, and refused every time.
      if (!_fitsTheFolder(picture.file)) continue;
      final bytes = await _vault.read(picture.file);
      if (bytes == null || bytes.length > budget) continue;
      try {
        final fileName = folderPhotoFileName(name, deviceId);
        await _folder.writePhotoFile(
          fileName,
          await encryptBytesForFolder(bytes, _key),
        );
        (listing[name] ??= []).add(fileName);
        budget -= bytes.length;
        sent++;
      } on Object catch (error, stack) {
        // One picture that cannot go now goes on a later run.
        _log('a picture could not be sent', error, stack);
      }
    }

    var fetched = 0;
    var emptied = 0;
    _fetchBudget = budgetBytes;
    // Released only at the end: with two pictures trading places, the file
    // one place gives up is the one the other is about to take.
    final released = <String>[];
    for (final place in mismatched) {
      final wanted = place.wanted;
      if (wanted == null) {
        // The row has no picture here any more: another device took it out.
        if (await _point(place, null) > 0) {
          emptied++;
          if (place.path case final path?) released.add(path);
        }
        continue;
      }
      final arrived =
          await _copyHeld(wanted, directory) ??
          await _fetch(wanted, names, listing, directory);
      if (arrived == null) continue;
      if (await _point(place, storeLocation(arrived.path)) > 0) {
        fetched++;
        if (place.path case final path?) released.add(path);
      } else {
        // The place changed while this run was fetching: somebody saved a
        // picture there. Theirs stays, and this copy goes.
        released.add(arrived.path);
      }
    }
    await _letGo(released);
    await _index.flush();
    _lastListing = listing;
    return FolderPhotoResult(fetched: fetched, emptied: emptied, sent: sent);
  }

  /// The folder's picture files as [exchange] left them, for [cleanUp]: on
  /// Android every listing is a query per file, and once per run is enough.
  Map<String, List<String>>? _lastListing;

  /// Whether the sealed picture in [file] stays within what the folder
  /// takes. A stat, so it costs nothing on the runs where it does not fit.
  static bool _fitsTheFolder(File file) {
    try {
      return file.lengthSync() * 4 ~/ 3 + 4096 <= maxFolderPhotoBytes;
    } on FileSystemException {
      return false;
    }
  }

  int _fetchBudget = 0;

  /// A copy of a picture this device already holds under another place,
  /// as a file of its own: two places never share a file, so that taking
  /// a picture off one item cannot take it off another.
  Future<File?> _copyHeld(String hash, Directory directory) async {
    final source = await _index.fileWith(hash, directory);
    if (source == null) return null;
    final target = File(p.join(directory.path, '${const Uuid().v4()}.jpg'));
    try {
      await source.copy(target.path);
    } on FileSystemException {
      return null;
    }
    await _index.remember(target, hash);
    return target;
  }

  /// The picture [hash] out of the folder, checked and put away, or null.
  Future<File?> _fetch(
    String hash,
    FolderPhotoNames names,
    Map<String, List<String>> listing,
    Directory directory,
  ) async {
    final name = await names.nameOf(hash);
    for (final fileName in [...?listing[name]]) {
      if (_fetchBudget <= 0) return null;
      final raw = await _folder.readPhotoFile(fileName);
      if (raw == null) continue;
      final bytes = await decryptBytesFromFolder(raw, _key);
      // Sealed with this key and still not the picture asked for: a file
      // renamed in the folder. Whoever did that can write there, but
      // cannot make one picture stand in for another.
      if (bytes == null || await photoContentHash(bytes) != hash) continue;
      _fetchBudget -= bytes.length;
      final target = File(p.join(directory.path, '${const Uuid().v4()}.jpg'));
      try {
        await _vault.write(target, bytes);
      } on Object catch (error, stack) {
        _log('a picture could not be stored', error, stack);
        return null;
      }
      await _index.remember(target, hash);
      return target;
    }
    return null;
  }

  /// Points [place] at [path], only while it still holds what this run
  /// read: a picture saved there in the meantime is not written over.
  Future<int> _point(_Place place, String? path) => place.possession
      ? _db.setPossessionPhotoPath(
          householdId: householdId,
          clientId: place.clientId,
          photoPath: path,
          onlyIf: Value(place.path),
        )
      : _db.setInventoryPhotoPath(
          householdId: householdId,
          clientId: place.clientId,
          photoPath: path,
          slot: place.slot,
          onlyIf: Value(place.path),
        );

  /// Deletes the files places showed before, unless a place still shows
  /// them.
  Future<void> _letGo(List<String> released) async {
    if (released.isEmpty) return;
    final shown = {
      for (final place in await _places())
        if (place.path case final path?)
          InventoryPhotoService.resolvePhotoPath(path),
    };
    for (final stored in released) {
      final file = InventoryPhotoService.resolvePhotoPath(stored);
      if (shown.contains(file)) continue;
      try {
        await File(file).delete();
      } on FileSystemException {
        // Already gone.
      }
    }
  }

  /// Takes this device's own pictures out of the folder once no row of
  /// the household names them any more. Answers how many went.
  ///
  /// A row elsewhere that still wants one -- a device that has not caught
  /// up with a replaced picture yet -- keeps its own copy, and should it
  /// ever be wanted again, the device that holds it puts it back.
  Future<int> cleanUp() async {
    final names = await _namer();
    final wanted = <String>{};
    for (final place in await _places()) {
      final hash = place.wanted;
      if (hash == null || hash == _unknown) continue;
      wanted.add(await names.nameOf(hash));
    }
    var removed = 0;
    final files = switch (_lastListing) {
      final listing? => [for (final names in listing.values) ...names],
      null => await _folder.listPhotoFiles(),
    };
    for (final fileName in files) {
      final parsed = parseFolderPhotoFileName(fileName);
      if (parsed == null || parsed.deviceId != deviceId) continue;
      if (wanted.contains(parsed.name)) continue;
      await _folder.deletePhotoFile(fileName);
      removed++;
    }
    await _index.prune(await _photos());
    return removed;
  }

  static void _log(String message, Object error, StackTrace stack) =>
      developer.log(
        message,
        name: 'preppsuite.sharing',
        error: error,
        stackTrace: stack,
      );
}
