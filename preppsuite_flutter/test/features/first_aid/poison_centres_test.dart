import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/first_aid/application/first_aid_guides.dart';
import 'package:preppsuite_flutter/features/first_aid/application/first_aid_guides_de.dart';
import 'package:preppsuite_flutter/features/first_aid/application/first_aid_guides_en.dart';
import 'package:preppsuite_flutter/features/first_aid/application/poison_centres.dart';

/// The poison-control numbers, which used to be written down twice.
///
/// The first-aid guide carried nine centres and the emergency screen
/// carried seven. The guide's extra two were Homburg/Saar, whose centre
/// closed around 2021, and Nürnberg, which the official register does not
/// name — so the page somebody opens while standing over a child held a
/// number nobody answers.
///
/// Two lists of the same emergency numbers are not redundancy. They are a
/// coin toss, and the one that loses is whichever page was opened.
void main() {
  test('a centre that closed is not offered', () {
    // Saarland has been answered by Mainz since Homburg shut.
    final cities = poisonCentres.map((c) => c.label);

    expect(cities, isNot(contains('Homburg/Saar')));
    expect(cities, contains('Mainz'));
  });

  test('only centres the official register names', () {
    expect(poisonCentres.map((c) => c.label), [
      'Berlin',
      'Bonn',
      'Erfurt',
      'Freiburg',
      'Göttingen',
      'Mainz',
      'München',
    ]);
  });

  test('both languages read the very same list', () {
    // Identity and not equality: a copy could be edited on one side.
    FirstAidGuide poisoning(List<FirstAidGuide> guides) =>
        guides.firstWhere((g) => g.id == 'poisoning');

    expect(
      identical(poisoning(firstAidGuidesDe).facts, poisonCentres),
      isTrue,
    );
    expect(
      identical(poisoning(firstAidGuidesEn).facts, poisonCentres),
      isTrue,
    );
  });

  test('every centre can be named by the region it answers for', () {
    for (final centre in poisonCentres) {
      expect(
        poisonCentreRegions,
        contains(centre.label),
        reason: '${centre.label} has no region',
      );
    }
    // And nothing is named that is not a centre any more.
    expect(poisonCentreRegions.length, poisonCentres.length);
  });

  test('the region listing carries the same numbers', () {
    expect(
      poisonCentresByRegion.map((c) => c.phone),
      poisonCentres.map((c) => c.value),
    );
    expect(poisonCentresByRegion.first.label, 'Berlin/Brandenburg');
    expect(poisonCentresByRegion.last.label, 'München (BY)');
  });

  test('every number is a dialable German number', () {
    // Not a format check for its own sake: a stray letter or a missing
    // leading zero is a number that fails exactly once, at the worst
    // possible moment.
    final german = RegExp(r'^0\d{2,4} \d{5,7}$');
    for (final centre in poisonCentres) {
      expect(german.hasMatch(centre.value), isTrue, reason: centre.value);
    }
  });

  test('the guide still says the numbers are only a stored snapshot', () {
    final poisoning = firstAidGuidesDe.firstWhere((g) => g.id == 'poisoning');

    expect(
      poisoning.cautions.any((c) => c.contains('gespeicherter Stand')),
      isTrue,
    );
  });
}
