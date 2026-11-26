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

  // A carried folder took over the household installed on this computer
  // before anything got here, once and only into an empty folder (see
  // `portable_takeover.dart`). Copying what it lacks at every start, as
  // until 3.0.3, filled a disk with a household of its own with another
  // household's pictures and indexes (#392).
  if (carried) return target;

  Directory legacy;
  try {
    legacy = await getApplicationDocumentsDirectory();
  } on Object {
    // A platform without one, or a plugin that is not there. Nothing to
    // carry over, and nothing worth failing startup for.
    return target;
  }

  // One installation succeeding another: moved, there is no reason to
  // keep two.
  await adoptLegacyDatabases(legacy: legacy, target: target);
  return target;
}

/// The journals SQLite keeps beside a database.
const _journalSuffixes = ['-journal', '-wal', '-shm'];

/// The databases an older version left in the documents folder: the
/// household database and the per-archive full-text indexes.
bool _isOurDatabase(String name) =>
    name.startsWith('preppsuite') && name.endsWith('.sqlite');

/// Takes the databases in [legacy] over into [target], by moving them.
///
/// Runs once, before anything opens them. A database already present in
/// [target] is left alone and the old one with it: overwriting a database
/// that is in use with one that was abandoned would lose exactly the data
/// this is meant to preserve.
///
/// A journal goes only with its own database (#392). Beside a database
/// that stayed where it was, the old one's journal would be read as the
/// journal of the other, and rolled back into it. So the journals are
/// moved first and the database after them, and when the database cannot
/// follow they are moved back.
///
/// Takes both directories rather than looking them up, so that what it
/// does can be tested without a platform underneath it.
Future<void> adoptLegacyDatabases({
  required Directory legacy,
  required Directory target,
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
      // Only into a place that holds no journal of its own: one there
      // without its database belongs to nobody this could tell.
      var occupied = false;
      for (final suffix in _journalSuffixes) {
        if (await File('$destination$suffix').exists()) occupied = true;
      }
      if (occupied) continue;
    } on Object {
      continue;
    }

    final moved = <(File, String)>[];
    try {
      for (final suffix in _journalSuffixes) {
        final journal = File('${entry.path}$suffix');
        if (!await journal.exists()) continue;
        moved.add((await _move(journal, '$destination$suffix'), journal.path));
      }
      await _move(entry, destination);
    } on Object {
      // The old database stays where it is, and its journals go back to
      // it.
      for (final (journal, origin) in moved.reversed) {
        try {
          await _move(journal, origin);
        } on Object {
          // Left beside nothing: there is no database of that name there.
        }
      }
    }
  }
}

/// Moves [file] to [destination]. Rename cannot cross a volume boundary;
/// copying and deleting can. Where the original cannot be deleted, the
/// copy goes again: one file in two places is two databases.
Future<File> _move(File file, String destination) async {
  try {
    return await file.rename(destination);
  } on FileSystemException {
    final copy = await file.copy(destination);
    try {
      await file.delete();
    } on Object {
      try {
        await copy.delete();
      } on Object {
        // Nothing more to try.
      }
      rethrow;
    }
    return copy;
  }
}
