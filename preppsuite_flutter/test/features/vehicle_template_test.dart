import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/checklists/application/built_in_templates.dart';

/// The vehicle list, which is the only shipped template whose first
/// three lines come from a regulation rather than from a recommendation.
///
/// Two of them are places where the lists circulating online get it
/// wrong, so both are pinned here against the statute text:
///
/// § 53a Abs. 2 Nr. 3 StVZO requires **one** high-visibility vest in a
/// car, not one per occupant. One per seat is a good idea and is in the
/// list as a good idea.
///
/// § 35h Abs. 3 StVZO names DIN 13164 "Ausgabe Januar 1998 oder Ausgabe
/// Januar 2014". The 2022 edition with its two masks is therefore not
/// required, however often that is written otherwise.
void main() {
  final vehicle = builtInTemplates.firstWhere((t) => t.title == 'Fahrzeug');

  test('the three duties each name the paragraph they come from', () {
    final duties = vehicle.items
        .where((item) => item.title.startsWith('Pflicht:'))
        .toList();

    expect(duties, hasLength(3));
    for (final duty in duties) {
      expect(duty.title, contains('StVZO'), reason: duty.title);
    }
  });

  test('the law asks for one vest, and the list says so', () {
    final duty = vehicle.items.firstWhere(
      (item) =>
          item.title.contains('Warnweste') && item.title.startsWith('Pflicht:'),
    );
    expect(duty.title, contains('eine Warnweste'));
    expect(duty.title, contains('§ 53a'));

    // One per seat exists too — clearly on the other side of the line.
    final extra = vehicle.items.firstWhere(
      (item) => item.title.contains('je Sitzplatz'),
    );
    expect(extra.title, contains('Keine Pflicht'));
  });

  test('the first aid kit names the editions the statute names', () {
    final duty = vehicle.items.firstWhere(
      (item) =>
          item.title.contains('Verbandkasten') &&
          item.title.startsWith('Pflicht:'),
    );
    expect(duty.title, contains('DIN 13164'));
    expect(duty.title, contains('1998'));
    expect(duty.title, contains('2014'));
    // Not 2022: the statute does not name it, so neither does this list.
    expect(duty.title, isNot(contains('2022')));
  });

  test('everything that is not a duty does not pretend to be one', () {
    for (final item in vehicle.items) {
      if (item.title.startsWith('Pflicht:')) continue;
      expect(item.title, isNot(contains('§')), reason: item.title);
    }
  });
}
