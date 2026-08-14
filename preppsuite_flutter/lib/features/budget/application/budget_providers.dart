import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_database_providers.dart';
import '../../../local_db/database.dart';

export '../../../core/app_database_providers.dart';

final budgetEntriesProvider = StreamProvider.autoDispose
    .family<List<BudgetEntry>, String>(
      (ref, householdId) =>
          ref.watch(appDatabaseProvider).watchBudgetEntries(householdId),
    );
