/// International Morse code, both ways, and as a rhythm for a lamp (#180).
///
/// The table is Recommendation ITU-R M.1677-1 (10/2009), "International
/// Morse code": the 26 letters, the accented e, the ten figures, the
/// punctuation it lists and its procedure signals. Nothing in it is this
/// app's. The German letters Ä, Ö, Ü, ß and CH and the Spanish Ñ are not
/// in the Recommendation; they are the extensions in common use in those
/// languages, kept in a list of their own so that the screen can say so
/// rather than pass them off as the standard.
///
/// The timing is the Recommendation's too: a dash is three dots, the gap
/// inside a letter one dot, between letters three, between words seven.
/// How long a dot lasts it leaves open, and so does this file -- the
/// screen offers three speeds.
library;

import '../../home/application/distress_signal.dart';

/// How a dot and a dash are drawn on screen.
const morseDot = '•';
const morseDash = '—';

/// [code] in [morseDot] and [morseDash].
String drawMorse(String code) =>
    code.replaceAll('.', morseDot).replaceAll('-', morseDash);

/// The code for one character, in dots and dashes: `.` and `-`.
typedef MorseSymbol = ({String character, String code});

/// Letters, ITU-R M.1677-1 §1.1.1.
const morseLetters = <MorseSymbol>[
  (character: 'A', code: '.-'),
  (character: 'B', code: '-...'),
  (character: 'C', code: '-.-.'),
  (character: 'D', code: '-..'),
  (character: 'E', code: '.'),
  (character: 'É', code: '..-..'),
  (character: 'F', code: '..-.'),
  (character: 'G', code: '--.'),
  (character: 'H', code: '....'),
  (character: 'I', code: '..'),
  (character: 'J', code: '.---'),
  (character: 'K', code: '-.-'),
  (character: 'L', code: '.-..'),
  (character: 'M', code: '--'),
  (character: 'N', code: '-.'),
  (character: 'O', code: '---'),
  (character: 'P', code: '.--.'),
  (character: 'Q', code: '--.-'),
  (character: 'R', code: '.-.'),
  (character: 'S', code: '...'),
  (character: 'T', code: '-'),
  (character: 'U', code: '..-'),
  (character: 'V', code: '...-'),
  (character: 'W', code: '.--'),
  (character: 'X', code: '-..-'),
  (character: 'Y', code: '-.--'),
  (character: 'Z', code: '--..'),
];

/// Figures, §1.1.2.
const morseDigits = <MorseSymbol>[
  (character: '1', code: '.----'),
  (character: '2', code: '..---'),
  (character: '3', code: '...--'),
  (character: '4', code: '....-'),
  (character: '5', code: '.....'),
  (character: '6', code: '-....'),
  (character: '7', code: '--...'),
  (character: '8', code: '---..'),
  (character: '9', code: '----.'),
  (character: '0', code: '-----'),
];

/// Punctuation marks and miscellaneous signs, §1.1.3. The multiplication
/// sign is left out: it is the same signal as X, and a decoder could not
/// tell them apart.
const morsePunctuation = <MorseSymbol>[
  (character: '.', code: '.-.-.-'),
  (character: ',', code: '--..--'),
  (character: ':', code: '---...'),
  (character: '?', code: '..--..'),
  (character: "'", code: '.----.'),
  (character: '-', code: '-....-'),
  (character: '/', code: '-..-.'),
  (character: '(', code: '-.--.'),
  (character: ')', code: '-.--.-'),
  (character: '"', code: '.-..-.'),
  (character: '=', code: '-...-'),
  (character: '+', code: '.-.-.'),
  (character: '@', code: '.--.-.'),
];

/// Not in the Recommendation: the letters German and Spanish send in
/// their own way. CH is one signal for two letters, which is why text is
/// still sent as C and H and only a received `----` reads as CH.
const morseExtensions = <MorseSymbol>[
  (character: 'Ä', code: '.-.-'),
  (character: 'Ö', code: '---.'),
  (character: 'Ü', code: '..--'),
  (character: 'ß', code: '...--..'),
  (character: 'CH', code: '----'),
  (character: 'Ñ', code: '--.--'),
];

