import 'dart:io';
import 'dart:convert';

import '../../../core/bounded_input.dart';
import '../../../core/resource_limits.dart';

import 'package:path/path.dart' as p;

/// The subdirectory PreppSuite claims inside the folder the user picked.
///
/// Named rather than writing into the folder root: people point this at a
/// Nextcloud or Syncthing directory they also use for other things, and
/// scattering `<uuid>.json` files across it would be rude.
const preppSuiteFolderName = 'preppsuite';

const _devicesFolderName = 'devices';
const _photosFolderName = 'photos';
const _householdFileName = 'household.json';
const _probeFileName = '.preppsuite-write-test';

/// The layout inside [preppSuiteFolderName], as paths relative to the
/// folder the user picked.
///
/// Shared by both implementations so that a folder written by a phone and
/// one written by a laptop are the same folder — Android reaches it
/// through the Storage Access Framework and cannot use `dart:io` at all,
/// but it must land in exactly these places.
const devicesDirectoryPath = '$preppSuiteFolderName/$_devicesFolderName';
const householdFilePath = '$preppSuiteFolderName/$_householdFileName';

String deviceFilePath(String deviceId) =>
    '$devicesDirectoryPath/$deviceId.json';

/// Where the household's pictures lie, sealed, in an encrypted folder
/// (#376). See `folder_photos.dart`.
const photosDirectoryPath = '$preppSuiteFolderName/$_photosFolderName';

String photoFilePath(String fileName) => '$photosDirectoryPath/$fileName';

/// A folder that can also hold the household's pictures (#376).
///
/// Apart from [SyncFolder] so that a folder which cannot -- a test's, or
/// one added later -- still syncs its rows: the pictures are what is left
/// out then, as they were before.
///
/// The rule of the folder holds here as well. Every picture file carries
/// the name of the device that wrote it, so no two devices ever write or
/// delete the same path; a picture two devices both hold is in the folder
/// once, from whichever put it there first.
abstract interface class SyncPhotoFolder {
  /// The names of the picture files, without their directory.
  Future<List<String>> listPhotoFiles();

  /// The sealed picture, or null when it is not there or not readable yet.
  Future<String?> readPhotoFile(String fileName);

  Future<void> writePhotoFile(String fileName, String contents);

  /// Best effort: a file that cannot go now goes on a later run.
  Future<void> deletePhotoFile(String fileName);
}

/// A directory two or more devices can both see — a Nextcloud, Syncthing,
/// Dropbox or iCloud Drive folder.
///
/// PreppSuite never talks to any of those services. It writes plain files
/// and lets whatever the user already trusts carry them, which is why this
/// interface is deliberately as small as a folder is: list, read, write.
///
/// The one rule the whole design rests on: **a device only ever writes its
/// own file.** Two people editing at once therefore never write the same
/// path, so the sync engine underneath never has to resolve a file
/// conflict — and those engines resolve them by keeping one copy and
/// renaming the other, which would silently lose a household's data.
abstract class SyncFolder {
  /// Whether the folder can actually be written to.
  ///
  /// Asked before the folder is accepted rather than at the first sync:
  /// on Android a picked directory frequently comes back as a path the
  /// app has no permission for, and finding that out at setup time is a
  /// message the user can act on.
  Future<bool> isWritable();

  /// The device ids that have a snapshot in this folder, this device
  /// included.
  Future<List<String>> listDeviceIds();

  Future<String?> readDeviceFile(String deviceId);

  Future<void> writeDeviceFile(String deviceId, String contents);

  /// The shared identity file, or null when it is not there.
  ///
  /// Throws when it is there and cannot be read (#312). Null is a statement
  /// about the folder, and what follows from it is that a new identity may
  /// be written. Over a real one that strands every other device, and in a
  /// sealed folder it takes the salt with it, so nobody can derive the key
  /// again. A device file can afford to read as absent, this one cannot.
  Future<String?> readHouseholdFile();

  Future<void> writeHouseholdFile(String contents);
}

/// A [SyncFolder] backed by an ordinary filesystem path.
///
/// Works wherever `dart:io` can reach the folder: macOS, Windows, Linux,
/// and Android as far as the picked path is permitted. Everything it does
/// is a plain file operation, so the folder stays readable — and
/// repairable — with a text editor.
class IoSyncFolder implements SyncFolder, SyncPhotoFolder {
  IoSyncFolder(this.rootPath);

