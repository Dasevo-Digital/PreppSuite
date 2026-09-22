import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/household/application/card_people.dart';

/// The doctors and the people to ring, stored in the column they were
/// always stored in.
void main() {
  group('what was already on the cards', () {
    test('a line written before any of this reads back as a name', () {
      // The case that decides whether a migration is needed. It is not.
      expect(
        parseCardPeople('Dr. Müller, Praxis am Markt'),
        [const CardPerson(name: 'Dr. Müller, Praxis am Markt')],
      );
    });

    test('and writes back out byte for byte', () {
      const stored = 'Dr. Müller, Praxis am Markt';
      expect(encodeCardPeople(parseCardPeople(stored)), stored);
    });

    test('an empty column is no people, not one empty person', () {
      expect(parseCardPeople(null), isEmpty);
      expect(parseCardPeople(''), isEmpty);
      expect(parseCardPeople('\n  \n'), isEmpty);
    });
  });

  group('reading an entry', () {
    test('name, role and number', () {
      expect(
        parseCardPeople('Dr. Mira Sandoval (Hausärztin) · 0531 123456'),
        [
          const CardPerson(
            name: 'Dr. Mira Sandoval',
            role: 'Hausärztin',
            phone: '0531 123456',
          ),
        ],
      );
    });

    test('a number without a role', () {
      expect(parseCardPeople('Anna Weber · 0170 987'), [
        const CardPerson(name: 'Anna Weber', phone: '0170 987'),
      ]);
    });

    test('a role without a number', () {
      expect(parseCardPeople('Anna Weber (Partnerin)'), [
        const CardPerson(name: 'Anna Weber', role: 'Partnerin'),
      ]);
    });

    test('several, one per line', () {
      final people = parseCardPeople(
        'Dr. Sandoval (Hausärztin) · 0531 1\n'
        'Dr. Weller (Kardiologe) · 0531 2\n'
        'Zahnarztpraxis Nord · 0531 3',
      );

      expect(people.map((p) => p.name), [
        'Dr. Sandoval',
        'Dr. Weller',
        'Zahnarztpraxis Nord',
      ]);
      expect(people.last.role, isEmpty);
    });

    test('brackets inside a name survive, because the last pair wins', () {
      expect(
        parseCardPeople('Praxis Meyer (MVZ) (Hausärztin) · 0531 4').single,
        const CardPerson(
          name: 'Praxis Meyer (MVZ)',
          role: 'Hausärztin',
          phone: '0531 4',
        ),
      );
    });
  });

  group('writing entries', () {
    test('nothing typed is nothing stored', () {
      expect(encodeCardPeople(const []), isNull);
      expect(encodeCardPeople(const [CardPerson()]), isNull);
    });

    test('a row with a number but no name is dropped', () {
      // The form offers a blank row on "add". One left with only a stray
      // digit must not become a nameless number on a card.
      expect(encodeCardPeople(const [CardPerson(phone: '0531')]), isNull);
    });

    test('surrounding space is not stored', () {
      expect(
        encodeCardPeople(const [
          CardPerson(name: '  Anna Weber ', role: ' Partnerin ', phone: ' 07 '),
        ]),
        'Anna Weber (Partnerin) · 07',
      );
    });

    test('a full list survives being read back', () {
      const people = [
        CardPerson(name: 'Dr. Sandoval', role: 'Hausärztin', phone: '0531 1'),
        CardPerson(name: 'Dr. Weller', phone: '0531 2'),
        CardPerson(name: 'Zahnarztpraxis Nord', role: 'Zahnmedizin'),
        CardPerson(name: 'Nur ein Name'),
      ];

      expect(parseCardPeople(encodeCardPeople(people)), people);
    });
  });

  test('the stored line is what a screen and a printout show', () {
    // One rendering, not three: the card, the PDF and an older version
    // of the app all show the same sentence because there is only one.
    expect(
      const CardPerson(
        name: 'Anna Weber',
        role: 'Partnerin',
        phone: '0170 987',
      ).line,
      'Anna Weber (Partnerin) · 0170 987',
    );
  });
}
