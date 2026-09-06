/// Reading and writing the household's emergency plan.
library;

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_database_providers.dart';
import '../../../local_db/database.dart';

/// The plan, or null while the household has not written one.
final householdPlanProvider = StreamProvider.autoDispose
    .family<HouseholdPlan?, String>((ref, householdId) {
      return ref.watch(appDatabaseProvider).watchHouseholdPlan(householdId);
    });

/// What a screen hands back when the plan is saved.
class HouseholdPlanDraft {
  const HouseholdPlanDraft({
    this.meetingPointNear,
    this.meetingPointFar,
    this.contactName,
    this.contactPhone,
    this.kitLocation,
    this.shutoffLocation,
    this.notes,
  });

  final String? meetingPointNear;
  final String? meetingPointFar;
  final String? contactName;
  final String? contactPhone;
  final String? kitLocation;
  final String? shutoffLocation;
  final String? notes;

  /// Whether anything at all was written down.
  bool get isEmpty => [
    meetingPointNear,
    meetingPointFar,
    contactName,
    contactPhone,
    kitLocation,
    shutoffLocation,
    notes,
  ].every((value) => value == null || value.isEmpty);
}

class HouseholdPlanController {
  const HouseholdPlanController({
    required AppDatabase database,
    required this.householdId,
  }) : _db = database;

  final AppDatabase _db;
  final String householdId;

  Future<void> save(HouseholdPlanDraft draft) async {
    await _db.upsertHouseholdPlan(
      HouseholdPlansCompanion.insert(
        // The household id, on purpose: one plan per household, edited
        // from every device. See [HouseholdPlans].
        clientId: householdId,
        householdId: householdId,
        meetingPointNear: Value(_trimmed(draft.meetingPointNear)),
        meetingPointFar: Value(_trimmed(draft.meetingPointFar)),
        contactName: Value(_trimmed(draft.contactName)),
        contactPhone: Value(_trimmed(draft.contactPhone)),
        kitLocation: Value(_trimmed(draft.kitLocation)),
        shutoffLocation: Value(_trimmed(draft.shutoffLocation)),
        notes: Value(_trimmed(draft.notes)),
        updatedAt: DateTime.now().toUtc(),
        // Cleared here rather than anywhere else, so a plan written on
        // one device reaches the others. Every local write sets this
        // explicitly — see ARCHITEKTUR.md.
        deletedAt: const Value(null),
        dirty: const Value(true),
      ),
    );
  }

  /// Tombstones the plan rather than deleting the row, so the deletion
  /// reaches the other devices instead of being undone by the next merge.
  Future<void> clear(HouseholdPlan existing) async {
    await _db.upsertHouseholdPlan(
      existing
          .toCompanion(false)
          .copyWith(
            deletedAt: Value(DateTime.now().toUtc()),
            updatedAt: Value(DateTime.now().toUtc()),
            dirty: const Value(true),
          ),
    );
  }

  /// Empty is stored as null, not as "": the screen asks "is there a
  /// meeting point", and an empty string would answer yes.
  static String? _trimmed(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}

final householdPlanControllerProvider = Provider.autoDispose
    .family<HouseholdPlanController, String>((ref, householdId) {
      return HouseholdPlanController(
        database: ref.watch(appDatabaseProvider),
        householdId: householdId,
      );
    });
