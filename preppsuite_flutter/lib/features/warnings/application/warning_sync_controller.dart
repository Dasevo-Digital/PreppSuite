import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:preppsuite_client/preppsuite_client.dart'
    show Household, WarningRegionSubscription;

import '../../../core/app_database_providers.dart';
import '../../../core/notification_service.dart';
import '../../../core/notifications_provider.dart';
import 'warning_poll_service.dart';
import 'warning_relevance.dart';

final warningPollServiceProvider = Provider<WarningPollService>((ref) {
  return WarningPollService(database: ref.watch(appDatabaseProvider));
});

/// Fetches the warning feeds and announces what is new.
///
/// There is no push or pull any more — the app talks to BBK and MeteoAlarm
/// directly. The name stays because this is still the thing that keeps the
/// local warning table current while a screen is open; the Android
/// background worker runs the same [WarningPollService] on its own
/// schedule.
class WarningSyncController extends Notifier<AsyncValue<void>> {
  WarningSyncController(this.household);

  final Household household;

  @override
  AsyncValue<void> build() {
    Future.microtask(syncNow);
    return const AsyncData(null);
  }

  Future<void> syncNow() async {
    try {
      final service = ref.read(warningPollServiceProvider);
      await service.poll(
        countryCode: household.countryCode,
        kreisSchluessel: household.regionKey,
      );
      await _notifyIfEnabled(service);
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  /// Announces only warnings that concern this household's region — the
  /// same relevance rule the list view sorts by.
  Future<void> _notifyIfEnabled(WarningPollService service) async {
    if (!ref.read(notificationsEnabledProvider)) return;

    const subscriptions = <WarningRegionSubscription>[];
    final pending = await service.pendingNotifications(
      isRelevant: (warning) => isWarningRelevant(
        warning: warning,
        household: household,
        subscriptions: subscriptions,
      ),
    );
    if (pending.isEmpty) return;

    for (final warning in pending) {
      await NotificationService.instance.showLocalWarning(warning);
    }
    await service.markNotified(pending);
  }
}

final warningSyncControllerProvider =
    NotifierProvider.family<WarningSyncController, AsyncValue<void>, Household>(
      WarningSyncController.new,
    );
