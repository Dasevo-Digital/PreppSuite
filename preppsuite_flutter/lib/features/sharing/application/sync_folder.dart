import 'dart:io';

import 'package:path/path.dart' as p;

/// The subdirectory PreppSuite claims inside the folder the user picked.
///
/// Named rather than writing into the folder root: people point this at a
/// Nextcloud or Syncthing directory they also use for other things, and
/// scattering `<uuid>.json` files across it would be rude.
const preppSuiteFolderName = 'preppsuite';

const _devicesFolderName = 'devices';
const _householdFileName = 'household.json';
const _probeFileName = '.preppsuite-write-test';

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

  /// The shared identity file, or null when this folder has never been
  /// used by PreppSuite.
  Future<String?> readHouseholdFile();

  Future<void> writeHouseholdFile(String contents);
}

/// A [SyncFolder] backed by an ordinary filesystem path.
///
/// Works wherever `dart:io` can reach the folder: macOS, Windows, Linux,
/// and Android as far as the picked path is permitted. Everything it does
/// is a plain file operation, so the folder stays readable — and
/// repairable — with a text editor.
class IoSyncFolder implements SyncFolder {
  IoSyncFolder(this.rootPath);

  /// The folder the user picked, without PreppSuite's own subdirectory.
  final String rootPath;

  Directory get _base => Directory(p.join(rootPath, preppSuiteFolderName));

  Directory get _devices => Directory(p.join(_base.path, _devicesFolderName));

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
  Future<String?> readDeviceFile(String deviceId) =>
      _readIfPresent(File(p.join(_devices.path, '$deviceId.json')));

  @override
  Future<void> writeDeviceFile(String deviceId, String contents) async {
    await _devices.create(recursive: true);
    await _writeAtomically(
      File(p.join(_devices.path, '$deviceId.json')),
      contents,
    );
  }

  @override
  Future<String?> readHouseholdFile() =>
      _readIfPresent(File(p.join(_base.path, _householdFileName)));

  @override
  Future<void> writeHouseholdFile(String contents) async {
    await _base.create(recursive: true);
    await _writeAtomically(
      File(p.join(_base.path, _householdFileName)),
      contents,
    );
  }

  Future<String?> _readIfPresent(File file) async {
    try {
      if (!await file.exists()) return null;
      return await file.readAsString();
    } on FileSystemException {
      // A file the sync engine is mid-download on, or one the user has no
      // permission for. Both are worth skipping rather than failing the
      // whole sync over — the next run picks it up.
      return null;
    }
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
