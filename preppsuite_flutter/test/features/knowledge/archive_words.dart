import 'package:preppsuite_flutter/features/knowledge/application/zim_archive.dart';

/// Words that are certainly in [archive], whatever language it is in.
///
/// The Xapian tests used to search for "Wasser". That said more about the
/// archive they happened to be written against than about the code: run
/// against an English one they failed, and the failure read like a broken
/// index rather than a wrong word. So the query comes out of the archive
/// now — a word from a real article title, checked against the index
/// before it is handed back.
///
/// Returns as many as [wanted], most promising first. Empty means the
/// index answered nothing about any of its own titles, which is a real
/// failure and belongs in the test that asked.
Future<List<String>> wordsInIndex(
  ZimArchive archive, {
  required Future<bool> Function(String word) matches,
  int wanted = 3,
  int scan = 400,
}) async {
  final found = <String>[];
  final seen = <String>{};

  for (var at = 0; at < scan && at < archive.header.entryCount; at++) {
    final entry = await archive.entryAt(at);
    if (entry.isRedirect) continue;
    // Article namespaces only: 'C' in current archives, 'A' in ones from
    // before the namespaces were merged.
    if (entry.namespace != 'C' && entry.namespace != 'A') continue;

    for (final word in _wordsOf(entry.title)) {
      if (!seen.add(word)) continue;
      if (!await matches(word)) continue;
      found.add(word);
      if (found.length >= wanted) return found;
    }
  }
  return found;
}

/// The parts of a title long enough to be worth searching for.
///
/// Short ones are stop words as often as not, and a stopper would drop
/// them from the query and leave it empty.
Iterable<String> _wordsOf(String title) sync* {
  final buffer = StringBuffer();
  for (final rune in title.runes) {
    final character = String.fromCharCode(rune);
    if (RegExp(r'[\p{L}]', unicode: true).hasMatch(character)) {
      buffer.write(character);
    } else {
      if (buffer.length >= 5) yield buffer.toString().toLowerCase();
      buffer.clear();
    }
  }
  if (buffer.length >= 5) yield buffer.toString().toLowerCase();
}
