/// Whether an archive in the Kiwix library is already on this device
/// (#37).
///
/// The library listed every archive as if none were here, so a 50 GB
/// encyclopedia could be started a second time by somebody who had only
/// meant to look. Kiwix rebuilds its archives every few months under a new
/// dated file name, so "already here" has two answers: this very build, or
/// an older one -- which is when downloading again is worth it.
library;

import 'kiwix_catalogue.dart';
import 'zim_store.dart';

enum CataloguePresence {
  /// Nothing of this archive is here.
  absent,

  /// This very file is here.
  sameBuild,

  /// The same archive in the same flavour is here, but another build of
  /// it -- or one whose build cannot be told, added before file names
  /// were kept.
  otherBuild,
}

CataloguePresence presenceOf(KiwixEntry entry, List<StoredArchive> library) {
  var found = CataloguePresence.absent;
  for (final archive in library) {
    final file = archive.fileName ?? _fileNameIn(archive.location);
    if (file == entry.fileName) return CataloguePresence.sameBuild;
    if (file != null && _sameArchive(file, entry)) {
      found = CataloguePresence.otherBuild;
    } else if (file == null &&
        (archive.title == entry.title || archive.label == entry.title)) {
      // A title is shared by every flavour and every build, so it can only
      // say that something of this archive is here.
      found = CataloguePresence.otherBuild;
    }
  }
  return found;
}

/// `wikipedia_de_all_mini_2026-10.zim` for the entry named
/// `wikipedia_de_all` in flavour `mini`, whatever the date.
///
/// The date has to follow straight after, so that `wikipedia_de` cannot
/// claim `wikipedia_de_all_maxi_2026-10.zim` as its own.
bool _sameArchive(String file, KiwixEntry entry) {
  if (!file.startsWith('${entry.name}_')) return false;
  final rest = file.substring(entry.name.length + 1).split('_');
  final date = RegExp(r'^\d{4}-\d{2}(\.zim)?$');
  if (entry.flavour.isEmpty) return rest.length == 1 && date.hasMatch(rest[0]);
  return rest.length == 2 && rest[0] == entry.flavour && date.hasMatch(rest[1]);
}

/// The file a location names, where it names one: a path, or the last
/// segment of an Android document URI. A security bookmark names none.
String? _fileNameIn(String location) {
  if (location.startsWith('bookmark://')) return null;
  final decoded = Uri.decodeComponent(location);
  final name = decoded.split(RegExp(r'[/\\:]')).last;
  return name.toLowerCase().endsWith('.zim') ? name : null;
}
