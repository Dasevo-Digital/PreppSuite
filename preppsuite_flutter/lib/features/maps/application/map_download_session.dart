import 'dart:convert';
import 'dart:io';

import 'map_download_plan.dart';
import 'pmtiles_writer.dart';

/// A map download that was started and not finished.
///
/// Written beside the scratch file the moment a download begins, and
/// removed when the archive is assembled. Its whole purpose is the next
/// launch: a country is tens of thousands of tiles and over an hour, and
/// nobody leaves an app open that long.
class MapDownloadSession {
  const MapDownloadSession({
    required this.plan,
    required this.targetPath,
    required this.label,
    required this.startedAt,
  });

  final MapDownloadPlan plan;

  /// Where the finished archive goes. Kept so a resumed download lands in
  /// the same place rather than beside its own first attempt.
  final String targetPath;

  final String label;
  final DateTime startedAt;

  Map<String, Object?> toJson() => {
    'plan': plan.toJson(),
    'target': targetPath,
    'label': label,
    'startedAt': startedAt.toUtc().toIso8601String(),
  };

  static MapDownloadSession? fromJson(Object? json) {
    if (json is! Map) return null;

    final plan = MapDownloadPlan.fromJson(json['plan']);
    final target = json['target'];
    if (plan == null || target is! String || target.isEmpty) return null;

    return MapDownloadSession(
      plan: plan,
      targetPath: target,
      label: '${json['label'] ?? ''}',
      startedAt:
          DateTime.tryParse('${json['startedAt']}')?.toLocal() ??
          DateTime.now(),
    );
  }
}

/// Reads and writes the unfinished download in a folder.
///
/// A file rather than preferences: it belongs with the scratch file it
/// describes, so moving the download folder or clearing it by hand takes
/// the whole download with it and never leaves a session pointing at
/// bytes that are gone.
class MapDownloadSessionStore {
  const MapDownloadSessionStore();

  static File fileIn(Directory directory) =>
      File('${directory.path}${Platform.pathSeparator}download.json');

  /// The unfinished download in [directory], or null.
  ///
  /// Null too when the scratch file it describes has gone: a session
  /// without its bytes would offer to resume something that would start
  /// from nothing.
  Future<MapDownloadSession?> read(Directory directory) async {
    final file = fileIn(directory);
    if (!await file.exists()) return null;
    if (!await PmTilesWriter.scratchFileIn(directory).exists()) return null;

    try {
      return MapDownloadSession.fromJson(
        jsonDecode(await file.readAsString()),
      );
    } on FormatException {
      // A file cut short by the process ending. Nothing to resume from.
      return null;
    }
  }

  Future<void> write(Directory directory, MapDownloadSession session) async {
    await directory.create(recursive: true);
    await fileIn(directory).writeAsString(jsonEncode(session.toJson()));
  }

  /// How many tiles the interrupted download already holds.
  ///
  /// Counted from the journal rather than remembered in the session file:
  /// the journal is the only record that is written as the download runs,
  /// so it is the only one that is right after a crash.
  Future<int> storedTileCount(Directory directory) async {
    final journal = PmTilesWriter.journalFileIn(directory);
    if (!await journal.exists()) return 0;

    final lines = await journal.readAsLines();
    return lines.where((line) => line.split(' ').length == 3).length;
  }

  /// Removes the session and the working files with it.
  Future<void> clear(Directory directory) async {
    for (final file in [
      fileIn(directory),
      PmTilesWriter.scratchFileIn(directory),
      PmTilesWriter.journalFileIn(directory),
    ]) {
      if (await file.exists()) await file.delete();
    }
  }
}
