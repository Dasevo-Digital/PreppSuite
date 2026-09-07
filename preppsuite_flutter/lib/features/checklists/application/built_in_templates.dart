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
  // Die folgenden Listen bilden die Zweige nach, die der BBK-Ratgeber
  // unter "Vorsorge" fuehrt und die hier fehlten: die Naturgefahren,
  // das Schutzsuchen im eigenen Haus, der Umgang mit der Lage, und
  // die Menschen, deren Bedarf keine der anderen Listen trifft.
  BuiltInTemplate(
    '00000000-0000-4000-8000-000000000011',
    'Hochwasser und Starkregen',
    ChecklistCategory.hazards,
    [
      BuiltInItem(
        '00000000-0000-4000-8000-000000001101',
        'Auf der Hochwassergefahrenkarte des Landes nachsehen, ob die '
            'Adresse betroffen sein kann',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000001102',
        'Rückstauklappen in den Abwasserleitungen — einmal im Jahr geprüft',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000001103',
        'Kellerfenster und Lichtschächte gegen eindringendes Wasser sichern',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000001104',
        'Öltank und Heizungsanlage gegen Auftrieb sichern',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000001105',
        'Elementarschadenversicherung prüfen — Hochwasser ist in der '
            'Wohngebäudeversicherung nicht enthalten',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000001106',
        'Nichts Unersetzliches im Keller lagern',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000001107',
        'Tauchpumpe, Schläuche und Sandsäcke griffbereit',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000001108',
        'Wissen, wo der Stromkreis für den Keller abgeschaltet wird',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000001109',
        'Bei Hochwasser den Keller nicht betreten — Strom im Wasser, und '
            'Räume laufen schneller voll, als man herauskommt',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000001110',
        'Pegelstände und Warnungen verfolgen: NINA und der Warndienst des '
            'Landes',
      ),
    ],
  ),
  BuiltInTemplate(
    '00000000-0000-4000-8000-000000000012',
    'Hitze und Dürre',
    ChecklistCategory.hazards,
    [
      BuiltInItem(
        '00000000-0000-4000-8000-000000001201',
        'Nachts und früh am Morgen lüften, tagsüber Fenster und Rollläden '
            'geschlossen halten',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000001202',
        'Mehr trinken als sonst, auch ohne Durst',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000001203',
        'Leichte Mahlzeiten, wenig Alkohol',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000001204',
        'Anstrengendes in die kühlen Stunden legen',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000001205',
        'Medikamente kühl lagern — viele vertragen keine 25 Grad; der '
            'Beipackzettel sagt es',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000001206',
        'Bei Hitze wirken manche Medikamente anders — einmal mit der '
            'Hausarztpraxis durchgehen',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000001207',
        'Einen kühlen Raum in der Wohnung bestimmen',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000001208',
        'Nach älteren und alleinlebenden Nachbarn sehen',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000001209',
        'Kinder und Tiere nie im Auto lassen',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000001210',
        'Anzeichen eines Hitzschlags kennen: Kopfschmerz, Übelkeit, '
            'Verwirrtheit, heiße trockene Haut',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000001211',
        'Bei Trockenheit im Wald kein Feuer, nicht rauchen, nicht auf '
            'trockenem Gras parken',
      ),
    ],
  ),
  BuiltInTemplate(
    '00000000-0000-4000-8000-000000000013',
    'Sturm, Kälte und Schnee',
    ChecklistCategory.hazards,
    [
      BuiltInItem(
        '00000000-0000-4000-8000-000000001301',
        'Lose Gegenstände auf Balkon, Terrasse und im Garten sichern, bevor '
            'der Sturm da ist',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000001302',
        'Bei Sturm im Haus bleiben, Fenster und Türen schließen, nicht '
            'unter Bäume stellen',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000001303',
        'Dach, Dachrinnen und Bäume am Haus regelmäßig prüfen lassen',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000001304',
        'Schneelast auf Flachdach, Carport und Wintergarten im Blick '
            'behalten',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000001305',
        'Heizung vor dem Winter warten lassen',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000001306',
        'Wasserleitungen in unbeheizten Räumen gegen Frost schützen',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000001307',
        'Für den Heizungsausfall: warme Kleidung, Decken, Schlafsäcke — und '
            'Brennstoff, wenn ein Ofen da ist',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000001308',
        'Streugut und Schneeschaufel',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000001309',
        'Im Auto: Decke, Schaufel, warme Sachen — und im Winter nicht mit '
            'fast leerem Tank fahren',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000001310',
        'Nach dem Sturm: heruntergefallene Leitungen melden, nie selbst '
            'anfassen',
      ),
    ],
  ),
  BuiltInTemplate(
    '00000000-0000-4000-8000-000000000014',
    'Schutz suchen',
    ChecklistCategory.safety,
    [
      BuiltInItem(
        '00000000-0000-4000-8000-000000001401',
        'Den sichersten Raum der Wohnung bestimmen: innenliegend, ohne '
            'Fenster, möglichst im Kern des Gebäudes',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000001402',
        'Bei Sturm und Unwetter: unteres Geschoss, weg von Fenstern',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000001403',
        'Bei Hochwasser: nach oben, nie in den Keller',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000001404',
        'Bei einem Gefahrstoffaustritt: hinein, Fenster und Türen '
            'schließen, Lüftung und Klimaanlage aus, Radio an',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000001405',
        'Bei Explosion oder Erschütterung: weg von Glas und Fensterfronten',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000001406',
        'Wissen, welches feste Gebäude in der Nähe Schutz böte',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000001407',
        'Fluchtwege aus dem Gebäude kennen, auch im Dunkeln',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000001408',
        'Treffpunkt für den Fall, dass der Haushalt getrennt wird — er '
            'steht auch im Notfallplan',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000001409',
        'Wissen, wer in der Nachbarschaft helfen kann und wer Hilfe braucht',
      ),
    ],
  ),
  BuiltInTemplate(
    '00000000-0000-4000-8000-000000000015',
    'Mit Ängsten und Sorgen umgehen',
    ChecklistCategory.wellbeing,
    [
      BuiltInItem(
        '00000000-0000-4000-8000-000000001501',
        'Feste Zeiten für Nachrichten, dazwischen bewusst abschalten',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000001502',
        'Nur verlässliche Quellen: amtliche Warnungen und öffentlich- '
            'rechtlicher Rundfunk',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000001503',
        'Tagesstruktur halten — Schlaf, Mahlzeiten, Bewegung',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000001504',
        'Mit anderen sprechen, statt allein zu grübeln',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000001505',
        'Mit Kindern altersgerecht sprechen, Fragen ernst nehmen und nicht '
            'beschwichtigen',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000001506',
        'Kindern zeigen, was der Haushalt vorbereitet hat — Vorbereitung '
            'nimmt Angst',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000001507',
        'Auf Anzeichen achten: Schlaflosigkeit, Reizbarkeit, Rückzug',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000001508',
        'Telefonseelsorge: 0800 111 0 111 und 0800 111 0 222, rund um die '
            'Uhr und kostenfrei',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000001509',
        'Wissen, wer im Haushalt in einer Krise besonders auf Beistand '
            'angewiesen ist',
      ),
    ],
  ),
  BuiltInTemplate(
    '00000000-0000-4000-8000-000000000016',
    'Säuglinge, Pflege und Barrierefreiheit',
    ChecklistCategory.firstAid,
    [
      BuiltInItem(
        '00000000-0000-4000-8000-000000001601',
        'Säuglingsnahrung und abgekochtes Wasser für zehn Tage',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000001602',
        'Windeln, Feuchttücher, Wickelunterlage',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000001603',
        'Pflegehilfsmittel für zehn Tage: Inkontinenzmaterial, '
            'Verbandsstoffe, Desinfektion',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000001604',
        'Ersatzbatterien und Ladegeräte für Hörgerät, Rollstuhl, Pflegebett',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000001605',
        'Für jedes Gerät, das Strom braucht, die handbetriebene Alternative '
            'klären',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000001606',
        'Medikamentenplan und Pflegeunterlagen in der Dokumentenmappe',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000001607',
        'Klären, wer beim Verlassen der Wohnung hilft, wenn der Aufzug '
            'steht',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000001608',
        'Nachbarn und Pflegedienst wissen lassen, wer im Haus Hilfe braucht',
      ),
      BuiltInItem(
        '00000000-0000-4000-8000-000000001609',
        'Für jede Person eine Notfallkarte ausfüllen — in PreppSuite unter '
            'Haushalt',
      ),
    ],
  ),
];
