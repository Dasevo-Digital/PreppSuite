/// The German poison information centres, written down once.
///
/// They were written down twice: the first-aid guide carried nine and the
/// emergency-information screen carried seven, and the two had drifted.
/// The guide's extra two were **Homburg/Saar**, whose centre closed around
/// 2021 — Saarland is answered by Mainz since — and **Nürnberg**, which is
/// not one of the centres the official list names. So the guide that is
/// read while somebody is standing over a child held a number that nobody
/// picks up.
///
/// That is the whole reason this file exists. Two lists of the same
/// emergency numbers are not redundancy, they are a coin toss, and the one
/// that loses is whichever the person happened to open.
///
/// Checked on 2026-09-20 against the BfR's register of
/// Giftinformationszentren and the Einsatzleiterwiki's list: seven
/// centres, and the two listed above are on neither.
///
/// The numbers are a stored snapshot all the same, which the guide says
/// out loud — a household should check them while it still has a network
/// and put its own one into the emergency contacts.
library;

import 'first_aid_guide.dart';

/// City and telephone number, in the shape the first-aid guide wants.
const poisonCentres = <FirstAidFact>[
  FirstAidFact('Berlin', '030 19240'),
  FirstAidFact('Bonn', '0228 19240'),
  FirstAidFact('Erfurt', '0361 730730'),
  FirstAidFact('Freiburg', '0761 19240'),
  FirstAidFact('Göttingen', '0551 19240'),
  FirstAidFact('Mainz', '06131 19240'),
  FirstAidFact('München', '089 19240'),
];

/// How each centre is named where the point is *which one is mine* —
/// by the Länder it answers for, rather than by the city it sits in.
///
/// Place names stay German in both languages, the way they do everywhere
/// else on the map: what is dialled is a German number.
const poisonCentreRegions = <String, String>{
  'Berlin': 'Berlin/Brandenburg',
  'Bonn': 'Bonn (NRW)',
  'Erfurt': 'Erfurt (MV, SN, ST, TH)',
  'Freiburg': 'Freiburg (BW)',
  'Göttingen': 'Göttingen (HB, HH, NI, SH)',
  'Mainz': 'Mainz (HE, RP, SL)',
  'München': 'München (BY)',
};

/// The centres as the emergency screen lists them: region first.
List<({String label, String phone})> get poisonCentresByRegion => [
  for (final centre in poisonCentres)
    (
      label: poisonCentreRegions[centre.label] ?? centre.label,
      phone: centre.value,
    ),
];
