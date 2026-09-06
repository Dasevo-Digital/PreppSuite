import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _folderKey = 'archiveDownloadFolder';

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
    final stored = prefs.getString(_folderKey);
    if (stored != null && stored.isNotEmpty) {
      final directory = Directory(stored);
      if (await directory.exists()) return directory;
    }
    return defaultFolder();
  }

  Future<void> use(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_folderKey, path);
  }

  /// Back to the platform default.
  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_folderKey);
  }

  Future<Directory> defaultFolder() async {
    final directory = await _platformDefault();
    await directory.create(recursive: true);
    return directory;
  }

  Future<Directory> _platformDefault() async {
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