/// The procedure signals a reader is likely to meet, sent as one
/// character each. SOS is the distress signal of the Radio Regulations,
/// the rest are §1.1.3 and §3 of the Recommendation.
enum MorseProsign {
  sos('...---...'),
  error('........'),
  understood('...-.'),
  wait('.-...'),
  start('-.-.-'),
  endOfMessage('.-.-.'),
  endOfWork('...-.-');

  const MorseProsign(this.code);
  final String code;
}

final _encode = {
  for (final symbol in [
    ...morseLetters,
    ...morseDigits,
    ...morsePunctuation,
    ...morseExtensions,
  ])
    if (symbol.character.length == 1) symbol.character: symbol.code,
};

final _decode = {
  for (final symbol in [
    ...morseLetters,
    ...morseDigits,
    ...morsePunctuation,
    ...morseExtensions,
  ])
    symbol.code: symbol.character,
  // SOS is received as what it means. Error is eight dots, and longer
  // runs of dots are the same thing from a hand correcting itself.
  MorseProsign.sos.code: 'SOS',
  MorseProsign.error.code: '…',
};

/// Accented letters the table does not have, sent as their base letter.
/// É has its own signal and stays.
const _folded = {
  'À': 'A',
  'Á': 'A',
  'Â': 'A',
  'Ã': 'A',
  'Å': 'A',
  'È': 'E',
  'Ê': 'E',
  'Ë': 'E',
  'Ì': 'I',
  'Í': 'I',
  'Î': 'I',
  'Ï': 'I',
  'Ò': 'O',
  'Ó': 'O',
  'Ô': 'O',
  'Õ': 'O',
  'Ù': 'U',
  'Ú': 'U',
  'Û': 'U',
  'Ç': 'C',
  'Ý': 'Y',
  'ẞ': 'ß',
};

/// A message in Morse, with what could not be sent.
class MorseEncoding {
  const MorseEncoding({required this.words, required this.unknown});

  /// Each word as its letters' codes, in dots and dashes.
  final List<List<String>> words;

  /// Characters the table has no signal for, each once, in the order they
  /// first appeared. Said on the screen rather than dropped: a message
  /// that silently loses its digits is worse than one that says it can't.
  final List<String> unknown;

  bool get isEmpty => words.isEmpty;

  /// Letters split by a space, words by ` / `, in the given symbols.
  ///
  /// A bullet and an em dash by default: a middle dot is too small to
  /// count at a glance, and a dash should look longer than a dot.
  String format({String dot = morseDot, String dash = morseDash}) => [
    for (final word in words)
      [
        for (final code in word)
          code.replaceAll('.', dot).replaceAll('-', dash),
      ].join(' '),
  ].join(' / ');

  /// How many characters are sent.
  int get length => words.fold(0, (sum, word) => sum + word.length);
}

/// [text] in Morse.
MorseEncoding encodeMorse(String text) {
  final words = <List<String>>[];
  final unknown = <String>[];
  for (final word in text.trim().split(RegExp(r'\s+'))) {
    final codes = <String>[];
    for (final rune in word.runes) {
      // A combining accent typed after its letter: the letter is sent.
      if (rune >= 0x0300 && rune <= 0x036F) continue;
      final raw = String.fromCharCode(rune);
      // ß has no capital in common use; its signal is filed as written.
      final upper = raw == 'ß' ? raw : raw.toUpperCase();
      final character = _folded[upper] ?? upper;
      final code = _encode[character];
      if (code == null) {
        if (raw.trim().isNotEmpty && !unknown.contains(raw)) unknown.add(raw);
        continue;
      }
      codes.add(code);
    }
    if (codes.isNotEmpty) words.add(codes);
  }
  return MorseEncoding(words: words, unknown: unknown);
}

/// A received signal as text, with the codes nobody knows.
class MorseDecoding {
  const MorseDecoding({required this.text, required this.unknown});

