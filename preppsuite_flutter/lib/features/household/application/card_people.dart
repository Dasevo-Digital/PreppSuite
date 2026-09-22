/// The people named on somebody's emergency card: their doctors, and
/// whoever is to be rung about them.
///
/// Both used to be one free-text line each, which was enough for a
/// household with one GP and one partner and wrong for everybody else.
/// A person under three specialists could write all three into one line,
/// and whoever read it in a hurry had to take the line apart themselves.
///
/// **Why lines of text and not a table of their own.** The card is the
/// unit that syncs, that is tombstoned, and that gets printed; a doctor
/// is part of a card and never outlives one. A second table would mean a
/// second set of rows to merge, to delete alongside the card, and to
/// carry through the folder, the handover and the QR chain — machinery
/// for something that has no independent life.
///
/// **Why this shape of line.** One entry per line, written the way it
/// would be said:
///
///     Dr. Mira Sandoval (Hausärztin) · 0531 123456
///     Anna Weber (Partnerin) · 0170 9876543
///
/// It stays readable where nothing parses it. A device still on an older
/// version shows the raw column and shows exactly that — which is the
/// whole reason the column keeps its type and its name, and why no
/// migration is needed: a line that was already there, "Dr. Müller,
/// Praxis am Markt", reads back as one entry with a name and nothing
/// else, and writes back out unchanged.
library;

/// One doctor, or one person to call.
///
/// The same three fields serve both, because they are the same three
/// questions: who, in what capacity, on what number. Only the labels
/// differ — "Fachrichtung" over a doctor, "Verhältnis" over a contact —
/// and labels belong to the screen, not here.
class CardPerson {
  const CardPerson({this.name = '', this.role = '', this.phone = ''});

  /// "Dr. Mira Sandoval", "Anna Weber".
  final String name;

  /// "Hausärztin", "Partnerin". Optional: a number that gets answered is
  /// worth more than a blank that was refused for being incomplete.
  final String role;

  final String phone;

  /// Nothing typed at all — a row the form offered and nobody filled.
  bool get isBlank =>
      name.trim().isEmpty && role.trim().isEmpty && phone.trim().isEmpty;

  CardPerson copyWith({String? name, String? role, String? phone}) =>
      CardPerson(
        name: name ?? this.name,
        role: role ?? this.role,
        phone: phone ?? this.phone,
      );

  /// The entry as one line, which is both how it is stored and how it
  /// reads on screen and on paper.
  String get line {
    final buffer = StringBuffer(name.trim());
    if (role.trim().isNotEmpty) buffer.write(' (${role.trim()})');
    if (phone.trim().isNotEmpty) buffer.write(' $_separator ${phone.trim()}');
    return buffer.toString();
  }

  @override
  bool operator ==(Object other) =>
      other is CardPerson &&
      other.name == name &&
      other.role == role &&
      other.phone == phone;

  @override
  int get hashCode => Object.hash(name, role, phone);

  @override
  String toString() => line;
}

/// Between the person and their number. A middle dot rather than a comma
/// or a slash, both of which turn up inside real names and real numbers.
const _separator = '·';

/// The entries stored in one column.
///
/// Anything that does not look like an entry is still an entry: a line
/// with no brackets and no dot is a name, which is what every card
/// written before this existed holds.
List<CardPerson> parseCardPeople(String? stored) {
  if (stored == null) return const [];

  final people = <CardPerson>[];
  for (final line in stored.split('\n')) {
    final person = _parseLine(line);
    if (person != null) people.add(person);
  }
  return people;
}

CardPerson? _parseLine(String line) {
  final trimmed = line.trim();
  if (trimmed.isEmpty) return null;

  var head = trimmed;
  var phone = '';
  final separator = trimmed.indexOf(_separator);
  if (separator >= 0) {
    head = trimmed.substring(0, separator).trim();
    phone = trimmed.substring(separator + _separator.length).trim();
  }

  var name = head;
  var role = '';
  // The last pair, so a name that itself carries brackets keeps them.
  if (head.endsWith(')')) {
    final open = head.lastIndexOf('(');
    if (open > 0) {
      role = head.substring(open + 1, head.length - 1).trim();
      name = head.substring(0, open).trim();
    }
  }

  return CardPerson(name: name, role: role, phone: phone);
}

/// What goes back into the column, or null where nothing was typed.
///
/// An entry with no name is dropped rather than stored: the form offers a
/// blank row as soon as somebody taps "add", and a row left untouched
/// must not become a nameless number on a card a paramedic reads.
String? encodeCardPeople(Iterable<CardPerson> people) {
  final lines = [
    for (final person in people)
      if (person.name.trim().isNotEmpty) person.line,
  ];
  return lines.isEmpty ? null : lines.join('\n');
}
