import 'dart:io';

import 'package:path/path.dart' as p;

import 'platform_storage.dart' show excludeFromBackup;

/// A copy of the household's database a day, the last [keep] of them,
/// beside the database itself (#140).
///
/// The backup a household writes by hand is the one that survives a lost
/// device. This is for the device that is still there and whose database
/// is not: a write cut off by a flat battery, a disk that went bad under
/// one page, a sync that left the file half in one state and half in
/// another. Until now the only way back from that was the last manual
/// backup -- weeks old, or none -- and in the meantime the app opened on
/// an error.
///
/// Each copy is SQLite's own `VACUUM INTO` (see `AppDatabase.snapshotTo`),
/// so it is consistent and carries the same key: on an encrypted device a
/// copy is no more readable than the database. It lives in the same
/// folder, which on a portable copy is the stick and everywhere else the
/// app's own private storage, kept out of cloud backups like the database.
class DatabaseSnapshots {
  DatabaseSnapshots(this.databaseFile, {this.keep = 7});

  /// The live database the copies are of.
  final File databaseFile;
  final int keep;

  /// A day apart, give or take: the app opened at 08:00 one day and 07:00
  /// the next should still take one.
  static const interval = Duration(hours: 20);

  Directory get folder =>
      Directory(p.join(p.dirname(databaseFile.path), 'snapshots'));

  String _stem() => p.basenameWithoutExtension(databaseFile.path);

  /// The copies there are, newest first.
  Future<List<File>> list() async {
    if (!await folder.exists()) return const [];
    final prefix = '${_stem()}-';
    final copies = <File>[
      await for (final entry in folder.list())
        if (entry is File &&
            p.basename(entry.path).startsWith(prefix) &&
            entry.path.endsWith('.sqlite'))
          entry,
    ];
    // The name carries the time, so it sorts as it was taken.
    copies.sort((a, b) => p.basename(b.path).compareTo(p.basename(a.path)));
    return copies;
  }

  /// When [file] was taken, read from its name.
  DateTime? takenAt(File file) {
    final match = RegExp(
      r'-(\d{4})(\d{2})(\d{2})T(\d{2})(\d{2})(\d{2})\.sqlite$',
    ).firstMatch(p.basename(file.path));
    if (match == null) return null;
    final parts = [for (var i = 1; i <= 6; i++) int.parse(match.group(i)!)];
    return DateTime.utc(
      parts[0],
      parts[1],
      parts[2],
      parts[3],
      parts[4],
      parts[5],
    );
  }

  /// Takes one through [write] when the newest is older than [interval],
  /// and drops the ones past [keep]. Answers the new copy, or null when
  /// none was due.
  ///
  /// [write] is `AppDatabase.snapshotTo`. The copy is written under a
  /// temporary name and renamed when complete, so a copy cut off half way
  /// is never mistaken for one.
  Future<File?> takeIfDue(
    Future<void> Function(String path) write, {
    DateTime? now,
  }) async {
    final at = (now ?? DateTime.now()).toUtc();
    final existing = await list();
    // A household that has just been encrypted must not keep a week of
    // readable copies beside its encrypted database: they are replaced at
    // once rather than aging out.
    final readable = await _isPlaintext(databaseFile)
        ? const <File>[]
        : [
            for (final copy in existing)
              if (await _isPlaintext(copy)) copy,
          ];
    final newest = existing.isEmpty ? null : takenAt(existing.first);
    if (readable.isEmpty &&
        newest != null &&
        at.difference(newest) < interval) {
      return null;
    }

    await folder.create(recursive: true);
    await excludeFromBackup(folder.path);
    final name = '${_stem()}-${_stamp(at)}.sqlite';
    final partial = File(p.join(folder.path, '$name.part'));
    if (await partial.exists()) await partial.delete();
    await write(partial.path);
    final copy = await partial.rename(p.join(folder.path, name));

    for (final old in {...readable, ...(await list()).skip(keep)}) {
      try {
        await old.delete();
      } on FileSystemException {
        // Next time.
      }
    }
    return copy;
  }

  /// Puts [snapshot] in place of the database, which must be closed.
  ///
  /// The damaged file is not deleted: it is renamed beside itself with
  /// the time, together with the journal files SQLite keeps next to it.
  /// What is in it may still be wanted, and the one thing this must never
  /// do is turn a damaged household into a missing one.
  Future<void> restore(File snapshot, {DateTime? now}) async {
    final stamp = _stamp((now ?? DateTime.now()).toUtc());
    for (final suffix in const ['', '-wal', '-shm', '-journal']) {
      final file = File('${databaseFile.path}$suffix');
      if (await file.exists()) {
        await file.rename('${databaseFile.path}.damaged-$stamp$suffix');
      }
    }
    await snapshot.copy(databaseFile.path);
  }

  /// Whether [file] starts with SQLite's own header, which an encrypted
  /// database does not.
  static Future<bool> _isPlaintext(File file) async {
    try {
      final handle = await file.open();
      try {
        final head = await handle.read(16);
        return String.fromCharCodes(head) == 'SQLite format 3\u0000';
      } finally {
        await handle.close();
      }
    } on FileSystemException {
      return false;
    }
  }

  static String _stamp(DateTime at) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${at.year}${two(at.month)}${two(at.day)}'
        'T${two(at.hour)}${two(at.minute)}${two(at.second)}';
  }
}
