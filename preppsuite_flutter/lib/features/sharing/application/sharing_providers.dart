import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_database_providers.dart';
import '../../../model/household_profile.dart';
import '../../household/application/household_providers.dart';
import 'household_file.dart';
import 'shared_folder_store.dart';
import 'shared_folder_sync_service.dart';
import 'sync_folder.dart';

/// Why a folder could not be joined.
enum SharedFolderJoinError {
  /// Picked, but not writable. On Android this is the common one: the
  /// picker hands back a path the app has no permission to use.
  unwritable,

  /// There is a `household.json` there, but it is damaged or was written
  /// by a newer version of the app.
  unreadable,
}

class SharedFolderState {
  const SharedFolderState({
    this.folderPath,
    this.lastSyncedAt,
    this.syncing = false,
    this.lastResult,
  });

  /// The folder this device shares through, or null when sharing is off.
  final String? folderPath;

  final DateTime? lastSyncedAt;
  final bool syncing;
  final SharedFolderSyncResult? lastResult;

  bool get isSharing => folderPath != null;

  SharedFolderState copyWith({
    String? folderPath,
    bool clearFolderPath = false,
    DateTime? lastSyncedAt,
    bool? syncing,
    SharedFolderSyncResult? lastResult,
  }) {
    return SharedFolderState(
      folderPath: clearFolderPath ? null : (folderPath ?? this.folderPath),
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      syncing: syncing ?? this.syncing,
      lastResult: lastResult ?? this.lastResult,
    );
  }
}

/// How often the app re-reads the folder while it is open.
///
/// Two minutes rather than seconds: the cloud engine underneath needs its
/// own time to move a file between devices, so polling faster would only
/// find the same files again. A run that finds nothing new writes nothing.
const sharedFolderSyncInterval = Duration(minutes: 2);

class SharedFolderController extends AsyncNotifier<SharedFolderState> {
  static const _store = SharedFolderStore();

  Timer? _timer;
  bool _syncing = false;

  @override
  Future<SharedFolderState> build() async {
    ref.onDispose(() => _timer?.cancel());

    final path = await _store.folderPath();
    final lastSynced = await ref
        .watch(appDatabaseProvider)
        .lastPulledAt(SharedFolderSyncService.syncStateEntity);

    _restartTimer(active: path != null);
    if (path != null) {
      // Deliberately after a beat and never awaited: the first sync must
      // not hold up whatever is waiting on this provider, and letting the
      // app finish starting first keeps it off the critical path.
      unawaited(Future.delayed(const Duration(milliseconds: 500), syncNow));
    }

    return SharedFolderState(folderPath: path, lastSyncedAt: lastSynced);
  }

  /// Points this device at [path], adopting whatever household is already
  /// there.
  ///
  /// Returns null on success. The adoption is the part worth reading
  /// twice: joining a folder that already belongs to a household re-stamps
  /// this device's rows with that household's id, because otherwise they
  /// would simply stop being visible — every table is partitioned by it.
  Future<SharedFolderJoinError?> joinFolder(
    String path, {
    required HouseholdProfile profile,
  }) async {
    final folder = IoSyncFolder(path);
    if (!await folder.isWritable()) return SharedFolderJoinError.unwritable;

    final raw = await folder.readHouseholdFile();
    if (raw == null) {
      await folder.writeHouseholdFile(_identityOf(profile).encode());
    } else {
      final existing = HouseholdFile.decode(raw);
      if (existing == null) return SharedFolderJoinError.unreadable;

      if (existing.householdId != profile.id) {
        await ref
            .read(appDatabaseProvider)
            .adoptHouseholdId(from: profile.id, to: existing.householdId);
        await ref
            .read(householdProfileProvider.notifier)
            .adopt(
              HouseholdProfile(
                id: existing.householdId,
                name: existing.name,
                countryCode: existing.countryCode,
                // Kept local on purpose: which warnings this device wants and
                // how many people it plans for are properties of the device
                // and the person holding it, not of the shared data.
                regionKey: profile.regionKey,
                personCount: profile.personCount,
                extraRegions: profile.extraRegions,
              ),
            );
      }
    }

    await _store.saveFolderPath(path);
    state = AsyncData(
      (state.value ?? const SharedFolderState()).copyWith(folderPath: path),
    );
    _restartTimer(active: true);
    await syncNow();
    return null;
  }

  /// Stops sharing on this device.
  ///
  /// The snapshot stays in the folder. Removing it would delete this
  /// device's rows from everyone else's next merge, which is not what
  /// "stop syncing my phone" means.
  Future<void> leaveFolder() async {
    await _store.clearFolderPath();
    _restartTimer(active: false);
    state = AsyncData(
      (state.value ?? const SharedFolderState()).copyWith(
        clearFolderPath: true,
      ),
    );
  }

  /// Reads the folder path from preferences rather than from [state], so
  /// this works before the provider has finished building — the first
  /// sync of a launch happens while the rest of the app is still starting.
  Future<void> syncNow() async {
    if (_syncing) return;

    final path = await _store.folderPath();
    if (path == null) return;

    final profile = ref.read(householdProfileProvider).value;
    if (profile == null) return;

    _syncing = true;
    _update((current) => current.copyWith(syncing: true));
    try {
      final service = SharedFolderSyncService(
        database: ref.read(appDatabaseProvider),
        folder: IoSyncFolder(path),
        deviceId: await _store.deviceId(),
        identity: _identityOf(profile),
      );
      final result = await service.sync();

      if (!ref.mounted) return;
      _update(
        (current) => current.copyWith(
          syncing: false,
          lastResult: result,
          lastSyncedAt: result.succeeded
              ? DateTime.now().toUtc()
              : current.lastSyncedAt,
        ),
      );
    } finally {
      _syncing = false;
    }
  }

  /// No-op while the provider is still building. The sync itself has
  /// already happened by then; only the line in settings is a beat behind.
  void _update(SharedFolderState Function(SharedFolderState) change) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(change(current));
  }

  /// The identity file this device would write for [profile].
  ///
  /// `createdAt` is only ever informational — a repair write stamps the
  /// moment of the repair rather than pretending to know when the folder
  /// was first set up.
  HouseholdFile _identityOf(HouseholdProfile profile) => HouseholdFile(
    householdId: profile.id,
    name: profile.name,
    countryCode: profile.countryCode,
    createdAt: DateTime.now().toUtc(),
  );

  void _restartTimer({required bool active}) {
    _timer?.cancel();
    _timer = active
        ? Timer.periodic(sharedFolderSyncInterval, (_) => syncNow())
        : null;
  }
}

final sharedFolderProvider =
    AsyncNotifierProvider<SharedFolderController, SharedFolderState>(
      SharedFolderController.new,
    );
