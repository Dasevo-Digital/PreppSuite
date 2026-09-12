import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'platform_storage.dart';
import 'portable_data.dart';

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

/// Where everything this app writes for itself goes: the databases, the
/// product photos and the web view's working files.
///
/// The platform's own place, or the folder on the disk when this copy is
/// being carried on one. One function for all three, so that turning
/// portability on moves all of them together rather than most of them —
/// a household on a stick and its photos left behind on a machine is not
/// a portable copy, it is a broken one.
Future<Directory> appSupportDirectory() async {
  final portable = portableSupportDirectory;
  if (portable != null) {
    await portable.create(recursive: true);
    return portable;
  }
  return getApplicationSupportDirectory();
}

Future<Directory> _prepare() async {
  final carried = portableSupportDirectory != null;
  final target = await appSupportDirectory();
  await target.create(recursive: true);

  // Application Support is backed up to iCloud on iOS, the same as
  // Documents — only `Library/Caches` and what is explicitly marked are
  // left out. Everything this app knows about a household lives in these
  // databases: the emergency cards carry blood type, allergies, medication
  // and conditions, and the personal-document index carries the full text
  // of whatever papers were added to it.
  //
  // None of that is ours to upload. The app already offers a backup that
  // the household controls — one file, encrypted with a passphrase they
  // choose (see `BackupService`) — and the shared folder for a second
  // device. A silent copy in somebody's iCloud is a third route nobody
  // asked for.
  //
  // Set on the directory, so a database added later is covered without
  // anyone remembering to mark it.
  await excludeFromBackup(target.path);

  Directory legacy;
  try {
    legacy = carried
        // A carried copy takes what an installed one on this machine has,
        // once, so that putting the folder beside the program does not
        // turn a working household into an empty one.
        ? await getApplicationSupportDirectory()
        : await getApplicationDocumentsDirectory();
  } on Object {
    // A platform without one, or a plugin that is not there. Nothing to
    // carry over, and nothing worth failing startup for.
    return target;
  }

  // Copied and not moved when the copy is carried: the installation on
  // this machine is still somebody's, and a stick plugged in once must
  // not take the household off it. The move is right the other way round
  // — that case is one installation succeeding another.
  await adoptLegacyDatabases(legacy: legacy, target: target, move: !carried);
  // The photos with them, or the household arrives on the disk with
  // every picture missing. Only when the copy is carried: between two
  // installed versions the photos never moved in the first place.
  if (carried) await adoptPhotos(legacy: legacy, target: target);
  return target;
}

/// Copies the product photos from [legacy] into [target], once.
///
/// Only ever adds: a photo already in [target] is the one this copy took
/// and is never written over. Best-effort throughout — a picture that
/// does not arrive costs a thumbnail, and the item beside it is
/// unaffected, so there is nothing here worth failing startup for.
Future<void> adoptPhotos({
  required Directory legacy,
  required Directory target,
}) async {
  const folder = 'inventory_photos';
  final from = Directory('${legacy.path}${Platform.pathSeparator}$folder');
  final to = Directory('${target.path}${Platform.pathSeparator}$folder');
  if (from.path == to.path) return;

  try {
    if (!await from.exists()) return;
    await to.create(recursive: true);
    await for (final entry in from.list(followLinks: false)) {
      if (entry is! File) continue;
      final name = entry.uri.pathSegments.last;
      final destination = '${to.path}${Platform.pathSeparator}$name';
      if (await File(destination).exists()) continue;
      await entry.copy(destination);
    }
  } on Object {
    return;
  }
}

/// The file names an older version left in the documents folder.
///
/// The household database and the per-archive full-text indexes, each
/// possibly with the two journal files SQLite writes beside it.
bool _isOurDatabase(String name) {
  if (!name.startsWith('preppsuite')) return false;
  return name.contains('.sqlite');
}

/// Takes the databases in [legacy] over into [target].
///
/// Runs once, before anything opens them. A file already present in
/// [target] is left alone and the old one with it: overwriting a database
/// that is in use with one that was abandoned would lose exactly the data
/// this is meant to preserve.
///
/// [move] decides whether the old file is left behind. It is moved when
/// one installation succeeds another — there is no reason to keep two —
/// and copied when a carried copy is taking over what an installation on
/// this machine has, because that installation is still somebody's and
/// will be started again.
///
/// Takes both directories rather than looking them up, so that what it
/// does can be tested without a platform underneath it.
Future<void> adoptLegacyDatabases({
  required Directory legacy,
  required Directory target,
  bool move = true,
}) async {
  if (legacy.path == target.path) return;

  final List<FileSystemEntity> entries;
  try {
    if (!await legacy.exists()) return;
    entries = await legacy.list(followLinks: false).toList();
  } on Object {
    // On macOS without the sandbox, the documents folder is the user's
    // own and reading it needs their permission. Declined, or asked for
    // while nobody was looking, listing it throws — and that must not
    // reach the caller: it is the database directory being resolved, and
    // failing here would leave the app with no database at all rather
    // than with an empty one.
    //
    // Nothing is lost. The old file stays where it is, and the app is
    // usable; the alternative was an app that would not start.
    return;
  }

  for (final entry in entries) {
    if (entry is! File) continue;

    final name = entry.uri.pathSegments.last;
    if (!_isOurDatabase(name)) continue;

    final destination = '${target.path}${Platform.pathSeparator}$name';

    try {
      if (await File(destination).exists()) continue;
      if (!move) {
        await entry.copy(destination);
        continue;
      }
      await entry.rename(destination);
    } on FileSystemException {
      // Rename cannot cross a volume boundary — and a carried copy is
      // always on another volume. Copying and deleting can, and if even
      // that fails the old file simply stays put.
      try {
        await entry.copy(destination);
        if (move) await entry.delete();
      } on Object {
        continue;
      }
    }
  }
}
