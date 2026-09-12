import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';

import 'platform_storage.dart';

/// The folder a carried copy of PreppSuite keeps everything in.
///
/// Presence is the switch: create a folder of this name beside the
/// program and the next launch uses it. Nothing is created on its own,
/// so an installed copy behaves exactly as it always has — which is the
/// point. A portable mode that turns itself on is a portable mode that
/// one day moves somebody's household without being asked.
///
/// German, like the folders the app already writes for downloads, because
/// it is a folder a person looks at in a file manager.
const portableFolderName = 'PreppSuite-Daten';

/// An override, for people who keep the data somewhere else entirely and
/// for the tests.
const portableEnvironmentVariable = 'PREPPSUITE_DATA';

/// The file that remembers a folder chosen through a panel.
///
/// Deliberately **not** in the preferences: the preferences are one of
/// the things that move into the portable folder, so storing the way
/// there inside them would be a circle. One line in the platform's own
/// Application Support, which always exists and is always writable.
const _pointerFileName = 'portable-data.txt';

/// Where the data actually is, and how it was decided.
class PortableLocation {
  const PortableLocation({required this.directory, required this.source});

  /// Null means the platform's own place — an ordinary installation.
  final Directory? directory;

  final PortableSource source;

  bool get isPortable => directory != null;
}

/// How a portable folder was found. Shown in the settings, because "it is
/// portable" is not a useful thing to read without "and here is why".
enum PortableSource {
  /// An ordinary installation.
  installed,

  /// [portableEnvironmentVariable] named it.
  environment,

  /// Chosen once through a panel and remembered.
  chosen,

  /// Found beside the program.
  besideTheProgram,
}

/// Whether a folder beside the program can be found without being picked.
///
/// Everywhere but macOS. There the app runs sandboxed — deliberately, so
/// that a folder picked once survives an update without the system asking
/// again — and a sandboxed app may not read a directory beside its own
/// bundle at all. So on macOS the folder is chosen once per Mac through a
/// panel, which is the same machinery the shared folder and the download
/// folder already use, and everything after that is identical.
bool get findsPortableFolderByItself {
  if (kIsWeb) return false;
  return Platform.isLinux || Platform.isWindows;
}

/// Whether this platform can be portable at all.
///
/// The desktops. On Android and iOS the system decides where an app's
/// data lives and there is no disk to carry it on.
bool get supportsPortableData {
  if (kIsWeb) return false;
  return Platform.isLinux || Platform.isWindows || Platform.isMacOS;
}

/// Works out where the data lives. Called once, before anything reads it.
///
/// Every step falls through rather than failing: a stick that was pulled
/// out, a folder that was renamed, a handle from another machine. The
/// worst outcome allowed here is an app that starts with the data it has
/// on this machine — never one that does not start.
Future<PortableLocation> resolvePortableLocation({
  Map<String, String>? environment,
  String? executablePath,
  bool? searchBesideProgram,
}) async {
  if (!supportsPortableData) {
    return const PortableLocation(
      directory: null,
      source: PortableSource.installed,
    );
  }

  final named =
      (environment ?? Platform.environment)[portableEnvironmentVariable];
  if (named != null && named.trim().isNotEmpty) {
    final directory = Directory(named.trim());
    if (await _usable(directory)) {
      return PortableLocation(
        directory: directory,
        source: PortableSource.environment,
      );
    }
  }

  final chosen = await _chosenDirectory();
  if (chosen != null) {
    return PortableLocation(
      directory: chosen,
      source: PortableSource.chosen,
    );
  }

  if (searchBesideProgram ?? findsPortableFolderByItself) {
    final beside = await _besideTheProgram(
      executablePath ?? Platform.resolvedExecutable,
    );
    if (beside != null) {
      return PortableLocation(
        directory: beside,
        source: PortableSource.besideTheProgram,
      );
    }
  }

  return const PortableLocation(
    directory: null,
    source: PortableSource.installed,
  );
}

/// Remembers [location] as the data folder, from the next launch on.
///
/// [handle] is what a sandboxed platform needs to reach it again; without
/// one the plain path is kept, which is all Windows and Linux need.
Future<void> rememberPortableFolder({
  required String location,
  String? handle,
}) async {
  final pointer = await _pointerFile();
  await pointer.writeAsString(
    handle == null || handle.isEmpty ? location : handle,
  );
}

/// Back to the platform's own place from the next launch on.
Future<void> forgetPortableFolder() async {
  final pointer = await _pointerFile();
  if (await pointer.exists()) await pointer.delete();
}

/// What the pointer file names, if anything it still points at.
Future<Directory?> _chosenDirectory() async {
  final File pointer;
  try {
    pointer = await _pointerFile();
    if (!await pointer.exists()) return null;
  } on Object {
    return null;
  }

  final stored = (await pointer.readAsString()).trim();
  if (stored.isEmpty) return null;

  // A handle has to be resolved, and resolving it is also what opens the
  // security scope that lets `dart:io` touch anything inside.
  final path = isNativeStorageHandle(stored)
      ? await resolveStoragePath(stored)
      : stored;
  if (path == null) return null;

  final directory = Directory(path);
  return await _usable(directory) ? directory : null;
}

Future<File> _pointerFile() async {
  final base = await getApplicationSupportDirectory();
  await base.create(recursive: true);
  return File('${base.path}${Platform.pathSeparator}$_pointerFileName');
}

/// Looks for the folder beside the program, and a few levels above it.
///
/// Several levels because "beside the program" is not one place: a Linux
/// release unpacks to `PreppSuite-x64/bundle/PreppSuite`, so the folder a
/// person would put next to what they unpacked is two levels up. Walking
/// up is forgiving in exactly the way that matters — it finds the folder
/// wherever somebody sensibly put it.
Future<Directory?> _besideTheProgram(String executablePath) async {
  var directory = File(executablePath).parent;

  for (var level = 0; level < 4; level++) {
    final candidate = Directory(
      '${directory.path}${Platform.pathSeparator}$portableFolderName',
    );
    if (await _usable(candidate)) return candidate;

    final parent = directory.parent;
    // The root, where `parent` is the directory itself.
    if (parent.path == directory.path) break;
    directory = parent;
  }
  return null;
}

/// Whether the folder is there and can actually be written to.
///
/// Written to, not merely present: a read-only disk, a stick mounted
/// without permission or a sandbox that denies the path all look like a
/// perfectly good directory until the first write fails — which would be
/// halfway through opening a database.
Future<bool> _usable(Directory directory) async {
  try {
    if (!await directory.exists()) return false;
    final probe = File(
      '${directory.path}${Platform.pathSeparator}.preppsuite-write-test',
    );
    await probe.writeAsString('');
    await probe.delete();
    return true;
  } on Object {
    return false;
  }
}
