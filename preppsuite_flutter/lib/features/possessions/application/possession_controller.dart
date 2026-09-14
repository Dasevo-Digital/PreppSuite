/// Reading and writing the household's inventory of what it owns.
library;

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/app_database_providers.dart';
import '../../../local_db/database.dart';

final possessionsProvider = StreamProvider.autoDispose
    .family<List<Possession>, String>((ref, householdId) {
      return ref.watch(appDatabaseProvider).watchPossessions(householdId);
    });

/// What one entry holds. Only [name] is required, for the same reason a
/// card needs only a name: a list of forty rooms' worth of things, each
/// with a name and nothing else, is still the difference between an
/// insurer's questionnaire being answerable and not.
class PossessionDraft {
  const PossessionDraft({
    required this.name,
    this.room,
    this.serialNumber,
    this.acquiredOn,
    this.purchasePriceCents,
    this.currency,
    this.notes,
    this.photoPath,
  });

  final String name;
  final String? room;
  final String? serialNumber;
  final DateTime? acquiredOn;
  final int? purchasePriceCents;
  final String? currency;
  final String? notes;
  final String? photoPath;
}

class PossessionController {
  const PossessionController({
    required AppDatabase database,
    required this.householdId,
  }) : _db = database;

  final AppDatabase _db;
  final String householdId;

  Future<void> save(PossessionDraft draft, {Possession? existing}) async {
    await _db.upsertPossession(
      PossessionsCompanion.insert(
        clientId: existing?.clientId ?? const Uuid().v4(),
        householdId: householdId,
        name: draft.name.trim(),
        room: Value(_trimmed(draft.room)),
        serialNumber: Value(_trimmed(draft.serialNumber)),
        acquiredOn: Value(draft.acquiredOn),
        purchasePriceCents: Value(draft.purchasePriceCents),
        currency: Value(_trimmed(draft.currency)),
        notes: Value(_trimmed(draft.notes)),
        photoPath: Value(draft.photoPath),
        updatedAt: DateTime.now().toUtc(),
        // An edit must be able to undo a delete, or a rewritten row would
        // keep its tombstone and vanish again at the next merge.
        deletedAt: const Value(null),
        dirty: const Value(true),
      ),
    );
  }

  /// A tombstone rather than a delete, so the removal reaches the other
  /// devices instead of the row coming back at the next merge.
  Future<void> remove(Possession possession) async {
    await _db.upsertPossession(
      possession
          .toCompanion(false)
          .copyWith(
            deletedAt: Value(DateTime.now().toUtc()),
            updatedAt: Value(DateTime.now().toUtc()),
            dirty: const Value(true),
          ),
    );
  }

  static String? _trimmed(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}

final possessionControllerProvider = Provider.autoDispose
    .family<PossessionController, String>((ref, householdId) {
      return PossessionController(
        database: ref.watch(appDatabaseProvider),
        householdId: householdId,
      );
    });

/// The entries grouped by room, in the order the rooms first appear.
///
/// Grouped rather than sorted flat because that is the shape a claim is
/// made in: an adjuster walks a flat room by room, and so does anybody
/// trying to remember what was in it.
Map<String?, List<Possession>> byRoom(List<Possession> rows) {
  final grouped = <String?, List<Possession>>{};
  for (final row in rows) {
    grouped.putIfAbsent(row.room, () => []).add(row);
  }
  return grouped;
}

/// What the listed things cost, per currency.
///
/// Per currency and never summed across them: adding euros to francs
/// would produce a total that is wrong in a way nobody notices. A
/// household with one currency — nearly all of them — sees one figure.
///
/// Entries without a price are simply not in it. The screen says how many
/// those are, because a total that silently covers half the list is worse
/// than no total.
Map<String, int> totalCentsByCurrency(List<Possession> rows) {
  final totals = <String, int>{};
  for (final row in rows) {
    final cents = row.purchasePriceCents;
    if (cents == null) continue;
    final currency = row.currency ?? '';
    totals[currency] = (totals[currency] ?? 0) + cents;
  }
  return totals;
}

/// How many entries carry no price, i.e. are missing from every total.
int withoutPrice(List<Possession> rows) =>
    rows.where((row) => row.purchasePriceCents == null).length;
