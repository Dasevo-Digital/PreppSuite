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

  static const _retiredBuiltInItems = [
    // The inventory and supply calculator already track the required
    // drinking-water quantity. The checklist keeps the equipment needed
    // to store and treat it, without asking for the same stock twice.
    '00000000-0000-4000-8000-000000000101',

    // Moved out of the two hazard lists, which are about having things
    // ready, and into the lists that are about acting -- "Hochwasser:
    // wenn es soweit ist" and "Sturm und Unwetter: wenn es soweit ist".
    // Retired rather than left in place, because the same instruction
    // with a tick box in two lists is two pieces of bookkeeping and one
    // of them is always the stale one.
    '00000000-0000-4000-8000-000000001109',
    '00000000-0000-4000-8000-000000001110',
    '00000000-0000-4000-8000-000000001302',
    '00000000-0000-4000-8000-000000001310',
  ];

  Future<void> seed(String householdId) async {
    await _db.claimOrphanChecklistRows(householdId);

    for (final clientId in _retiredBuiltInItems) {
      await _db.retireChecklistItem(clientId);
    }

    for (final template in builtInTemplates) {
      if (await _db.checklistTemplateByClientId(template.clientId) != null) {
        // Already seeded, so its contents are the household's now and
        // nothing here rewrites them. Its filing is not its contents:
        // whether a list is about having things ready or about acting is
        // decided in `built_in_templates.dart` and nowhere else, and a
        // household seeded before that distinction existed has every one
        // of them filed under `preparation`. This is the one write that
        // reaches them — see [AppDatabase.setChecklistTemplateKind] for
        // why it is not an edit.
        await _db.setChecklistTemplateKind(
          template.clientId,
          template.kind.name,
        );
        continue;
      }

      await _db.upsertChecklistTemplate(
        ChecklistTemplatesCompanion.insert(
          clientId: template.clientId,
          householdId: Value(householdId),
          title: template.title,
          category: template.category.name,
          kind: Value(template.kind.name),
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
