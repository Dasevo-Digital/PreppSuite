/// German names on the offline map.
///
/// The renderer's built-in style is the OpenMapTiles demo style, and that
/// style asks tiles for `{name_en}` on countries, states and towns. So a
/// German civil-protection app drew a map of „Germany" with „Cologne" in
/// „LOWER SAXONY" — in a screen somebody opens to find out where they
/// are.
///
/// Rewritten rather than replaced, for the same reason the dark map is
/// turned rather than written a second time (see `dark_map_style.dart`):
/// a hand-written style would be a second thing to keep in step with the
/// package's.
///
/// The order is the one [offline_poi_search] already uses against real
/// archives, with English appended as a last resort. `name:de` is where
/// OpenMapTiles puts the German name; `name` is the local one, which in
/// Germany is German anyway; `name_de` turns up in older extracts. Every
/// step can be missing, and the last one keeps a label from coming out
/// blank — an unlabelled town is worse than an English one.
library;

const _fields = ['name:de', 'name', 'name_de', 'name_en'];

/// Every name the style asks for, asked for in German first.
Object? germanMapLabels(Object? node) {
  if (node is List) return [for (final item in node) germanMapLabels(item)];
  if (node is Map) {
    return <String, dynamic>{
      for (final entry in node.entries)
        '${entry.key}': entry.key == 'text-field' && _namesAName(entry.value)
            ? _germanName
            : germanMapLabels(entry.value),
    };
  }
  return node;
}

/// Whether a `text-field` is one of the plain name templates.
///
/// Deliberately narrow: `{ref}` is a road number and has no language, and
/// anything the style expresses as an expression rather than a template
/// is left alone rather than guessed at.
bool _namesAName(Object? value) =>
    value is String &&
    const {'{name}', '{name_en}', '{name_de}'}.contains(value);

/// `["coalesce", ["get", "name:de"], …]` — the first field the feature
/// actually carries wins.
List<Object> get _germanName => [
  'coalesce',
  for (final field in _fields) ['get', field],
];
