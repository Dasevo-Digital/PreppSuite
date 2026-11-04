/// The order a person looks names up in (#283).
///
/// `String.compareTo` compares UTF-16 code units: every capital before
/// every small letter, and every letter with a mark after "z". The stores
/// came out as "apfelmus, Nudeln, Zucker, Äpfel, Öl", and a list of
/// stations read the same way put "Überlingen" below "Zwiesel". SQLite's
/// default collation is the same comparison, so the database cannot be
/// asked for the order either.
///
/// The key here is the German dictionary order (DIN 5007-1): case is
/// ignored, ä, ö and ü sort as a, o and u, ß as ss, and the accents of the
/// other languages the app speaks drop away the same way. One letter is
/// kept: ñ is a letter of its own in Spanish, after n and before o, and
/// folding it would put "piña" before "pino". Where two names fold to the
/// same key, the names themselves decide, so the order is still total
/// and the same on every device.
library;

const _folded = {
  'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a', 'æ': 'ae',
  'ç': 'c',
  'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
  'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i',
  // After every n and before o: see above.
  'ñ': 'n\uFFFF',
  'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o', 'ø': 'o', 'œ': 'oe',
  'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u',
  'ý': 'y', 'ÿ': 'y',
  'ß': 'ss',
};

/// What [name] is sorted by.
///
/// A name can also arrive with its marks as separate characters ("a"
/// followed by a combining diaeresis), as a file name from macOS or text
/// pasted from some PDFs does; those marks drop away too, and a combining
/// tilde after n is the Spanish letter.
String nameSortKey(String name) {
  final lower = name.trim().toLowerCase();
  final key = StringBuffer();
  var previous = 0;
  for (final rune in lower.runes) {
    if (rune >= 0x300 && rune <= 0x36F) {
      if (rune == 0x303 && previous == 0x6E) key.write('\uFFFF');
    } else {
      final char = String.fromCharCode(rune);
      key.write(_folded[char] ?? char);
    }
    previous = rune;
  }
  return key.toString();
}

/// [a] before [b] in the order of [nameSortKey], the names themselves
/// where the keys are the same.
int compareNames(String a, String b) {
  final byKey = nameSortKey(a).compareTo(nameSortKey(b));
  return byKey != 0 ? byKey : a.compareTo(b);
}

/// [items] sorted by [name], each key worked out once rather than at
/// every comparison.
List<T> sortedByName<T>(Iterable<T> items, String Function(T item) name) {
  final keyed = [
    for (final item in items) (item, name(item), nameSortKey(name(item))),
  ];
  keyed.sort((a, b) {
    final byKey = a.$3.compareTo(b.$3);
    return byKey != 0 ? byKey : a.$2.compareTo(b.$2);
  });
  return [for (final entry in keyed) entry.$1];
}
