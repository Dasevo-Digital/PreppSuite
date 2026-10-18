/// The Snowball French stemmer, in Dart (#194).
///
/// A transcription of `french.sbl` as Snowball 2 has it, checked against
/// Snowball's own expected output for its test vocabulary, 20 805 words:
/// see `french_stemmer_test.dart` and `tool/snowball_stems.sh`.
///
/// Expects one lowercased word.
library;

/// The stem of [word], which must already be lowercase.
String frenchStem(String word) {
  var s = _prelude(word);
  final (pV, p1, p2) = _markRegions(s);

  final step = _Step(s, pV, p1, p2);
  final removed =
      step.standardSuffix() || step.iVerbSuffix() || step.verbSuffix();
  if (removed) {
    // A 'Y' or 'ç' the removal left at the end goes back to 'i' or 'c'.
    if (step.s.endsWith('Y')) {
      step.s = '${step.s.substring(0, step.s.length - 1)}i';
    } else if (step.s.endsWith('ç')) {
      step.s = '${step.s.substring(0, step.s.length - 1)}c';
    }
  } else {
    step.residualSuffix();
  }
  s = _unAccent(_unDouble(step.s));
  return _postlude(s);
}

const _vowels = 'aeiouyâàëéêèïîôûù';

bool _isVowel(String character) => _vowels.contains(character);

/// Marks the letters that are not doing a vowel's work -- 'u' and 'i'
/// between vowels, 'y' next to one, 'u' after 'q' -- by writing them in
/// capitals, and spells 'ë' and 'ï' as 'He' and 'Hi' so that a suffix
/// beginning with the bare vowel is still recognised.
String _prelude(String word) {
  final c = word.split('');
  // Snowball's `goto` leaves the cursor where the match began, not after
  // it, so the search goes on from there: in "jouaient" the 'a' after the
  // marked 'U' is looked at again, and the 'i' after it is marked too.
  // Every match changes a letter, so the same place never matches twice.
  var at = 0;
  while (true) {
    var advanced = false;
    for (var p = at; p < c.length; p++) {
      final next = p + 1 < c.length ? c[p + 1] : null;
      final after = p + 2 < c.length ? c[p + 2] : null;
      if (_isVowel(c[p]) && next != null) {
        if (next == 'u' && after != null && _isVowel(after)) {
          c[p + 1] = 'U';
          at = p;
          advanced = true;
          break;
        }
        if (next == 'i' && after != null && _isVowel(after)) {
          c[p + 1] = 'I';
          at = p;
          advanced = true;
          break;
        }
        if (next == 'y') {
          c[p + 1] = 'Y';
          at = p;
          advanced = true;
          break;
        }
      }
      if (c[p] == 'ë') {
        c.replaceRange(p, p + 1, const ['H', 'e']);
        at = p;
        advanced = true;
        break;
      }
      if (c[p] == 'ï') {
        c.replaceRange(p, p + 1, const ['H', 'i']);
        at = p;
        advanced = true;
        break;
      }
      if (c[p] == 'y' && next != null && _isVowel(next)) {
        c[p] = 'Y';
        at = p;
        advanced = true;
        break;
      }
      if (c[p] == 'q' && next == 'u') {
        c[p + 1] = 'U';
        at = p;
        advanced = true;
        break;
      }
    }
    if (!advanced) break;
  }
  return c.join();
}

/// RV, R1 and R2. RV begins after the third letter when the word opens
/// with two vowels or with "par", "col" or "tap", and otherwise after the
/// first vowel that is not the first letter.
(int, int, int) _markRegions(String word) {
  final n = word.length;
  var pV = n;
  if (n >= 3 && _isVowel(word[0]) && _isVowel(word[1])) {
    pV = 3;
  } else if (word.startsWith('par') ||
      word.startsWith('col') ||
      word.startsWith('tap')) {
    pV = 3;
  } else {
    for (var i = 1; i < n; i++) {
      if (_isVowel(word[i])) {
        pV = i + 1;
        break;
      }
    }
  }

  final p1 = _pastVowelConsonant(word, 0);
  if (p1 == null) return (pV, n, n);
  return (pV, p1, _pastVowelConsonant(word, p1) ?? n);
}

int? _pastVowelConsonant(String word, int from) {
  var at = from;
  while (at < word.length && !_isVowel(word[at])) {
    at++;
  }
  if (at >= word.length) return null;
  at++;
  while (at < word.length && _isVowel(word[at])) {
    at++;
  }
  if (at >= word.length) return null;
  return at + 1;
}

String? _longest(String word, Iterable<String> candidates, {int from = 0}) {
  String? best;
  for (final candidate in candidates) {
    if (word.length - candidate.length < from) continue;
    if (word.endsWith(candidate) &&
        (best == null || candidate.length > best.length)) {
      best = candidate;
    }
  }
  return best;
}

