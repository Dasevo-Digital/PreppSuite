import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';

/// Seeds a small set of built-in, read-only checklist templates
/// (`householdId == null`) on first server startup. Idempotent: skips
/// entirely if any built-in template already exists, so it's safe to call
/// on every boot.
///
/// This is deliberately a minimal starter set (content curation is a
/// product concern, not an architecture one) proving the built-in/
/// copy-on-customize mechanism end-to-end; expanding the catalog later
/// doesn't require any schema or sync changes.
class ChecklistSeeder {
  const ChecklistSeeder();

  Future<void> seedBuiltInTemplates(Session session) async {
    final existing = await ChecklistTemplate.db.count(
      session,
      where: (t) => t.isBuiltIn.equals(true),
    );
    if (existing > 0) return;

    for (final template in _builtInTemplates) {
      final inserted = await ChecklistTemplate.db.insertRow(
        session,
        ChecklistTemplate(
          clientId: UuidValue.fromString(template.clientId),
          title: template.title,
          category: template.category,
          isBuiltIn: true,
          updatedAt: DateTime.now().toUtc(),
        ),
      );

      var sortOrder = 0;
      for (final item in template.items) {
        await ChecklistItem.db.insertRow(
          session,
          ChecklistItem(
            clientId: UuidValue.fromString(item.clientId),
            templateId: inserted.id!,
            title: item.title,
            sortOrder: sortOrder++,
            updatedAt: DateTime.now().toUtc(),
          ),
        );
      }
    }
  }
}

class _BuiltInTemplate {
  const _BuiltInTemplate(this.clientId, this.title, this.category, this.items);

  final String clientId;
  final String title;
  final ChecklistCategory category;
  final List<_BuiltInItem> items;
}

class _BuiltInItem {
  const _BuiltInItem(this.clientId, this.title);

  final String clientId;
  final String title;
}

const _builtInTemplates = [
  _BuiltInTemplate(
    '00000000-0000-4000-8000-000000000001',
    'Wasser',
    ChecklistCategory.water,
    [
      _BuiltInItem(
        '00000000-0000-4000-8000-000000000101',
        'Trinkwasser (mind. 2 l pro Person und Tag, für 10 Tage)',
      ),
      _BuiltInItem(
        '00000000-0000-4000-8000-000000000102',
        'Wasserkanister/-behälter',
      ),
      _BuiltInItem(
        '00000000-0000-4000-8000-000000000103',
        'Wasserfilter oder Entkeimungsmittel',
      ),
    ],
  ),
  _BuiltInTemplate(
    '00000000-0000-4000-8000-000000000002',
    'Erste Hilfe',
    ChecklistCategory.firstAid,
    [
      _BuiltInItem(
        '00000000-0000-4000-8000-000000000201',
        'Verbandskasten (DIN 13157)',
      ),
      _BuiltInItem(
        '00000000-0000-4000-8000-000000000202',
        'Fieberthermometer',
      ),
      _BuiltInItem(
        '00000000-0000-4000-8000-000000000203',
        'Dauermedikation (ausreichender Vorrat)',
      ),
      _BuiltInItem(
        '00000000-0000-4000-8000-000000000204',
        'Erste-Hilfe-Broschüre',
      ),
    ],
  ),
];
