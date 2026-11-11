import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart' show protected, visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_database_providers.dart';
import '../../../model/household_profile.dart';
import '../../household/application/household_providers.dart';
import 'folder_encryption.dart';
import 'household_file.dart';
import 'shared_folder_access.dart';
import 'shared_folder_store.dart';
import 'folder_key_store.dart';
import 'shared_folder_sync_service.dart';

/// Why a folder could not be joined.
enum SharedFolderJoinError {
  /// Picked, but not writable — a read-only location, or a drive that is
  /// no longer there.
  unwritable,

  /// Devices have written here, but the folder's identity file cannot be
  /// read at the moment.
  incomplete,

  /// There is a `household.json` there, but it is damaged or was written
  /// by a newer version of the app.
  unreadable,

  /// The folder is empty, and this household has been shared encrypted
  /// before. It is founded sealed, which takes a password: ask for one
  /// and join again with it (#214). Until then this came back as
  /// [unreadable], saying a household was there when nothing was.
  needsPassphrase,

  /// The folder holds a household in the clear, and this one is shared
  /// encrypted. Its rows would land there unsealed, so nothing is joined.
  notEncrypted,
}

class SharedFolderState {
  const SharedFolderState({
    this.folder,
    this.lastSyncedAt,
    this.syncing = false,
    this.lastResult,
  });

  /// The folder this device shares through, or null when sharing is off.
  final SharedFolderLocation? folder;

  final DateTime? lastSyncedAt;
  final bool syncing;
  final SharedFolderSyncResult? lastResult;

  bool get isSharing => folder != null;

