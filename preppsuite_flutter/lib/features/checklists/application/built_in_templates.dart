import '../../../model/categories.dart';

/// The checklist templates every installation starts with.
///
/// Seeded locally now. They used to be inserted by the server at boot,
/// which meant a fresh install had empty checklists until its first
/// successful sync — and no checklists at all without a server.
///
/// The fixed `clientId`s are what make seeding idempotent across restarts
/// and across devices sharing a folder: the same template written twice is
/// the same row, not a duplicate. It is also what lets this list grow: a
/// template added here appears on the next launch of an install that was
/// seeded long ago, and one that is already there is left exactly as the
/// user left it.
///
/// The content follows the BBK's "Ratgeber für Notfallvorsorge und
/// richtiges Handeln in Notsituationen" and its checklists. German only,
/// like the rest of this file — it is seeded content, not app copy, and
/// once a row is in the database no locale switch can reach it anyway.

class BuiltInTemplate {
  const BuiltInTemplate(this.clientId, this.title, this.category, this.items);

  final String clientId;
  final String title;
  final ChecklistCategory category;
  final List<BuiltInItem> items;
}

class BuiltInItem {
  const BuiltInItem(this.clientId, this.title);

  final String clientId;
  final String title;
}

const builtInTemplates = [
  BuiltInTemplate(
    '00000000-0000-4000-8000-000000000001',
    'Wasser',
    ChecklistCategory.water,
    [
      BuiltInItem(
        '00000000-0000-4000-8000-000000000101',
        'Trinkwasser (mind. 2 l pro Person und Tag, für 10 Tage)',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000000102',
        'Wasserkanister/-behälter',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000000103',
        'Wasserfilter oder Entkeimungsmittel',
      ),
    ],
  ),
  BuiltInTemplate(
    '00000000-0000-4000-8000-000000000002',
    'Erste Hilfe',
    ChecklistCategory.firstAid,
    [
      BuiltInItem(
        '00000000-0000-4000-8000-000000000201',
        'Verbandskasten (DIN 13157)',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000000202',
        'Fieberthermometer',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000000203',
        'Dauermedikation (ausreichender Vorrat)',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000000204',
        'Erste-Hilfe-Broschüre',
      ),
    ],
  ),
  // Mengen je Person für 10 Tage, nach dem Vorratskalkulator des BBK —
  // dieselbe Quelle, aus der auch `supply_calculator.dart` seine 2 l und
  // 2200 kcal pro Person und Tag nimmt.
  BuiltInTemplate(
    '00000000-0000-4000-8000-000000000003',
    'Lebensmittel',
    ChecklistCategory.food,
    [
      BuiltInItem(
        '00000000-0000-4000-8000-000000000301',
        'Getreideprodukte, Brot, Kartoffeln, Nudeln, Reis '
            '(3,5 kg pro Person für 10 Tage)',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000000302',
        'Gemüse und Hülsenfrüchte, z. B. als Konserve (4 kg pro Person '
            'für 10 Tage)',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000000303',
        'Obst und Nüsse (2,5 kg pro Person für 10 Tage)',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000000304',
        'Milch und Milchprodukte (2,6 kg pro Person für 10 Tage)',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000000305',
        'Fisch, Fleisch, Eier oder Volleipulver (1,5 kg pro Person '
            'für 10 Tage)',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000000306',
        'Fette und Öle (0,35 kg pro Person für 10 Tage)',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000000307',
        'Vorrat, der ohne Kochen essbar ist',
      ),
    ],
  ),
  BuiltInTemplate(
    '00000000-0000-4000-8000-000000000004',
    'Hygiene',
    ChecklistCategory.hygiene,
    [
      BuiltInItem(
        '00000000-0000-4000-8000-000000000401',
        'Seife und Handdesinfektionsmittel',
      ),
      BuiltInItem('00000000-0000-4000-8000-000000000402', 'Waschmittel'),
      BuiltInItem(
        '00000000-0000-4000-8000-000000000403',
        'Zahnbürste und Zahnpasta',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000000404',
        'Toilettenpapier und Feuchttücher',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000000405',
        'Müllbeutel, groß und reißfest',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000000406',
        'Haushaltshandschuhe',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000000407',
        'Campingtoilette oder Eimer mit dicht schließendem Deckel — '
            'ohne Wasser spült keine Toilette',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000000408',
        'Was dieser Haushalt sonst braucht: Damenhygiene, Windeln, '
            'Inkontinenzmaterial',
      ),
    ],
  ),
  BuiltInTemplate(
    '00000000-0000-4000-8000-000000000005',
    'Strom- und Heizungsausfall',
    ChecklistCategory.energy,
    [
      BuiltInItem(
        '00000000-0000-4000-8000-000000000501',
        'Taschenlampe und Ersatzbatterien',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000000502',
        'Kerzen, Streichhölzer oder Feuerzeug — Kerzen nie unbeaufsichtigt '
            'brennen lassen',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000000503',
        'Campingkocher mit Brennstoff — nur im Freien oder gut gelüftet, '
            'nie im geschlossenen Raum',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000000504',
        'Holz oder Kohle, falls Ofen oder Kamin vorhanden sind',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000000505',
        'Geladene Powerbank für das Telefon',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000000506',
        'Warme Kleidung, Decken, Schlafsäcke',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000000507',
        'Batterien in den Größen, die im Haushalt vorkommen',
      ),
    ],
  ),
  BuiltInTemplate(
    '00000000-0000-4000-8000-000000000006',
    'Informiert bleiben',
    ChecklistCategory.information,
    [
      BuiltInItem(
        '00000000-0000-4000-8000-000000000601',
        'Batterie- oder Kurbelradio für UKW und DAB+',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000000602',
        'Ersatzbatterien für das Radio',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000000603',
        'Autoradio als Rückfallebene, wenn sonst nichts geht',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000000604',
        'Wichtige Telefonnummern auf Papier — ein leeres Telefon gibt '
            'keine heraus',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000000605',
        'Notrufnummern: 112 für Feuerwehr und Rettungsdienst, '
            '110 für die Polizei',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000000606',
        'Warn-App NINA des BBK auf dem Telefon',
      ),
    ],
  ),
  BuiltInTemplate(
    '00000000-0000-4000-8000-000000000007',
    'Wichtige Dokumente',
    ChecklistCategory.documents,
    [
      BuiltInItem(
        '00000000-0000-4000-8000-000000000701',
        'Dokumentenmappe, griffbereit an einem festen Platz',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000000702',
        'Personalausweis, Reisepass, Führerschein',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000000703',
        'Geburts-, Heirats- und Sterbeurkunden',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000000704',
        'Impfpass, Allergiepass, Medikamentenplan',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000000705',
        'Versicherungspolicen',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000000706',
        'Grundbuchauszug, Miet- oder Kaufverträge',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000000707',
        'Renten-, Einkommens- und Steuerbescheide',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000000708',
        'Zeugnisse und Qualifikationsnachweise',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000000709',
        'Beglaubigte Kopien, getrennt von den Originalen aufbewahrt',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000000710',
        'Digitale Kopien auf einem USB-Stick in der Mappe',
      ),
    ],
  ),
  BuiltInTemplate(
    '00000000-0000-4000-8000-000000000008',
    'Notgepäck',
    ChecklistCategory.evacuation,
    [
      BuiltInItem(
        '00000000-0000-4000-8000-000000000801',
        'Ein Rucksack je Person, den sie allein tragen kann',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000000802',
        'Persönliche Medikamente und kleine Hausapotheke',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000000803',
        'Dokumentenmappe',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000000804',
        'Verpflegung und Getränke für zwei bis drei Tage',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000000805',
        'Essgeschirr, Taschenmesser, Dosenöffner',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000000806',
        'Wetterfeste Kleidung, Wechselwäsche, festes Schuhwerk',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000000807',
        'Schlafsack oder Decke',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000000808',
        'Hygieneartikel im Reiseformat',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000000809',
        'Taschenlampe, Radio, Ersatzbatterien',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000000810',
        'Bargeld in kleinen Scheinen — Kartenzahlung braucht Strom',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000000811',
        'Telefon, Ladekabel, Powerbank',
      ),
    ],
  ),
  BuiltInTemplate(
    '00000000-0000-4000-8000-000000000009',
    'Sicherheit im Haus',
    ChecklistCategory.safety,
    [
      BuiltInItem(
        '00000000-0000-4000-8000-000000000901',
        'Rauchmelder in Schlaf- und Kinderzimmern und im Flur, '
            'einmal im Jahr geprüft',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000000902',
        'Geprüfter Feuerlöscher',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000000903',
        'Löschdecke für die Küche',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000000904',
        'Kohlenmonoxidmelder, wenn mit Gas oder festem Brennstoff geheizt '
            'oder gekocht wird',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000000905',
        'Fluchtwege frei halten und mit allen im Haushalt durchgehen',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000000906',
        'Treffpunkt außerhalb des Hauses vereinbaren',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000000907',
        'Absperrhähne für Gas, Wasser und Strom kennen und erreichen können',
      ),
    ],
  ),
  BuiltInTemplate(
    '00000000-0000-4000-8000-000000000010',
    'Haustiere',
    ChecklistCategory.pets,
    [
      BuiltInItem(
        '00000000-0000-4000-8000-000000001001',
        'Futter für mindestens zehn Tage',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000001002',
        'Trinkwasser für die Tiere — der Vorratsrechner zählt es mit',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000001003',
        'Transportbox oder -tasche für jedes Tier',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000001004',
        'Leine, Halsband, Maulkorb',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000001005',
        'Impfpass und Chip- oder Tätowierungsnummer',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000001006',
        'Medikamente des Tieres',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000001007',
        'Decke und gewohntes Spielzeug',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000001008',
        'Kotbeutel, Katzenstreu, Einstreu',
      ),
    ],
  ),
];
