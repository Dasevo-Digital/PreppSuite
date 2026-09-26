import 'dart:convert' show jsonEncode;

/// A fingerprint of the finished map style, to be mixed into the theme's
/// identity.
///
/// `vector_map_tiles` keeps **rendered tiles on disk**, and the file name
/// it keeps them under is built from the theme's `id` and `version`. Both
/// come out of the package's own style data, so neither changes when this
/// app changes that style — it only turns the colours over for the dark
/// map and asks for German names. The consequence is not subtle: after
/// the change to German labels the map still drew „Germany" and
/// „Cologne", because it was handing back pictures rendered weeks
/// earlier. Nothing was wrong with the style, the theme or the archive;
/// the map simply never re-rendered.
///
/// A fingerprint over the finished style makes that impossible to repeat.
/// Any change to a colour, a label field or a layer gives a different id,
/// the old pictures stop being looked up, and the cache ages them out on
/// its own. A hand-maintained version number would do the same job right
/// up to the first time somebody forgets to bump it.
String mapStyleFingerprint(Object? style) {
  // FNV-1a, 32 bit. Deterministic across runs, platforms and releases,
  // which is the whole requirement for a cache key; nothing here is
  // about security, and a collision costs one stale tile.
  var hash = 0x811c9dc5;
  for (final unit in jsonEncode(style).codeUnits) {
    hash = ((hash ^ unit) * 0x01000193) & 0xffffffff;
  }
  return hash.toRadixString(16).padLeft(8, '0');
}
