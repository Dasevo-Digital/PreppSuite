import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/search/application/app_search.dart';

/// Finding things by name, and the order the answers come in.
void main() {
  const candidates = [
    SearchCandidate(key: 'a', label: 'Notgepäck', context: 'Checklisten'),
    SearchCandidate(key: 'b', label: 'Strom- und Heizungsausfall'),
    SearchCandidate(key: 'c', label: 'Wenn der Strom ausfällt'),
    SearchCandidate(
      key: 'd',
      label: 'Pegelstände',
      aliases: ['hochwasser', 'fluss'],
    ),
    SearchCandidate(key: 'e', label: 'Reis', context: 'Keller'),
    SearchCandidate(key: 'f', label: 'Rote Bete', context: 'Keller'),
  ];

  List<String> keysFor(String query) => [
    for (final match in searchCandidates(query, candidates))
      match.candidate.key,
  ];

  group('folding the way German is typed', () {
    test('a missing umlaut still finds the word', () {
      // On a keyboard without them, and in a hurry, this happens.
      expect(keysFor('notgepack'), ['a']);
    });

    test('and typing the umlaut finds a word written without one', () {
      expect(foldForSearch('Notgepäck'), foldForSearch('Notgepack'));
      expect(foldForSearch('Straße'), 'strasse');
    });

    test('a combining accent folds like the single character', () {
      // What a Mac produces for option-u then a. A different string
      // entirely, and it would otherwise never match.
      expect(foldForSearch('ä'), foldForSearch('ä'));
    });
  });

  group('the order answers come in', () {
    test('the name beating a word inside it beating an alias', () {
      final matches = searchCandidates('strom', candidates);

      expect(matches.first.candidate.key, 'b');
      expect(matches.first.rank, SearchRank.nameStart);
      expect(matches[1].candidate.key, 'c');
      expect(matches[1].rank, SearchRank.wordStart);
    });

    test('a word nobody sees still finds it, but comes last', () {
      final matches = searchCandidates('hochwasser', candidates);

      expect(matches.single.candidate.key, 'd');
      expect(matches.single.rank, SearchRank.elsewhere);
    });

    test('where a thing lives is searchable too', () {
      // "Keller" should find what is in the cellar.
      expect(keysFor('keller'), ['e', 'f']);
    });

    test('a hyphenated title breaks into words', () {
      expect(keysFor('heizungsausfall'), ['b']);
    });

    test('two equally good answers sort by name, and stay put', () {
      // Both match only through where they are kept, so neither is the
      // better answer. Two that swapped places as somebody typed would
      // be two they tap the wrong one of.
      expect(keysFor('keller'), ['e', 'f']);
      expect(keysFor('kell'), keysFor('keller'));
    });
  });

  group('what it refuses to answer', () {
    test('nothing typed finds nothing, not everything', () {
      // A list of every screen and every tin in the house is not an
      // answer, and the screen has something better to show.
      expect(searchCandidates('', candidates), isEmpty);
      expect(searchCandidates('   ', candidates), isEmpty);
    });

    test('something nobody has is simply absent', () {
      expect(searchCandidates('quinoa', candidates), isEmpty);
    });

    test('the list is capped, so one letter cannot flood the screen', () {
      final many = [
        for (var i = 0; i < 200; i++)
          SearchCandidate(key: '$i', label: 'Sache $i'),
      ];

      expect(searchCandidates('sache', many, limit: 20), hasLength(20));
    });
  });
}
