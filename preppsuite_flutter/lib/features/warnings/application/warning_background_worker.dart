import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

import '../../../core/notification_service.dart';
import '../../../core/notifications_provider.dart';
import '../../../local_db/database.dart';
import 'warning_poll_service.dart';
import 'warning_region_store.dart';
import 'warning_relevance.dart';

/// Whether this platform has a background scheduler worth registering
/// with.
///
/// Android runs the poll on a real periodic schedule. iOS maps it to
/// BGAppRefreshTask, which the system runs when it judges the moment
/// right — that can be hours, so it is a bonus rather than a guarantee and
/// the app does not present it as one. Desktop has no scheduler at all and
/// does not need one: a desktop app that is running polls anyway, and one
/// that is closed cannot be woken.
bool get supportsBackgroundWarningPolling {
  if (kIsWeb) return false;
  return Platform.isAndroid || Platform.isIOS;
}

/// Task name registered with the platform scheduler.
const warningPollTaskName = 'preppsuite.warningPoll';
const _warningPollTaskId = 'preppsuite.warningPoll.periodic';

/// How often the platform is asked to run the poll.
///
/// Fifteen minutes is Android's floor for periodic work, not a preference —
/// WorkManager silently rounds anything shorter up to it. The system is
/// free to run it later than this, and on iOS it decides entirely on its
/// own.
const warningPollInterval = Duration(minutes: 15);

/// Entry point for the background isolate.
///
/// Must be a top-level function annotated for AOT retention, or the
/// release build tree-shakes it away and the task silently never runs.
@pragma('vm:entry-point')
void warningCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) => runWarningBackgroundPoll());
}

/// Polls the warning feeds and notifies, without any of the app running.
///
/// This isolate has no Riverpod container, no widget tree and no household
/// fetched from anywhere — everything it needs comes from preferences and
/// the local database. It returns false only on failure, so the platform
/// can decide whether to retry.
Future<bool> runWarningBackgroundPoll({
  AppDatabase? database,
  WarningRegionStore regionStore = const WarningRegionStore(),
  NotificationService? notifications,
  WarningPollService? pollService,
}) async {
  // The isolate starts bare; plugins are unusable until this runs.
  WidgetsFlutterBinding.ensureInitialized();

  final filter = await regionStore.load();
  // Nothing set up yet — no household, no region, nothing to poll for.
  if (filter == null) return true;

  if (!await const NotificationsEnabledStore().isEnabled()) {
    // The user switched notifications off. Polling anyway would spend
    // their battery and data on something they asked not to be told.
    return true;
  }

  // Opened here rather than shared with the UI isolate: when the app is
  // closed there is nothing to share with, and when it is open SQLite's
  // own locking keeps the two consistent. The cost is that the UI does not
  // see these writes until it queries again, which it does on every open.
  final db = database ?? AppDatabase();
  final service = pollService ?? WarningPollService(database: db);
  final notifier = notifications ?? NotificationService.instance;

  try {
    await service.poll(
      countryCode: filter.countryCode,
      kreisSchluessel: filter.ownKreisSchluessel,
    );

    final pending = await service.pendingNotifications(
      isRelevant: (warning) =>
          isWarningRelevant(warning: warning, filter: filter),
    );
    for (final warning in pending) {
      await notifier.showLocalWarning(warning);
    }
    await service.markNotified(pending);
    return true;
  } catch (_) {
    // A failed poll is not worth a retry storm: the next scheduled run is
    // at most fifteen minutes away, and the feeds are frequently briefly
    // unreachable.
    return true;
  } finally {
    if (database == null) await db.close();
  }
}

/// Registers the periodic poll, replacing any earlier registration.
///
/// Idempotent, so it is safe to call on every launch — which is what keeps
/// the schedule alive after a reinstall or an OS update that cleared it.
Future<void> scheduleWarningPolling() async {
  await Workmanager().initialize(warningCallbackDispatcher);
  await Workmanager().registerPeriodicTask(
    _warningPollTaskId,
    warningPollTaskName,
    frequency: warningPollInterval,
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    constraints: Constraints(networkType: NetworkType.connected),
  );
}

/// Stops the periodic poll — called when the user switches notifications
/// off, so the app stops spending battery on something nobody will see.
Future<void> cancelWarningPolling() async {
  await Workmanager().cancelByUniqueName(_warningPollTaskId);
}
