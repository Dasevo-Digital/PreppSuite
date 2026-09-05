import '../../../model/categories.dart';

/// The checklist templates every installation starts with.
///
/// Seeded locally now. They used to be inserted by the server at boot,
/// which meant a fresh install had empty checklists until its first
/// successful sync — and no checklists at all without a server.
///
/// The fixed `clientId`s are what make seeding idempotent across restarts
/// and across devices sharing a folder: the same template written twice is
/// the same row, not a duplicate.

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
];
