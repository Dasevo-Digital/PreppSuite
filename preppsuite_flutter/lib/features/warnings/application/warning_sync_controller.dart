import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../model/household_profile.dart';

import '../../../core/app_database_providers.dart';
import '../../../core/notification_service.dart';
import '../../../core/notifications_provider.dart';
import 'warning_background_worker.dart';
import 'warning_poll_service.dart';
import 'warning_region_filter.dart';
import 'warning_region_store.dart';
import 'warning_relevance.dart';
import 'warning_freshness.dart';

final warningPollServiceProvider = Provider<WarningPollService>((ref) {
  return WarningPollService(database: ref.watch(appDatabaseProvider));
});

/// Fetches the warning feeds while a screen is open, and keeps the
/// background worker's view of the world current.
///
/// There is no push or pull any more — the app talks to BBK and MeteoAlarm
/// directly. This runs the same [WarningPollService] the background worker
/// runs; the difference is only who scheduled it.
class WarningSyncController extends Notifier<AsyncValue<void>> {
  WarningSyncController(this.profile);

  final HouseholdProfile profile;

  @override
  AsyncValue<void> build() {
    // Registering and cancelling both have to follow the switch, not just
    // its first value — see `ensureLoaded` for why that first value lies
    // for one turn of the event loop.
    ref.listen(notificationsEnabledProvider, (_, enabled) {
      _applyBackgroundSchedule(enabled);
    });
    Future.microtask(() async {
      await ref.read(notificationsEnabledProvider.notifier).ensureLoaded();
      if (!ref.mounted) return;
      await _applyBackgroundSchedule(ref.read(notificationsEnabledProvider));
    });

    Future.microtask(syncNow);
    return const AsyncData(null);
  }

  Future<void> syncNow() async {
    try {
      final filter = _currentFilter();
      // Written on every pass, so the background isolate — which cannot
      // ask anyone anything — always polls for the region the user most
      // recently had.
      await const WarningRegionStore().save(filter);

      final service = ref.read(warningPollServiceProvider);
      await service.poll(
        countryCode: filter.countryCode,
        kreisSchluessel: filter.ownKreisSchluessel,
        extraKreisSchluessel: [
          for (final region in filter.extraRegions)
            if (region.kind == WarningRegionKind.kreis) region.value,
        ],
      );
      await _notifyIfEnabled(service, filter);
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    } finally {
      // Every attempt, answered or not, moves how old the warnings are
      // (#138).
      if (ref.mounted) ref.invalidate(warningPollStatusProvider);
    }
  }

  WarningRegionFilter _currentFilter() => profile.warningFilter;

  /// Announces only warnings that concern this household's region — the
  /// same relevance rule the list view sorts by, and the same one the
  /// background worker applies.
  Future<void> _notifyIfEnabled(
    WarningPollService service,
    WarningRegionFilter filter,
  ) async {
    if (!ref.read(notificationsEnabledProvider)) return;

    final pending = await service.pendingNotifications(
      isRelevant: (warning) =>
          isWarningRelevant(warning: warning, filter: filter),
    );
    if (pending.isEmpty) return;

    for (final warning in pending) {
      await NotificationService.instance.showLocalWarning(warning);
    }
    await service.markNotified(pending);
  }

  /// Keeps the periodic background poll in step with the setting. Polling
  /// on a schedule whose results nobody will see is just battery.
  Future<void> _applyBackgroundSchedule(bool enabled) async {
    if (!supportsBackgroundWarningPolling) return;
    if (enabled) {
      await scheduleWarningPolling();
    } else {
      await cancelWarningPolling();
    }
  }
}

final warningSyncControllerProvider =
    NotifierProvider.family<
      WarningSyncController,
      AsyncValue<void>,
      HouseholdProfile
    >(
      WarningSyncController.new,
    );
