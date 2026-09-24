import 'package:flutter_test/flutter_test.dart';

import 'package:preppsuite_flutter/features/checklists/application/built_in_templates.dart';
import 'package:preppsuite_flutter/features/checklists/application/hazard_response_lists.dart';

void main() {
  const flood = '00000000-0000-4000-8000-000000000020';
  const storm = '00000000-0000-4000-8000-000000000021';
  const heat = '00000000-0000-4000-8000-000000000012';

  test('every list this points at actually exists', () {
    // A wrong id here is a button that opens nothing, and it would only
    // show itself on the day a warning arrives.
    for (final id in [flood, storm, heat]) {
      expect(
        builtInTemplates.any((t) => t.clientId == id),
        isTrue,
        reason: '$id ist keine mitgelieferte Liste',
      );
    }
  });

  test('the wording the services actually use', () {
    // The DWD says all of these for one family of weather.
    for (final event in [
      'Sturmböen',
      'Schwere Sturmböen',
      'Orkanartige Böen',
      'Orkanböen',
      'Gewitter mit Starkregen und Hagel',
      'Schweres Gewitter',
    ]) {
      expect(responseListFor(event), isNotNull, reason: event);
    }

    expect(responseListFor('Hochwasser'), flood);
    expect(responseListFor('Überschwemmung'), flood);
    expect(responseListFor('Ergiebiger Dauerregen'), flood);
    expect(responseListFor('Hitzewarnung'), heat);
    expect(responseListFor('Extreme Hitze'), heat);
    // Begins with "Sturm" and is still a flood: what comes in is water.
    expect(responseListFor('Sturmflut'), flood);
  });

  test('umlauts survive the folding', () {
    // The keywords are stored folded. Spelled the German way they would
    // match nothing, and nothing is exactly what a missing suggestion
    // looks like.
    expect(responseListFor('Böen'), storm);
    expect(responseListFor('Dürre'), heat);
    expect(responseListFor('ÜBERSCHWEMMUNG'), flood);
  });

  test('says nothing rather than something that does not fit', () {
    // An offer that does not fit is worse than none on a screen somebody
    // is reading in a hurry.
    for (final event in [
      'Glatteis',
      'Frost',
      'Nebel',
      'Stromausfall',
      'Gefahrstoffaustritt',
      '',
    ]) {
      expect(responseListFor(event), isNull, reason: event);
    }
  });
}