  /// The folder the user picked, without PreppSuite's own subdirectory.
  final String rootPath;

  Directory get _base => Directory(p.join(rootPath, preppSuiteFolderName));

  Directory get _devices => Directory(p.join(_base.path, _devicesFolderName));

  Directory get _photos => Directory(p.join(_base.path, _photosFolderName));

  @override
  Future<bool> isWritable() async {
    try {
      await _devices.create(recursive: true);
      final probe = File(p.join(_base.path, _probeFileName));
      await probe.writeAsString('ok', flush: true);
      await probe.delete();
      return true;
    } on FileSystemException {
      return false;
    }
  }

  @override
  Future<List<String>> listDeviceIds() async {
    if (!await _devices.exists()) return const [];

    return [
      await for (final entry in _devices.list())
        if (entry is File && entry.path.endsWith('.json'))
          p.basenameWithoutExtension(entry.path),
    ];
  }

  @override
  Future<String?> readDeviceFile(String deviceId) async {
    try {
      return await _readIfPresent(
        File(p.join(_devices.path, '$deviceId.json')),
        maxSnapshotBytes,
      );
    } on FileSystemException {
      // A file the sync engine is mid-download on, or one the user has no
      // permission for. Both are worth skipping rather than failing the
      // whole sync over -- the next run picks it up.
      return null;
    } on FormatException {
      // Not text, so a damaged file: that one, and not the run.
      return null;
    }
  }

  @override
  Future<void> writeDeviceFile(String deviceId, String contents) async {
    if (utf8.encode(contents).length > maxSnapshotBytes) {
      throw const InputTooLarge(maxSnapshotBytes);
    }
    await _devices.create(recursive: true);
    await _writeAtomically(
      File(p.join(_devices.path, '$deviceId.json')),
      contents,
    );
  }

  @override
  Future<String?> readHouseholdFile() => _readIfPresent(
    File(p.join(_base.path, _householdFileName)),
    maxHouseholdMetadataBytes,
  );

  @override
  Future<void> writeHouseholdFile(String contents) async {
    if (utf8.encode(contents).length > maxHouseholdMetadataBytes) {
      throw const InputTooLarge(maxHouseholdMetadataBytes);
    }
    await _base.create(recursive: true);
    await _writeAtomically(
      File(p.join(_base.path, _householdFileName)),
      contents,
    );
  }

  @override
  Future<List<String>> listPhotoFiles() async {
    if (!await _photos.exists()) return const [];
    return [
      await for (final entry in _photos.list())
        if (entry is File && entry.path.endsWith('.json'))
          p.basename(entry.path),
    ];
  }

  @override
  Future<String?> readPhotoFile(String fileName) async {
    try {
      return await _readIfPresent(
        File(p.join(_photos.path, p.basename(fileName))),
        maxFolderPhotoBytes,
      );
    } on FileSystemException {
      return null;
    } on FormatException {
      return null;
    } on InputTooLarge {
      return null;
    }
  }

  @override
  Future<void> writePhotoFile(String fileName, String contents) async {
    if (utf8.encode(contents).length > maxFolderPhotoBytes) {
      throw const InputTooLarge(maxFolderPhotoBytes);
    }
    await _photos.create(recursive: true);
    await _writeAtomically(
      File(p.join(_photos.path, p.basename(fileName))),
      contents,
    );
  }

  @override
  Future<void> deletePhotoFile(String fileName) async {
    try {
      await File(p.join(_photos.path, p.basename(fileName))).delete();
    } on FileSystemException {
      // Already gone, or held open; the next run tries again.
    }
  }

  Future<String?> _readIfPresent(File file, int maxBytes) async {
    if (!await file.exists()) return null;
    return utf8.decode(
      await readBoundedBytes(
        file.openRead(),
        maxBytes: maxBytes,
        declaredLength: await file.length(),
        timeout: const Duration(seconds: 60),
      ),
    );
  }

  /// Writes to a temporary name and renames into place.
  ///
  /// Cloud sync engines watch the folder and start uploading the moment a
  /// file appears. Writing in place would hand them half a snapshot to
  /// distribute; a rename is atomic on every platform this runs on.
  Future<void> _writeAtomically(File target, String contents) async {
    final temp = File('${target.path}.tmp');
    await temp.writeAsString(contents, flush: true);
    await temp.rename(target.path);
  }
}
