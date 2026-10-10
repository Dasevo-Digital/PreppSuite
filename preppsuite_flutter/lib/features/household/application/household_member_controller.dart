/// Reading and writing the household's emergency cards.
library;

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/app_database_providers.dart';
import '../../../local_db/database.dart';

final householdMembersProvider = StreamProvider.autoDispose
    .family<List<HouseholdMember>, String>((ref, householdId) {
      return ref.watch(appDatabaseProvider).watchHouseholdMembers(householdId);
    });

/// The cards read once rather than watched: what a form offers as a
/// choice of person (#150). A list that cannot change while the form is
/// open costs nothing, and it leaves no live query behind when the form
/// closes.
final householdMemberChoicesProvider = FutureProvider.autoDispose
    .family<List<HouseholdMember>, String>((ref, householdId) {
      return ref.watch(appDatabaseProvider).householdMembersOnce(householdId);
    });

/// What a card holds. Only [name] is required — see [HouseholdMembers].
class HouseholdMemberDraft {
  const HouseholdMemberDraft({
    required this.name,
    this.birthYear,
    this.bloodType,
    this.allergies,
    this.medication,
    this.conditions,
    this.insurance,
    this.doctor,
    this.emergencyContact,
    this.careNeeds,
    this.notes,
  });

  final String name;
  final int? birthYear;
  final String? bloodType;
  final String? allergies;
  final String? medication;
  final String? conditions;
  final String? insurance;
  final String? doctor;
  final String? emergencyContact;
  final String? careNeeds;
  final String? notes;
}

class HouseholdMemberController {
  const HouseholdMemberController({
    required AppDatabase database,
    required this.householdId,
  }) : _db = database;

  final AppDatabase _db;
  final String householdId;

  /// Adds a card, or rewrites [existing] if one is given.
  ///
  /// A generated client id, unlike the plan: these are many rows, each
  /// created on one device, which is the ordinary case the rest of this
  /// database is built for.
  Future<void> save(
    HouseholdMemberDraft draft, {
    HouseholdMember? existing,
    int? sortOrder,
  }) async {
    await _db.upsertHouseholdMember(
      HouseholdMembersCompanion.insert(
        clientId: existing?.clientId ?? const Uuid().v4(),
        householdId: householdId,
        name: draft.name.trim(),
        birthYear: Value(draft.birthYear),
        bloodType: Value(_trimmed(draft.bloodType)),
        allergies: Value(_trimmed(draft.allergies)),
        medication: Value(_trimmed(draft.medication)),
        conditions: Value(_trimmed(draft.conditions)),
        insurance: Value(_trimmed(draft.insurance)),
        doctor: Value(_trimmed(draft.doctor)),
        emergencyContact: Value(_trimmed(draft.emergencyContact)),
        careNeeds: Value(_trimmed(draft.careNeeds)),
        notes: Value(_trimmed(draft.notes)),
        sortOrder: Value(sortOrder ?? existing?.sortOrder ?? 0),
        updatedAt: DateTime.now().toUtc(),
        // An edit must be able to undo a delete, and a rewritten row that
        // kept its tombstone would vanish again on the next merge.
        deletedAt: const Value(null),
        dirty: const Value(true),
      ),
    );
  }

  /// Tombstones rather than deletes, so the removal reaches the other
  /// devices instead of being undone by the next merge.
  Future<void> remove(HouseholdMember existing) async {
    final now = DateTime.now().toUtc();
    await _db.upsertHouseholdMember(
      existing
          .toCompanion(false)
          .copyWith(
            deletedAt: Value(now),
            updatedAt: Value(now),
            dirty: const Value(true),
          ),
    );
  }

  static String? _trimmed(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}

final householdMemberControllerProvider = Provider.autoDispose
    .family<HouseholdMemberController, String>((ref, householdId) {
      return HouseholdMemberController(
        database: ref.watch(appDatabaseProvider),
        householdId: householdId,
      );
    });
