/// Finding things by name, across an app that got too big to navigate.
///
/// Sixty-two screens and ten tabs, plus whatever the household has
/// written down. Matching is deliberately dull — no scoring model, no
/// fuzzy distance — because a search that guesses is worse than one that
/// does not: somebody typing "Pegel" wants the gauge, and a list that
/// puts three near-misses above it has answered a question nobody asked.
///
/// What it does do is fold the way German is actually typed. "Notgepack"
/// finds "Notgepäck" and "Notgepäck" finds "Notgepack", because on a
/// keyboard without umlauts, or in a hurry, both happen.
library;

/// Something that can be found.
class SearchCandidate {
  const SearchCandidate({
    required this.key,
    required this.label,
    this.context,
    this.aliases = const [],
  });

  /// The caller's own handle back to the thing. Never shown.
  final String key;

  /// What is shown, and the first thing matched against.
  final String label;

  /// Where it lives — a tab name, a room, the list an item belongs to.
  /// Shown underneath, and matched too: "Keller" should find what is in
  /// the cellar.
  final String? context;

  /// Words that are not in the label. See [AppDestination.aliases] for
  /// why these are not translated.
  final List<String> aliases;
}

/// How well a candidate answered, lowest first.
enum SearchRank {
  /// The name begins with what was typed. "Not" → "Notgepäck".
  nameStart,

  /// A later word in the name does. "gepäck" → "Notgepäck".
  wordStart,

  /// The name contains it somewhere.
  nameContains,

  /// Only where it lives, or a word nobody sees, matched.
  elsewhere,
}

class SearchMatch {
  const SearchMatch(this.candidate, this.rank);

  final SearchCandidate candidate;
  final SearchRank rank;
}

/// Lower case, and umlauts folded the way they are typed without them.
///
/// Also strips the combining marks a Mac produces for "ä" typed as
/// option-u then a, which is a different string from the single
/// character and would otherwise never match it.
String foldForSearch(String text) {
  final buffer = StringBuffer();
  for (final rune in text.toLowerCase().runes) {
    buffer.write(switch (rune) {
      0x00e4 || 0x00e0 || 0x00e1 || 0x00e2 => 'a',
      0x00f6 || 0x00f2 || 0x00f3 || 0x00f4 => 'o',
      0x00fc || 0x00f9 || 0x00fa || 0x00fb => 'u',
      0x00e8 || 0x00e9 || 0x00ea || 0x00eb => 'e',
      0x00df => 'ss',
      // Combining diaeresis, grave, acute, circumflex: dropped, which
      // leaves the plain letter that carried them.
      0x0300 || 0x0301 || 0x0302 || 0x0308 => '',
      _ => String.fromCharCode(rune),
    });
  }
  return buffer.toString();
}

/// What [query] finds among [candidates], best first.
///
/// An empty or blank query finds nothing rather than everything: a list
/// of every screen and every tin in the house is not an answer, and the
/// screen has something better to show while nobody has typed yet.
List<SearchMatch> searchCandidates(
  String query,
  Iterable<SearchCandidate> candidates, {
  int limit = 50,
}) {
  final needle = foldForSearch(query.trim());
  if (needle.isEmpty) return const [];

  final matches = <SearchMatch>[];
  for (final candidate in candidates) {
    final rank = _rank(needle, candidate);
    if (rank != null) matches.add(SearchMatch(candidate, rank));
  }

  matches.sort((a, b) {
    final byRank = a.rank.index.compareTo(b.rank.index);
    if (byRank != 0) return byRank;
    // Then by name, so the same query always gives the same order.
    // Two equally good answers that swap places between keystrokes are
    // two answers somebody taps the wrong one of.
    return foldForSearch(
      a.candidate.label,
    ).compareTo(foldForSearch(b.candidate.label));
  });

  return matches.length <= limit ? matches : matches.sublist(0, limit);
}

SearchRank? _rank(String needle, SearchCandidate candidate) {
  final label = foldForSearch(candidate.label);
  if (label.startsWith(needle)) return SearchRank.nameStart;

  for (final word in label.split(_wordBreak)) {
    if (word.startsWith(needle)) return SearchRank.wordStart;
  }
  if (label.contains(needle)) return SearchRank.nameContains;

  final context = candidate.context;
  if (context != null && foldForSearch(context).contains(needle)) {
    return SearchRank.elsewhere;
  }
  for (final alias in candidate.aliases) {
    if (foldForSearch(alias).contains(needle)) return SearchRank.elsewhere;
  }
  return null;
}

/// Spaces, and the punctuation that joins words in a title: "Sturm,
/// Kälte und Schnee", "Strom- und Heizungsausfall".
final _wordBreak = RegExp(r'[\s,.;:/()\[\]-]+');
