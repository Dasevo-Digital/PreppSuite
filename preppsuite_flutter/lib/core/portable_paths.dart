import 'dart:io';

import 'portable_data.dart';

/// Marks a location as being inside the data folder rather than at a
/// fixed place on one machine.
///
/// A stored path is absolute, and on a carried disk an absolute path is
/// a guess about a machine: the stick is `E:` today and `F:` tomorrow,
/// `/Volumes/PREPP` on a Mac and `/media/marco/PREPP` on Linux. The map
/// archive, the encyclopedias and the scanned documents would all be
/// "not found" after the first replug — a portable program with a broken
/// library, which is worse than no portable program.
///
/// So anything that lies inside the data folder is remembered by where it
/// is *within* it, and put back together at the other end. Anything
/// outside keeps its absolute path, which is correct: a file on the
/// machine's own disk is exactly as findable as it ever was.
const portableLocationPrefix = 'daten:';

/// How [path] should be written down.
///
/// Unchanged unless it is inside the data folder, so an installed copy
/// stores precisely what it always stored.
String storeLocation(String path) {
  final root = portableSupportDirectory;
  if (root == null) return path;

  final inside = _relativeTo(root.path, path);
  return inside == null ? path : '$portableLocationPrefix$inside';
}

/// The other direction.
///
/// A stored value without the marker is handed back untouched: every
/// location written before this existed is an absolute path, and so is
/// every Android and iOS handle.
String readLocation(String stored) {
  if (!stored.startsWith(portableLocationPrefix)) return stored;

  final relative = stored.substring(portableLocationPrefix.length);
  final root = portableSupportDirectory;
  if (root == null) {
    // Marked as being in the data folder, and there is no data folder:
    // the stick was set up portable and is now being read by an
    // installed copy. Nothing can be done with it, and handing back the
    // bare relative path is what makes the screen say "not found"
    // instead of opening something else.
    return relative;
  }
  return '${root.path}${Platform.pathSeparator}'
      '${relative.replaceAll('/', Platform.pathSeparator)}';
}

/// [path] as written from [root], or null when it is not underneath it.
///
/// Always with forward slashes, so a folder written on Windows is
/// readable on Linux and the other way round. That is not a nicety: the
/// whole point is one disk carried between machines.
String? _relativeTo(String root, String path) {
  final normalizedRoot = _slashes(root);
  final normalizedPath = _slashes(path);

  // Compared case-blind on Windows, where two paths differ in case
  // without differing — but sliced out of the original, because the
  // name that comes back has to be the name on the disk.
  final prefix = '$normalizedRoot/';
  final comparable = Platform.isWindows
      ? normalizedPath.toLowerCase()
      : normalizedPath;
  final comparablePrefix = Platform.isWindows ? prefix.toLowerCase() : prefix;

  if (!comparable.startsWith(comparablePrefix)) return null;
  return normalizedPath.substring(prefix.length);
}

/// Forward slashes throughout, and no trailing one.
String _slashes(String path) {
  var normalized = path.replaceAll(r'\', '/');
  while (normalized.endsWith('/') && normalized.length > 1) {
    normalized = normalized.substring(0, normalized.length - 1);
  }
  return normalized;
}
