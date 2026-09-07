import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Where the app's own databases live.
///
/// Application Support rather than the documents folder, for two reasons.
///
/// The first is that on a desktop macOS without the sandbox, "documents"
/// is the user's own `~/Documents`. A database dropped in there is
/// clutter beside their letters and their tax returns.
///
/// The second matters more: that path is the same for every build of this
/// app, whatever bundle identifier it carries. Two installs meant to be
/// independent — PreppSuite and PreppSuite Test — would open one file and
/// write over each other's household. Application Support is per bundle
/// identifier on macOS, and app-private on every other platform, which is
/// what a database wants in both cases.
///
/// Photos and the WebView2 working directory were already kept here; the
/// databases were the outlier.
Future<Directory> appDatabaseDirectory() => _prepared ??= _prepare();

Future<Directory>? _prepared;

Future<Directory> _prepare() async {
  final target = await getApplicationSupportDirectory();
  await target.create(recursive: true);

  Directory legacy;
  try {
    legacy = await getApplicationDocumentsDirectory();
  } on Object {
    // A platform without one, or a plugin that is not there. Nothing to
    // carry over, and nothing worth failing startup for.
    return target;
  }

  await adoptLegacyDatabases(legacy: legacy, target: target);
  return target;
}

/// The file names an older version left in the documents folder.
///
/// The household database and the per-archive full-text indexes, each
/// possibly with the two journal files SQLite writes beside it.
bool _isOurDatabase(String name) {
  if (!name.startsWith('preppsuite')) return false;
  return name.contains('.sqlite');
}

/// Moves the databases an older version wrote into [legacy].
///
/// Runs once, before anything opens them. A file already present in
/// [target] is left alone and the old one with it: overwriting a database
/// that is in use with one that was abandoned would lose exactly the data
/// this is meant to preserve.
///
/// Takes both directories rather than looking them up, so that what it
/// does can be tested without a platform underneath it.
Future<void> adoptLegacyDatabases({
  required Directory legacy,
  required Directory target,
}) async {
  if (legacy.path == target.path || !await legacy.exists()) return;

  await for (final entry in legacy.list(followLinks: false)) {
    if (entry is! File) continue;

    final name = entry.uri.pathSegments.last;
    if (!_isOurDatabase(name)) continue;

    final destination = '${target.path}${Platform.pathSeparator}$name';
    if (await File(destination).exists()) continue;

    try {
      await entry.rename(destination);
    } on FileSystemException {
      // Rename cannot cross a volume boundary. Copying and deleting can.
      await entry.copy(destination);
      await entry.delete();
    }
  }
}