/// The suffix steps, which change the word as they go: Snowball never
/// takes back a change, even in a step that goes on to fail.
class _Step {
  _Step(this.s, this.pV, this.p1, this.p2);

  String s;
  final int pV;
  final int p1;
  final int p2;

  int _startOf(String suffix) => s.length - suffix.length;
  void _drop(String suffix) => s = s.substring(0, s.length - suffix.length);
  void _replace(String suffix, String by) {
    _drop(suffix);
    s = '$s$by';
  }

  bool _r2(String suffix) => _startOf(suffix) >= p2;
  bool _r1(String suffix) => _startOf(suffix) >= p1;
  bool _rv(String suffix) => _startOf(suffix) >= pV;

  /// Drops [tail] when the word ends in it inside R2. Whether it did.
  bool _dropInR2(String tail) {
    if (!s.endsWith(tail) || !_r2(tail)) return false;
    _drop(tail);
    return true;
  }

  /// 'ic' goes inside R2 and turns into 'iqU' outside it.
  void _icOrIqu() {
    if (!s.endsWith('ic')) return;
    if (!_dropInR2('ic')) _replace('ic', 'iqU');
  }

  /// [suffix] -> 'eux' unless it can simply go: R2 drops it, R1 rewrites
  /// it.
  bool _dropOrEux(String suffix) {
    if (_r2(suffix)) {
      _drop(suffix);
      return true;
    }
    if (_r1(suffix)) {
      _replace(suffix, 'eux');
      return true;
    }
    return false;
  }

  bool standardSuffix() {
    final suffix = _longest(s, const [
      'ance',
      'iqUe',
      'isme',
      'able',
      'iste',
      'eux',
      'ances',
      'iqUes',
      'ismes',
      'ables',
      'istes',
      'atrice',
      'ateur',
      'ation',
      'atrices',
      'ateurs',
      'ations',
      'logie',
      'logies',
      'usion',
      'ution',
      'usions',
      'utions',
      'ence',
      'ences',
      'ement',
      'ements',
      'ité',
      'ités',
      'if',
      'ive',
      'ifs',
      'ives',
      'eaux',
      'aux',
      'euse',
      'euses',
      'issement',
      'issements',
      'amment',
      'emment',
      'ment',
      'ments',
    ]);
    if (suffix == null) return false;

    switch (suffix) {
      case 'ance' ||
          'iqUe' ||
          'isme' ||
          'able' ||
          'iste' ||
          'eux' ||
          'ances' ||
          'iqUes' ||
          'ismes' ||
          'ables' ||
          'istes':
        if (!_r2(suffix)) return false;
        _drop(suffix);
        return true;
      case 'atrice' || 'ateur' || 'ation' || 'atrices' || 'ateurs' || 'ations':
        if (!_r2(suffix)) return false;
        _drop(suffix);
        _icOrIqu();
        return true;
      case 'logie' || 'logies':
        if (!_r2(suffix)) return false;
        _replace(suffix, 'log');
        return true;
      case 'usion' || 'ution' || 'usions' || 'utions':
        if (!_r2(suffix)) return false;
        _replace(suffix, 'u');
        return true;
      case 'ence' || 'ences':
        if (!_r2(suffix)) return false;
        _replace(suffix, 'ent');
        return true;
      case 'ement' || 'ements':
        if (!_rv(suffix)) return false;
        _drop(suffix);
        final next = _longest(s, const [
          'iv',
          'eus',
          'abl',
          'iqU',
          'ièr',
          'Ièr',
        ]);
        switch (next) {
          case 'iv':
            if (_dropInR2('iv')) _dropInR2('at');
          case 'eus':
            _dropOrEux('eus');
          case 'abl' || 'iqU':
            _dropInR2(next!);
          case 'ièr' || 'Ièr':
            if (_rv(next!)) _replace(next, 'i');
        }
        return true;
      case 'ité' || 'ités':
        if (!_r2(suffix)) return false;
        _drop(suffix);
        final next = _longest(s, const ['abil', 'ic', 'iv']);
        switch (next) {
          case 'abil':
            if (!_dropInR2('abil')) _replace('abil', 'abl');
          case 'ic':
            if (!_dropInR2('ic')) _replace('ic', 'iqU');
          case 'iv':
            _dropInR2('iv');
        }
        return true;
      case 'if' || 'ive' || 'ifs' || 'ives':
        if (!_r2(suffix)) return false;
        _drop(suffix);
        if (_dropInR2('at')) _icOrIqu();
        return true;
      case 'eaux':
        _replace(suffix, 'eau');
        return true;
      case 'aux':
        if (!_r1(suffix)) return false;
        _replace(suffix, 'al');
        return true;
      case 'euse' || 'euses':
        return _dropOrEux(suffix);
      case 'issement' || 'issements':
        final start = _startOf(suffix);
        if (!_r1(suffix) || start < 1 || _isVowel(s[start - 1])) return false;
        _drop(suffix);
        return true;
      // The three below change the word and then report failure, so that
      // the verb endings are still looked at: "-ment" usually follows a
      // participle, as in "confusément".
      case 'amment':
        if (_rv(suffix)) _replace(suffix, 'ant');
        return false;
      case 'emment':
        if (_rv(suffix)) _replace(suffix, 'ent');
        return false;
      case 'ment' || 'ments':
        final start = _startOf(suffix);
        if (start >= 1 && _isVowel(s[start - 1]) && start - 1 >= pV) {
          _drop(suffix);
        }
        return false;
    }
    return false;
  }

