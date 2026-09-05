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

  final AppDatabase _db;

  Future<void> seed(String householdId) async {
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
          updatedAt: DateTime.now().toUtc(),
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
            updatedAt: DateTime.now().toUtc(),
            dirty: const Value(true),
          ),
        );
      }
    }
  }
}
