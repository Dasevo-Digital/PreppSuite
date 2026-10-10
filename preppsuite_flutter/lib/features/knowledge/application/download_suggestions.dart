/// Documents in the Downloads folder, offered for the library (#33).
///
/// A PDF that was saved from a browser lands in Downloads and stays
/// there, unknown to the search, until somebody remembers the add button
/// and finds the file again in a picker. So the library looks there
/// itself and offers what it finds -- and offers is all it does: it reads
/// the names in that one folder and nothing inside them, and a file goes
/// into the library only when somebody taps it.
///
/// Computers only, the same platforms that can take in a whole folder
/// (see `document_folder_import.dart`). A phone's app cannot list its
/// Downloads without the system picker, which already opens there.
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'document_folder_import.dart';
import 'personal_document_store.dart';

class DownloadSuggestion {
  const DownloadSuggestion({
    required this.path,
    required this.bytes,
    required this.modified,
  });

  final String path;
  final int bytes;
  final DateTime modified;

  String get name => p.basename(path);
}

/// The system's Downloads folder -- and none at all under `flutter test`.
///
/// On a Mac the lookup works inside a test run as well and answers with
/// the developer's own Downloads. A test must never read a real folder of
/// a real person's files, names included, so the run is told apart by the
/// variable the test runner sets, and a test that wants suggestions hands
/// in a folder of its own.
Future<Directory?> systemDownloadsFolder() =>
    Platform.environment.containsKey('FLUTTER_TEST')
    ? Future.value(null)
    : getDownloadsDirectory();

/// At most this many at once: the newest, which are the ones somebody is
/// likely to have just saved.
const maxDownloadSuggestions = 12;

/// What lies directly in [downloads] that the library could read and does
/// not have yet, newest first. Anything [dismissed] -- by path -- is left
/// out. An unreadable or missing folder offers nothing rather than
/// failing: these are suggestions, and none is a fine answer.
Future<List<DownloadSuggestion>> downloadSuggestions({
  required Directory? downloads,
  required Iterable<PersonalDocument> known,
  required Set<String> dismissed,
}) async {
  if (downloads == null || !await downloads.exists()) return const [];
  final knownLocations = {for (final document in known) document.location};
  final knownNames = {
    for (final document in known) document.label.toLowerCase(),
  };

  final found = <DownloadSuggestion>[];
  try {
    await for (final entry in downloads.list(followLinks: false)) {
      if (entry is! File) continue;
      final name = p.basename(entry.path);
      if (name.startsWith('.')) continue;
      final dot = name.lastIndexOf('.');
      if (dot < 0) continue;
      if (!documentFileExtensions.contains(
        name.substring(dot + 1).toLowerCase(),
      )) {
        continue;
      }
      if (dismissed.contains(entry.path)) continue;
      // By location where the library holds a plain path, by name where
      // it holds a bookmark that names no file.
      if (knownLocations.contains(entry.path)) continue;
      if (knownNames.contains(name.toLowerCase())) continue;
      final stat = await entry.stat();
      found.add(
        DownloadSuggestion(
          path: entry.path,
          bytes: stat.size,
          modified: stat.modified,
        ),
      );
    }
  } on FileSystemException {
    return const [];
  }
  found.sort((a, b) => b.modified.compareTo(a.modified));
  return found.take(maxDownloadSuggestions).toList();
}

/// The suggestions somebody said no to, so they do not come back.
class DismissedDownloads {
  const DismissedDownloads();

  static const _key = 'knowledge.downloadSuggestions.dismissed.v1';

  Future<Set<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return {...?prefs.getStringList(_key)};
  }

  Future<void> add(String path) async {
    final prefs = await SharedPreferences.getInstance();
    final current = {...?prefs.getStringList(_key), path};
    await prefs.setStringList(_key, current.toList()..sort());
  }
}
