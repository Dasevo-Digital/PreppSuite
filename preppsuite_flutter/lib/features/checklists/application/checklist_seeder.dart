import 'package:drift/drift.dart';

import '../../../local_db/database.dart';
import 'built_in_templates.dart';

/// Writes the built-in checklist templates into the local database.
///
/// Idempotent by `clientId`, so it runs on every launch without piling up
/// duplicates — which is also what lets a device that adopted someone
/// else's shared data run it harmlessly.
class ChecklistSeeder {
  const ChecklistSeeder(this._db);

  /// The `updatedAt` every seeded row carries, on every device, forever.
  ///
  /// A real timestamp would make the seed itself an edit: a device set up
  /// today would arrive in a shared folder with fresher built-ins than the
  /// device that ticked half of them off last month, and the merge — which
  /// keeps the newer row — would faithfully un-tick them. A fixed instant
  /// in the past means any genuine edit always wins.
  static final seededAt = DateTime.utc(2024, 1, 1);

  final AppDatabase _db;

  Future<void> seed(String householdId) async {
    await _db.claimOrphanChecklistRows(householdId);

    for (final template in builtInTemplates) {
      if (await _db.checklistTemplateByClientId(template.clientId) != null) {
        continue;
      }

      await _db.upsertChecklistTemplate(
        ChecklistTemplatesCompanion.insert(
          clientId: template.clientId,
          householdId: Value(householdId),
          title: template.title,
          category: template.category.name,
          isBuiltIn: const Value(true),
          updatedAt: seededAt,
          dirty: const Value(true),
        ),
      );

      var sortOrder = 0;
      for (final item in template.items) {
        await _db.upsertChecklistItem(
          ChecklistItemsCompanion.insert(
            clientId: item.clientId,
            householdId: Value(householdId),
            templateClientId: template.clientId,
            title: item.title,
            sortOrder: Value(sortOrder++),
            updatedAt: seededAt,
            dirty: const Value(true),
          ),
        );
      }
    }
  }
}
