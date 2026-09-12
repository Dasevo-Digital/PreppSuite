import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/platform_storage.dart';
import '../../../core/portable_data.dart';
import '../../../core/portable_paths.dart';

const _folderKey = 'archiveDownloadFolder';

/// The handle that makes [_folderKey] usable again after a restart.
///
/// Only macOS writes one. There the folder was picked from inside a
/// sandbox, and the path alone is a place the app is not allowed to go
/// until the bookmark behind this handle has opened the way.
const _handleKey = 'archiveDownloadFolderHandle';

/// Whether the user may point downloads somewhere of their own.
///
/// Desktop only. On Android and iOS the platform decides where an app may
/// write, and offering a choice there would mean driving the storage
/// bridge for something not worth the moving parts.
bool get supportsChosenDownloadFolder {
  if (kIsWeb) return false;
  return Platform.isMacOS || Platform.isLinux || Platform.isWindows;
}

/// Where downloaded archives are put.
///
/// A downloaded archive is the one file the app does write itself, and it
/// is the largest thing on the device — so it goes somewhere the user can
/// find, move and delete without the app's help, and it is never written
/// into a cache the system may sweep.
class DownloadFolder {
  const DownloadFolder();

  /// The folder in use: the one that was chosen, or the platform's
  /// sensible default.
  ///
  /// A folder that has gone away — an unplugged disk, a restored backup
  /// from another machine — falls back rather than failing, because the
  /// alternative is a download that cannot start and cannot be fixed from
  /// inside the app.
  Future<Directory> current() async {
    final prefs = await SharedPreferences.getInstance();

    // The handle first, where there is one: on macOS the stored path is
    // unreachable until the bookmark has opened the scope, so asking
    // `exists()` about it would answer no and quietly fall back to the
    // default — losing the folder the user chose rather than reporting
    // it.
    final handle = prefs.getString(_handleKey);
    if (handle != null && handle.isNotEmpty) {
      final resolved = await resolveStoragePath(handle);
      if (resolved != null) {
        final directory = Directory(resolved);
        if (await directory.exists()) return directory;
      }
    }

    final stored = prefs.getString(_folderKey);
    if (stored != null && stored.isNotEmpty) {
      // A download folder on the same disk as the app moves with it.
      final directory = Directory(readLocation(stored));
      if (await directory.exists()) return directory;
    }
    return defaultFolder();
  }

  /// Remembers a chosen folder. [handle] is what a sandboxed platform
  /// needs to reach it again; [path] is kept either way, for display and
  /// for the platforms that need nothing else.
  Future<void> use(String path, {String? handle}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_folderKey, storeLocation(path));
    if (handle == null || handle.isEmpty) {
      await prefs.remove(_handleKey);
    } else {
      await prefs.setString(_handleKey, handle);
    }
  }

  /// Back to the platform default.
  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_folderKey);
    await prefs.remove(_handleKey);
  }

  Future<Directory> defaultFolder() async {
    final directory = await _platformDefault();
    await directory.create(recursive: true);
    return directory;
  }

  Future<Directory> _platformDefault() async {
    // A carried copy puts its archives on the disk it is carried on.
    // Anything else would be absurd: the point of the copy is that it
    // works on a machine that is not yours, and ~/Downloads there is
    // somebody else's folder — on a public machine possibly one that is
    // wiped at logout.
    final carried = portableSupportDirectory;
    if (carried != null) {
      return Directory('${carried.path}${Platform.pathSeparator}Archive');
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        // The app's own Documents folder, which `UIFileSharingEnabled`
        // makes visible in Files — so an archive can be moved off the
        // device without the app being involved.
        return getApplicationDocumentsDirectory();

      case TargetPlatform.android:
        // App-specific external storage: no permission to ask for, and
        // usually the roomier of the two volumes.
        final external = await getExternalStorageDirectory();
        return external ?? await getApplicationDocumentsDirectory();

      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
      case TargetPlatform.fuchsia:
        final downloads = await getDownloadsDirectory();
        final base = downloads ?? await getApplicationDocumentsDirectory();
        // A subfolder of its own: these files are large enough that
        // finding them again matters.
        return Directory('${base.path}${Platform.pathSeparator}PreppSuite');
    }
  }
}
