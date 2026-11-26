import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/app_database_providers.dart';
import '../../checklists/application/checklist_seeder.dart';
import '../../../model/household_profile.dart';
import '../../inventory/application/inventory_photo_service.dart';
import '../../../model/household_profile_store.dart';
import '../../warnings/application/warning_region_filter.dart';
import '../../warnings/application/warning_region_store.dart';

/// The household profile, or null while it is still loading or has never
/// been set up.
///
/// Replaces what used to be a round trip to the server for the signed-in
/// user's household. There is no signing in any more: the profile is this
/// installation's own, created on first run.
class HouseholdProfileController extends AsyncNotifier<HouseholdProfile?> {
  static const _store = HouseholdProfileStore();

  @override
  Future<HouseholdProfile?> build() => _store.load();

  /// Creates the profile on first run.
  Future<HouseholdProfile> create({
    required String name,
    required String countryCode,
    String? regionKey,
    int personCount = 1,
    int children = 0,
    int dogs = 0,
    int cats = 0,
  }) async {
    final profile = HouseholdProfile(
      // Generated once and then fixed: every local row partitions by it,
      // and two devices sharing a folder have to agree on it for their
      // rows to merge rather than pile up side by side.
      id: const Uuid().v4(),
      name: name,
      countryCode: countryCode,
      regionKey: regionKey,
      personCount: personCount,
      children: children,
      dogs: dogs,
      cats: cats,
    );
    await _persist(profile);
    return profile;
  }

  /// Named `save` rather than `update` because [AsyncNotifier] already
  /// defines an `update` with an incompatible shape.
  Future<void> save(HouseholdProfile profile) => _persist(profile);

  /// Adopts a profile that came from somewhere else — a shared folder, a
  /// restored backup — keeping its id so the data merges.
  Future<void> adopt(HouseholdProfile profile) => _persist(profile);

  /// Moves this device from [from] into the household [id].
  ///
  /// The one place this happens, for every road into another household —
  /// a shared folder, a QR chain, a local handover. It used to be spelled
  /// out on each of them, and the copies drifted: the folder's left the
  /// children and the pets behind, so a household that joined one planned
  /// for adults only from then on.
  ///
  /// With [discardOwnRows] this device's rows are deleted rather than
  /// re-stamped. The caller must already hold what it is moving into —
  /// the folder checked, the other device's rows received — because this
  /// cannot be undone, and deleting first is how a handover that then
  /// failed once left a device with nothing at all.
  ///
  /// Everything else in the profile stays: which warnings this device
  /// follows and whom it plans for belong to the device, not to the
  /// shared data. [name] and [countryCode] replace this device's own
  /// where the caller has the other household's.
  ///
  /// Takes its turn with [forHousehold] (#397): a write for the old
  /// household that lands after the re-stamp stays under the old id, out
  /// of sight of every query, of the folder and of "delete household".
  Future<HouseholdProfile> moveInto(
    HouseholdProfile from,
    String id, {
    String? name,
    String? countryCode,
    bool discardOwnRows = false,
  }) async {
    final moved = from.copyWith(id: id, name: name, countryCode: countryCode);
    if (id == from.id) return moved;

    return ref.read(householdTurnsProvider).take(() async {
      final db = ref.read(appDatabaseProvider);
      if (discardOwnRows) {
        await deleteHouseholdPhotos(db, householdId: from.id);
        await db.deleteHouseholdData(from.id);
      } else {
        // Without the re-stamp the rows do not merge — they stop being
        // visible, because every query selects by this id.
        await db.adoptHouseholdId(from: from.id, to: id);
      }
      await _persist(moved);
      return moved;
    });
  }

  /// Runs [work] for the household [id], but only while it is this
  /// device's household, and never beside a [moveInto] (#397).
  ///
  /// For writes that start on their own and name the household when they
  /// start: the built-in checklists, which the gate writes as soon as a
  /// profile appears. On first setup that is the profile the form has
  /// just made, and joining a folder moves it a moment later. Run beside
  /// the move, the lists written after the re-stamp stayed under the old
  /// id; a tick on them was never published, "x of y" did not count them
  /// and "delete household" left them behind. Now a move waits for work
  /// under way, and work that comes after a move finds its household gone
  /// and does nothing -- the new household gets its own run.
  Future<void> forHousehold(String id, Future<void> Function() work) =>
      ref.read(householdTurnsProvider).take(() async {
        if (state.value?.id != id) return;
        await work();
      });

  /// Drops the profile, putting the app back on the setup screen.
  ///
  /// For one case only: a join during first run that created the profile
  /// and then failed to attach it to the folder or the other device. The
  /// gate goes by the profile alone, so leaving it behind would let the
  /// app through into a household that is joined to nothing — with a
  /// fresh id that can never merge with the one it was meant to join.
  ///
  /// The built-in lists the gate wrote for that profile go with it, as far
  /// as nobody touched them (#397): left under the forgotten id, the next
  /// profile's lists were skipped as existing and never became its own.
  /// In its turn, so a run still writing them finishes first. A failure
  /// there costs the tidying, never the forgetting.
  Future<void> forget() => ref.read(householdTurnsProvider).take(() async {
    final forgotten = state.value?.id;
    if (forgotten != null) {
      try {
        await ChecklistSeeder(
          ref.read(appDatabaseProvider),
        ).forgetUntouched(forgotten);
      } on Object catch (error, stack) {
        developer.log(
          'built-in lists of a forgotten profile could not be removed',
          name: 'preppsuite.household',
          error: error,
          stackTrace: stack,
        );
      }
    }
    await _store.clear();
    state = const AsyncData(null);
  });

  Future<void> _persist(HouseholdProfile profile) async {
    await _store.save(profile);
    // The background worker cannot read this provider, so the regions it
    // polls for are mirrored into their own store on every change.
    await const WarningRegionStore().save(profile.warningFilter);
    state = AsyncData(profile);
  }

  Future<void> addRegion(WarningRegion region) async {
    final profile = state.value;
    if (profile == null) return;
    final existing = profile.extraRegions.indexOf(region);
    if (existing >= 0) {
      final updated = [...profile.extraRegions]..[existing] = region;
      await _persist(profile.copyWith(extraRegions: updated));
      return;
    }
    await _persist(
      profile.copyWith(extraRegions: [...profile.extraRegions, region]),
    );
  }

  Future<void> removeRegion(WarningRegion region) async {
    final profile = state.value;
    if (profile == null) return;
    await _persist(
      profile.copyWith(
        extraRegions: [
          for (final existing in profile.extraRegions)
            if (existing != region) existing,
        ],
      ),
    );
  }

  Future<void> clear() async {
    await _store.clear();
    await const WarningRegionStore().clear();
    state = const AsyncData(null);
  }
}

final householdProfileProvider =
    AsyncNotifierProvider<HouseholdProfileController, HouseholdProfile?>(
      HouseholdProfileController.new,
    );

/// One thing at a time between moving households and the writes that
/// belong to one (#397); see [HouseholdProfileController.forHousehold].
///
/// A provider of its own rather than a field of the controller: the
/// controller is built afresh whenever its provider is, and a queue that
/// went with it would let a move and a write run side by side again.
class HouseholdTurns {
  Future<void> _last = Future.value();

  /// Runs [work] once everything handed in before it has finished,
  /// failed or not.
  Future<T> take<T>(Future<T> Function() work) {
    final previous = _last;
    final done = Completer<void>();
    _last = done.future;
    return previous.then((_) => work()).whenComplete(done.complete);
  }
}

final householdTurnsProvider = Provider<HouseholdTurns>(
  (ref) => HouseholdTurns(),
);
