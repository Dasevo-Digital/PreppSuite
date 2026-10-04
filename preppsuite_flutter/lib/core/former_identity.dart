import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Carrying a household over from the identifier the app had until 2.x.
///
/// Up to then the app was `de.status403.preppsuite` — the domain of a
/// private server, which has no business in a public identifier and none
/// at all in a store listing. Since then it is `de.dasevo.preppsuite`
/// everywhere, `.test` for the test copy.
///
/// The identifier is not cosmetic. It is where the data lives:
///
/// - macOS: the sandbox container `~/Library/Containers/<id>/…`
/// - Linux: `~/.local/share/<APPLICATION_ID>`
/// - Windows: `%APPDATA%\<CompanyName>\<ProductName>`, from `Runner.rc`
///
/// Without this, the first start under the new identifier would open an
/// empty household while the real one sat beside it under a name nobody
/// looks for. Android and iOS cannot be helped from here: a new identifier
/// is a new app there, with a sandbox the old one cannot be read from. A
/// household moves to it the ordinary way, through a backup.
///
/// Runs once, first thing, before the pointer to a chosen folder or any
/// database is read — both live in the directory being carried over.
Future<void> takeOverFormerIdentity() async {
  if (kIsWeb) return;
  try {
    final current = await getApplicationSupportDirectory();
    final former = formerSupportDirectory(
      current.path,
      platform: Platform.operatingSystem,
    );
    if (former == null) return;
    await adoptFormerDirectory(current: current, former: Directory(former));
  } on Object catch (error) {
    // Never a reason not to start. The old directory is still there, and
    // the next launch tries again.
    debugPrint('Former identifier not taken over: $error');
  }
}

/// Where [supportPath] was under the former identifier, or null when it
/// does not look like the current one.
///
/// Plain string work, so all three desktops can be tested on one machine.
@visibleForTesting
String? formerSupportDirectory(String supportPath, {required String platform}) {
  final windows = platform == 'windows';
  final separator = windows ? r'\' : '/';
  final parts = supportPath.split(separator);

  String? former(int i) {
    final part = parts[i];
    switch (platform) {
      case 'macos':
        const ids = {
          'de.dasevo.preppsuite': 'de.status403.preppsuite',
          'de.dasevo.preppsuite.test': 'de.status403.preppsuite.test',
        };
        return ids[part];
      case 'linux':
        return part == 'de.dasevo.preppsuite'
            ? 'de.status403.preppsuite'
            : null;
      case 'windows':
        // Two parts: <CompanyName>\<ProductName>.
        final lower = part.toLowerCase();
        final next = i + 1 < parts.length ? parts[i + 1].toLowerCase() : null;
        final previous = i > 0 ? parts[i - 1].toLowerCase() : null;
        if (lower == 'de.dasevo' && next == 'preppsuite') {
          return 'PreppSuite Contributors';
        }
        if (lower == 'preppsuite' && previous == 'de.dasevo') {
          return 'PreppSuite';
        }
        return null;
    }
    return null;
  }

  final result = [for (var i = 0; i < parts.length; i++) former(i) ?? parts[i]];
  final changed = [
    for (var i = 0; i < parts.length; i++) result[i] != parts[i],
  ].contains(true);
  return changed ? result.join(separator) : null;
}

/// Moves [former] to [current] if the household is there and not here.
///
/// Renamed, not copied, as one installation succeeding another always was
/// here (see `adoptLegacyDatabases`): there is no reason to keep two, and a
/// rename on one volume costs nothing whatever the photos weigh.
///
/// Where a rename cannot work — another volume, a file held open — the
/// directory is copied instead, into a sibling first and renamed into place
/// at the end, so an interrupted copy never looks like a household. The
/// former directory is then left as it is: nothing here deletes.
///
/// [current] is touched only while it is empty. `path_provider` creates it
/// on the way, so empty is the normal state on a first start; anything in
/// it means this installation has been used and is kept.
@visibleForTesting
Future<void> adoptFormerDirectory({
  required Directory current,
  required Directory former,
}) async {
  if (current.path == former.path) return;
  if (!await _holdsSomething(former)) return;
  if (await _holdsSomething(current)) return;

  if (await current.exists()) {
    // Empty but for Finder's file, which is the only thing allowed here.
    final finder = File('${current.path}${Platform.pathSeparator}.DS_Store');
    if (await finder.exists()) await finder.delete();
    await current.delete();
  }
  await current.parent.create(recursive: true);
  try {
    await former.rename(current.path);
    return;
  } on FileSystemException {
    // Falls through to the copy.
  }

  final partial = Directory('${current.path}.taking-over');
  if (await partial.exists()) await partial.delete(recursive: true);
  await _copy(former, partial);
  await partial.rename(current.path);
}

/// Whether [directory] has anything in it worth keeping.
///
/// Finder's `.DS_Store` does not count — it appears in any folder that was
/// once looked at, and it is not a household.
Future<bool> _holdsSomething(Directory directory) async {
  if (!await directory.exists()) return false;
  await for (final entry in directory.list(followLinks: false)) {
    final name = entry.uri.pathSegments.lastWhere((s) => s.isNotEmpty);
    if (name != '.DS_Store') return true;
  }
  return false;
}

Future<void> _copy(Directory from, Directory to) async {
  await to.create(recursive: true);
  await for (final entry in from.list(followLinks: false)) {
    final name = entry.uri.pathSegments.lastWhere((s) => s.isNotEmpty);
    final target = '${to.path}${Platform.pathSeparator}$name';
    if (entry is Directory) {
      await _copy(entry, Directory(target));
    } else if (entry is File) {
      await entry.copy(target);
    }
  }
}
