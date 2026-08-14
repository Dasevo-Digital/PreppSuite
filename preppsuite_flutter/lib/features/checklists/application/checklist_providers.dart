import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_database_providers.dart';
import '../../../local_db/database.dart';

export '../../../core/app_database_providers.dart';

/// A household's own checklist templates plus every built-in one.
final checklistTemplatesProvider = StreamProvider.autoDispose
    .family<List<ChecklistTemplate>, String>(
      (ref, householdId) =>
          ref.watch(appDatabaseProvider).watchChecklistTemplates(householdId),
    );

/// Items of one template, keyed by the template's local clientId.
final checklistItemsProvider = StreamProvider.autoDispose
    .family<List<ChecklistItem>, String>(
      (ref, templateClientId) =>
          ref.watch(appDatabaseProvider).watchChecklistItems(templateClientId),
    );