  SharedFolderState copyWith({
    SharedFolderLocation? folder,
    bool clearFolder = false,
    DateTime? lastSyncedAt,
    bool? syncing,
    SharedFolderSyncResult? lastResult,
  }) {
    return SharedFolderState(
      folder: clearFolder ? null : (folder ?? this.folder),
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

  /// The run under way, for [leaveFolder] and for any request that comes
  /// in meanwhile to wait for.
  Completer<void>? _running;

  /// Requests that came in while a run was under way: one more run after
  /// it, which writes this device's file regardless when any of them
  /// asked for that.
  Completer<void>? _queued;
  bool _queuedRepublish = false;

  @override
  Future<SharedFolderState> build() async {
    ref.onDispose(() => _timer?.cancel());

    final folder = await _store.location();
    final lastSynced = await ref
        .watch(appDatabaseProvider)
        .lastPulledAt(SharedFolderSyncService.syncStateEntity);

    _restartTimer(active: folder != null);
    if (folder != null) {
      // Deliberately after a beat and never awaited: the first sync must
      // not hold up whatever is waiting on this provider, and letting the
      // app finish starting first keeps it off the critical path.
      unawaited(Future.delayed(const Duration(milliseconds: 500), syncNow));
    }

    return SharedFolderState(folder: folder, lastSyncedAt: lastSynced);
  }

  /// Points this device at [path], adopting whatever household is already
  /// there.
  ///
  /// Returns null on success. The adoption is the part worth reading
  /// twice: joining a folder that already belongs to a household re-stamps
  /// this device's rows with that household's id, because otherwise they
  /// would simply stop being visible — every table is partitioned by it.
  ///
  /// [discardOwnRows] is the answer "replace" to the conflict question:
  /// this device's rows are deleted instead of re-stamped — but only once
  /// the folder has been checked and is known to hold a household, so a
  /// join that fails leaves them where they were.
  ///
  /// [passphrase] is the answer to [SharedFolderJoinError.needsPassphrase]
  /// and is used for nothing else.
  Future<SharedFolderJoinError?> joinFolder(
    SharedFolderLocation location, {
    required HouseholdProfile profile,
    bool discardOwnRows = false,
    String? passphrase,
  }) async {
    final folder = syncFolderFor(location.value);
    if (!await folder.isWritable()) return SharedFolderJoinError.unwritable;

    final String? raw;
    try {
      raw = await folder.readHouseholdFile();
    } on Object {
      return SharedFolderJoinError.incomplete;
    }
    if (raw == null) {
      // Devices have written here, so the folder is not empty, whatever
      // the read said: a cloud folder still loading, a placeholder. A new
      // identity would strand them all, and in a sealed folder it would
      // take the salt with it (#312).
      if ((await folder.listDeviceIds()).isNotEmpty) {
        return SharedFolderJoinError.incomplete;
      }
      if (await const FolderKeyStore().requiresEncryption(profile.id)) {
        if (passphrase == null) return SharedFolderJoinError.needsPassphrase;
        final error = await FolderEncryption(
          folder: folder,
        ).found(identity: _identityOf(profile), passphrase: passphrase);
        if (error != null) return SharedFolderJoinError.unwritable;
      } else {
        await folder.writeHouseholdFile(_identityOf(profile).encode());
      }
    } else {
      final existing = HouseholdFile.decode(raw);
      if (existing == null) return SharedFolderJoinError.unreadable;
      if (!existing.isEncrypted &&
          await const FolderKeyStore().requiresEncryption(
            existing.householdId,
          )) {
        return SharedFolderJoinError.notEncrypted;
      }
      if (existing.isEncrypted) {
        await const FolderKeyStore().rememberEncryption(existing.householdId);
      }

      if (existing.householdId != profile.id) {
        await ref
            .read(householdProfileProvider.notifier)
            .moveInto(
              profile,
              existing.householdId,
              name: existing.name,
              countryCode: existing.countryCode,
              discardOwnRows: discardOwnRows,
            );
      }
    }

    await _store.saveLocation(location);
    state = AsyncData(
      (state.value ?? const SharedFolderState()).copyWith(folder: location),
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
  ///
  /// Waits for a run under way. "Delete household" leaves first, and a run
  /// that went on after it had deleted the rows wrote the empty household
  /// over this device's file (#336).
  Future<void> leaveFolder() async {
    await _store.clearLocation();
    _restartTimer(active: false);
    await _running?.future;
    state = AsyncData(
      (state.value ?? const SharedFolderState()).copyWith(clearFolder: true),
    );
  }

  /// Reads the folder path from preferences rather than from [state], so
  /// this works before the provider has finished building — the first
  /// sync of a launch happens while the rest of the app is still starting.
  /// [republish] writes this device's file even when nothing changed —
  /// for the run right after encryption is switched on, when the file
  /// already there is still in the clear.
  ///
  /// One run at a time (#370). The run used to count as under way only
  /// after the folder path had been read, so the return to the app, the
  /// two-minute timer and the button could start two at once. Both wrote
  /// this device's file through the same temporary name, the first to end
  /// cleared what [leaveFolder] waits for while the second still ran, and
  /// a request to republish that came during a run was dropped. Now a
  /// request during a run is one more run after it, and every caller
  /// waits for the run that covers its request.
  Future<void> syncNow({bool republish = false}) {
    if (_running != null) {
      _queuedRepublish = _queuedRepublish || republish;
      return (_queued ??= Completer<void>()).future;
    }
    return _run(republish);
  }

  Future<void> _run(bool republish) async {
    // Before the first await, so that nothing can start beside it and
    // [leaveFolder] sees it from the first moment.
    final running = _running = Completer<void>();
    try {
      await runSync(republish: republish);
    } finally {
      _running = null;
      running.complete();
      final queued = _queued;
      if (queued != null) {
        final again = _queuedRepublish;
        _queued = null;
        _queuedRepublish = false;
        if (ref.mounted) {
          unawaited(_run(again).whenComplete(queued.complete));
        } else {
          queued.complete();
        }
      }
    }
  }

  /// One run: read the folder, merge, write. Only [syncNow] calls it.
  @protected
  @visibleForTesting
  Future<void> runSync({required bool republish}) async {
    final folder = await _store.location();
    if (folder == null) return;

    final profile = ref.read(householdProfileProvider).value;
    if (profile == null) return;

    _update((current) => current.copyWith(syncing: true));
    var reported = false;
    try {
      final service = await _serviceFor(folder, profile, republish);
      final result = service == null
          ? const SharedFolderSyncResult(error: SharedFolderSyncError.failed)
          : await service.sync();

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
      reported = true;
    } finally {
      if (!reported && ref.mounted) {
        _update((current) => current.copyWith(syncing: false));
      }
    }
  }

  /// Everything the run needs that is read before it starts.
  ///
  /// Null when any of it cannot be read — a keychain that is locked, a
  /// preferences file that is not there. That used to throw out of
  /// [syncNow] past the line that clears `syncing`, so the settings card
  /// said "syncing" from then on, and out of a timer callback, where
  /// nothing caught it at all.
  Future<SharedFolderSyncService?> _serviceFor(
    SharedFolderLocation folder,
    HouseholdProfile profile,
    bool republish,
  ) async {
    try {
      return SharedFolderSyncService(
        database: ref.read(appDatabaseProvider),
        folder: syncFolderFor(folder.value),
        deviceId: await _store.deviceId(),
        identity: _identityOf(profile),
        // Null for a plain folder and for one this device has not been
        // unlocked for; the service turns the second case into
        // SharedFolderSyncError.locked rather than writing in the clear.
        key: await const FolderKeyStore().read(profile.id),
        requireEncryption: await const FolderKeyStore().requiresEncryption(
          profile.id,
        ),
        onEncryptedFolder: () =>
            const FolderKeyStore().rememberEncryption(profile.id),
        republish: republish,
      );
    } on Object catch (error, stack) {
      developer.log(
        'shared folder sync could not start',
        name: 'preppsuite.sharing',
        error: error,
        stackTrace: stack,
      );
      return null;
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
