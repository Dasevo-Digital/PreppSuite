import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/household/application/card_people.dart';

/// A number without a name was thrown away on saving, without a word
/// (#350).
void main() {
  test('a number with no name is kept, and reads back as it was', () {
    final stored = encodeCardPeople(const [
      CardPerson(role: 'Sohn', phone: '0171 1234567'),
      CardPerson(phone: '0151 7654321'),
    ]);

    expect(stored, isNotNull);
    expect(parseCardPeople(stored), const [
      CardPerson(role: 'Sohn', phone: '0171 1234567'),
      CardPerson(phone: '0151 7654321'),
    ]);
  });

  test('a row with nothing in it still goes', () {
    expect(encodeCardPeople(const [CardPerson()]), isNull);
    expect(
      parseCardPeople(
        encodeCardPeople(const [
          CardPerson(),
          CardPerson(name: 'Tom', phone: '0151 1'),
        ]),
      ),
      const [CardPerson(name: 'Tom', phone: '0151 1')],
    );
  });

  test('a name with brackets of its own keeps them', () {
    expect(
      parseCardPeople('Praxis (Dr. Weber) (Hausarzt) · 0531 1'),
      const [
        CardPerson(
          name: 'Praxis (Dr. Weber)',
          role: 'Hausarzt',
          phone: '0531 1',
        ),
      ],
    );
  });
}