  /// The text, with [unknownMark] wherever a code was not in the table.
  final String text;

  /// The codes that were not, each once, as dots and dashes.
  final List<String> unknown;

  static const unknownMark = '□';
}

final _dots = RegExp(r'[.·•∙⋅*]');
final _dashes = RegExp(r'[-−–—_]');

/// [signal] as text.
///
/// Forgiving about how it was written, because it is typed by hand from
/// something heard or seen: `.` `·` `•` and `*` are dots, `-` `−` `–` `—`
/// and `_` dashes. Letters are separated by a space, words by `/`, `|`,
/// a line break or two spaces or more.
MorseDecoding decodeMorse(String signal) {
  final words = <String>[];
  final unknown = <String>[];
  final normalised = signal
      .replaceAll(_dots, '.')
      .replaceAll(_dashes, '-')
      .trim();
  if (normalised.isEmpty) return const MorseDecoding(text: '', unknown: []);
  for (final word in normalised.split(RegExp(r'\s*[/|\n]\s*|\s{2,}'))) {
    final letters = StringBuffer();
    for (final code in word.trim().split(RegExp(r'\s+'))) {
      if (code.isEmpty) continue;
      final known =
          _decode[code] ?? (RegExp(r'^\.{8,}$').hasMatch(code) ? '…' : null);
      if (known == null) {
        letters.write(MorseDecoding.unknownMark);
        if (!unknown.contains(code)) unknown.add(code);
      } else {
        letters.write(known);
      }
    }
    if (letters.isNotEmpty) words.add(letters.toString());
  }
  return MorseDecoding(text: words.join(' '), unknown: unknown);
}

/// A message as light and dark, for the lamp.
///
/// Repeats with a pause of twice a word gap at the end, so whoever reads
/// it can tell where it starts again.
class MorseRhythm extends SignalRhythm {
  MorseRhythm._(super.spans, this._letterAt, this.characters);

  factory MorseRhythm(MorseEncoding message, {required Duration unit}) {
    assert(unit > Duration.zero);
    final spans = <SignalSpan>[];
    final letterAt = <int>[];
    var letter = 0;
    for (var w = 0; w < message.words.length; w++) {
      final word = message.words[w];
      for (var l = 0; l < word.length; l++) {
        final code = word[l];
        for (var e = 0; e < code.length; e++) {
          spans.add((lit: true, length: unit * (code[e] == '-' ? 3 : 1)));
          letterAt.add(letter);
          final lastElement = e == code.length - 1;
          final lastLetter = l == word.length - 1;
          final lastWord = w == message.words.length - 1;
          final gap = !lastElement
              ? 1
              : !lastLetter
              ? 3
              : !lastWord
              ? 7
              : 14;
          spans.add((lit: false, length: unit * gap));
          letterAt.add(lastElement ? -1 : letter);
        }
        letter++;
      }
    }
    return MorseRhythm._(spans, letterAt, message.length);
  }

  final List<int> _letterAt;

  /// How many characters one turn sends.
  final int characters;

  /// Which character of the message is being sent at [elapsed], counted
  /// from zero, or null in a gap between letters.
  int? characterAt(Duration elapsed) {
    final total = period.inMicroseconds;
    if (total == 0) return null;
    var into = elapsed.inMicroseconds % total;
    if (into < 0) into += total;
    var boundary = 0;
    for (var i = 0; i < spans.length; i++) {
      boundary += spans[i].length.inMicroseconds;
      if (into < boundary) return _letterAt[i] < 0 ? null : _letterAt[i];
    }
    return null;
  }
}

/// The three speeds offered, as the length of a dot.
///
/// Slow is the distress signal's half second, for an eye across a valley.
/// Fast is about ten words a minute by the PARIS standard (fifty units a
/// word), which a practised reader can still follow by eye.
enum MorseSpeed {
  slow(Duration(milliseconds: 500)),
  medium(Duration(milliseconds: 250)),
  fast(Duration(milliseconds: 120));

  const MorseSpeed(this.unit);
  final Duration unit;
}