  bool iVerbSuffix() {
    final suffix = _longest(s, const [
      'îmes',
      'ît',
      'îtes',
      'i',
      'ie',
      'ies',
      'ir',
      'ira',
      'irai',
      'iraIent',
      'irais',
      'irait',
      'iras',
      'irent',
      'irez',
      'iriez',
      'irions',
      'irons',
      'iront',
      'is',
      'issaIent',
      'issais',
      'issait',
      'issant',
      'issante',
      'issantes',
      'issants',
      'isse',
      'issent',
      'isses',
      'issez',
      'issiez',
      'issions',
      'issons',
      'it',
    ], from: pV);
    if (suffix == null) return false;
    final before = _startOf(suffix) - 1;
    if (before < pV || s[before] == 'H' || _isVowel(s[before])) return false;
    _drop(suffix);
    return true;
  }

  bool verbSuffix() {
    final suffix = _longest(s, const [
      'ions',
      'é',
      'ée',
      'ées',
      'és',
      'èrent',
      'er',
      'era',
      'erai',
      'eraIent',
      'erais',
      'erait',
      'eras',
      'erez',
      'eriez',
      'erions',
      'erons',
      'eront',
      'ez',
      'iez',
      'âmes',
      'ât',
      'âtes',
      'a',
      'ai',
      'aIent',
      'ais',
      'ait',
      'ant',
      'ante',
      'antes',
      'ants',
      'as',
      'asse',
      'assent',
      'asses',
      'assiez',
      'assions',
    ], from: pV);
    if (suffix == null) return false;
    if (suffix == 'ions') {
      if (!_r2(suffix)) return false;
      _drop(suffix);
      return true;
    }
    const withE = {
      'âmes',
      'ât',
      'âtes',
      'a',
      'ai',
      'aIent',
      'ais',
      'ait',
      'ant',
      'ante',
      'antes',
      'ants',
      'as',
      'asse',
      'assent',
      'asses',
      'assiez',
      'assions',
    };
    _drop(suffix);
    if (withE.contains(suffix) && s.endsWith('e') && s.length - 1 >= pV) {
      _drop('e');
    }
    return true;
  }

  void residualSuffix() {
    if (s.endsWith('s')) {
      final n = s.length;
      final afterHi = n >= 3 && s[n - 3] == 'H' && s[n - 2] == 'i';
      final keep = n >= 2 && 'aiouIsè'.contains(s[n - 2]);
      if (n >= 2 && (afterHi || !keep)) _drop('s');
    }
    final suffix = _longest(s, const [
      'ion',
      'ier',
      'ière',
      'Ier',
      'Ière',
      'e',
    ], from: pV);
    switch (suffix) {
      case 'ion':
        final before = _startOf('ion') - 1;
        if (_r2('ion') && before >= pV && 'st'.contains(s[before])) {
          _drop('ion');
        }
      case 'ier' || 'ière' || 'Ier' || 'Ière':
        _replace(suffix!, 'i');
      case 'e':
        _drop('e');
    }
  }
}

/// A doubled consonant left at the end of 'enn', 'onn', 'ett', 'ell' or
/// 'eill' loses one of its letters.
String _unDouble(String word) {
  for (final ending in const ['enn', 'onn', 'ett', 'ell', 'eill']) {
    if (word.endsWith(ending)) return word.substring(0, word.length - 1);
  }
  return word;
}

/// An 'é' or 'è' before the final consonants becomes 'e'.
String _unAccent(String word) {
  var i = word.length - 1;
  while (i >= 0 && !_isVowel(word[i])) {
    i--;
  }
  if (i < 0 || i == word.length - 1) return word;
  if (word[i] == 'é' || word[i] == 'è') {
    return '${word.substring(0, i)}e${word.substring(i + 1)}';
  }
  return word;
}

/// Writes the marked letters back.
String _postlude(String word) {
  final out = StringBuffer();
  var i = 0;
  while (i < word.length) {
    final c = word[i];
    if (c == 'H') {
      final next = i + 1 < word.length ? word[i + 1] : null;
      if (next == 'e') {
        out.write('ë');
        i += 2;
        continue;
      }
      if (next == 'i') {
        out.write('ï');
        i += 2;
        continue;
      }
      i += 1;
      continue;
    }
    out.write(switch (c) {
      'I' => 'i',
      'U' => 'u',
      'Y' => 'y',
      _ => c,
    });
    i += 1;
  }
  return out.toString();
}
