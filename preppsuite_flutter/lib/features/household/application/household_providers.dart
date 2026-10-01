import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/app_database_providers.dart';
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
  Future<HouseholdProfile> moveInto(
    HouseholdProfile from,
    String id, {
    String? name,
    String? countryCode,
    bool discardOwnRows = false,
  }) async {
    final moved = from.copyWith(id: id, name: name, countryCode: countryCode);
    if (id == from.id) return moved;

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
  }

  /// Drops the profile, putting the app back on the setup screen.
  ///
  /// For one case only: a join during first run that created the profile
  /// and then failed to attach it to the folder or the other device. The
  /// gate goes by the profile alone, so leaving it behind would let the
  /// app through into a household that is joined to nothing — with a
  /// fresh id that can never merge with the one it was meant to join.
  Future<void> forget() async {
    await _store.clear();
    state = const AsyncData(null);
  }

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
