import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/warnings/application/dwd_areas.dart';

/// Placing a warning whose id says nothing about where it applies, and
/// naming a district key back to the person who typed it.
///
/// The case that forced both: KATWARN ids carry no state, so an
/// earthquake near Worms was placed nowhere — which the relevance rule
/// reads as everywhere — and it reached a household in Braunschweig.
void main() {
  // Enough of the real table to exercise every branch: two districts in
  // one state, one in another, a district whose own name has no "Kreis"
  // in front of it, a Gemeinde-level row sharing a district with its
  // Kreis, and a row with no district at all.
  final areas = DwdAreas.parse('''
# name;district;state
Kreis Alzey-Worms;07331;RP
Kreis Bad Dürkheim;07332;RP
Rhein-Pfalz-Kreis;07338;RP
Stadt Worms;07319;RP
Stadt Braunschweig;03101;NI
Kreis Göttingen;03159;NI
Kreis Kassel;06633;HE
Stadt Dülmen;05558;NW
Westerwaldkreis;07143;RP
Gemeinde Aying;09184;BY
Kreis München;09184;BY
Stadt Garching b. München;09184;BY
Stadt München;09162;BY
Insel Borkum;;NI
''');

  group('reducing a name to its place', () {
    test('the two feeds spell the same district differently', () {
      // This is the whole reason the reduction exists.
      expect(DwdAreas.areaNameCore('Kreis Alzey-Worms'), 'alzey-worms');
      expect(DwdAreas.areaNameCore('LKr. Alzey-Worms'), 'alzey-worms');
      expect(DwdAreas.areaNameCore('Landkreis Alzey-Worms'), 'alzey-worms');
      expect(
        DwdAreas.areaNameCore('Teile von LKr. Alzey-Worms'),
        'alzey-worms',
      );
    });

    test('a name that carries "kreis" inside it keeps it', () {
      // Stripping it would make Westerwaldkreis look like "wald" and
      // Rhein-Pfalz-Kreis like "rhein-pfalz" — two districts turned into
      // places that are not them.
      expect(DwdAreas.areaNameCore('Westerwaldkreis'), 'westerwaldkreis');
      expect(DwdAreas.areaNameCore('Rhein-Pfalz-Kreis'), 'rhein-pfalz-kreis');
    });

    test('a prefix on its own leaves nothing rather than itself', () {
      expect(DwdAreas.areaNameCore('Stadt'), '');
      expect(DwdAreas.areaNameCore('  '), '');
    });
  });

  group('placing a free-text area description', () {
    test('the earthquake near Worms is placed in Rheinland-Pfalz', () {
      // Verbatim from the live feed on 2026-09-10, warning
      // kat.6aa2cd02995efd5eae120ffb_public_topics.
      expect(
        areas.stateForAreaNames(
          'Teile von LKr. Alzey-Worms, LKr. Bad Dürkheim, '
          'Rhein-Pfalz-Kreis und Umland',
        ),
        'RP',
      );
    });

    test('a single town is placed in its state', () {
      expect(areas.stateForAreaNames('Stadt Dülmen'), 'NW');
      expect(areas.stateForAreaNames('Stadt Braunschweig'), 'NI');
    });

    test('districts spanning two states leave it unplaced', () {
      // Unanimous or nothing. Narrowing here would hide the warning from
      // one of the two states it is actually about, and for a
      // civil-protection alert too many people is the safe error.
      expect(
        areas.stateForAreaNames('Kreis Kassel und Kreis Göttingen'),
        isNull,
      );
    });

    test('text naming no known place stays unplaced', () {
      expect(areas.stateForAreaNames('das gesamte Stadtgebiet'), isNull);
      expect(areas.stateForAreaNames(''), isNull);
      expect(areas.stateForAreaNames('und Umland'), isNull);
    });

    test('filler around a real name does not spoil the match', () {
      expect(areas.stateForAreaNames('Stadt Worms und Umland'), 'RP');
    });

    test('a name shared by two states would be unanimous for neither', () {
      // Guards the rule rather than the data: `_statesByCore` holds a set
      // per name for exactly this reason.
      final ambiguous = DwdAreas.parse('''
# name;district;state
Stadt Neustadt;07316;RP
Stadt Neustadt;09573;BY
''');
      expect(ambiguous.stateForAreaNames('Stadt Neustadt'), isNull);
    });
  });

  group('naming a district key', () {
    test('a Kreisschluessel resolves to its district and state', () {
      final found = areas.describeDistrict('07319');
      expect(found?.name, 'Stadt Worms');
      expect(found?.state, 'RP');
    });

    test('the twelve-digit form is accepted, since that is what BBK uses', () {
      // What the app actually stores: the ARS with seven zeroes on the
      // end. Refusing it would leave the one shape people have.
      expect(
        areas.describeDistrict('031010000000')?.name,
        'Stadt Braunschweig',
      );
    });

    test('a district is named after itself, not after a town in it', () {
      // 09184 carries "Gemeinde Aying" and "Stadt Garching b. München"
      // as well; neither is the district.
      expect(areas.describeDistrict('09184')?.name, 'Kreis München');
      // And a kreisfreie Stadt, which has no "Kreis" row at all.
      expect(areas.describeDistrict('09162')?.name, 'Stadt München');
    });

    test('a district whose name has no Kreis prefix is still itself', () {
      expect(areas.describeDistrict('07143')?.name, 'Westerwaldkreis');
    });

    test('an unknown or too-short key answers nothing', () {
      expect(areas.describeDistrict('99999'), isNull);
      expect(areas.describeDistrict('031'), isNull);
    });
  });

  group('against the table the app actually ships', () {
    setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

    test('every district in it resolves to a name and a state', () async {
      final real = DwdAreas.parse(
        await rootBundle.loadString(DwdAreas.assetPath),
      );

      // Spot checks first: these are the ones a wrong rule gets wrong.
      expect(real.describeDistrict('03101')?.name, 'Stadt Braunschweig');
      expect(real.describeDistrict('07319')?.name, 'Stadt Worms');
      expect(real.describeDistrict('07143')?.name, 'Westerwaldkreis');
      expect(real.describeDistrict('07232')?.name, 'Eifelkreis Bitburg-Prüm');
      expect(real.describeDistrict('09184')?.name, 'Kreis München');
      expect(real.describeDistrict('11000')?.name, 'Stadt Berlin');

      expect(real.describeDistrict('03101')?.state, 'NI');
      expect(real.describeDistrict('07319')?.state, 'RP');
    });

    test('the live KATWARN wording is placed off the real table', () async {
      final real = DwdAreas.parse(
        await rootBundle.loadString(DwdAreas.assetPath),
      );
      expect(
        real.stateForAreaNames(
          'Teile von LKr. Alzey-Worms, LKr. Bad Dürkheim, '
          'Rhein-Pfalz-Kreis und Umland',
        ),
        'RP',
      );
    });
  });
}
