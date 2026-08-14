import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:preppsuite_client/preppsuite_client.dart'
    show Warning, WarningSeverity;

import '../../../core/notification_service.dart';
import '../../../core/notifications_provider.dart';
import 'warning_providers.dart';
import 'warning_severity_l10n.dart';

/// Pull-only sync — there's no local write path to debounce after (see
/// `SyncService.syncWarnings`), just the immediate + 60s periodic cadence
/// shared with the other entities' sync controllers.
class WarningSyncController extends Notifier<AsyncValue<void>> {
  WarningSyncController(this.householdId);

  final String householdId;

  Timer? _periodicTimer;

  @override
  AsyncValue<void> build() {
    ref.onDispose(() => _periodicTimer?.cancel());
    _periodicTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => syncNow(),
    );
    Future.microtask(syncNow);
    return const AsyncData(null);
  }

  Future<void> syncNow() async {
    try {
      final changes = await ref
          .read(syncServiceProvider)
          .syncWarnings(householdId);
      await _notifyIfEnabled(changes);
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  /// Only notifies for moderate-or-above warnings — a constant stream of
  /// "minor" notifications would just train people to ignore them, working
  /// against the point of a warning notification.
  Future<void> _notifyIfEnabled(List<Warning> changes) async {
    if (changes.isEmpty) return;
    if (!ref.read(notificationsEnabledProvider)) return;

    final minRank = warningSeverityRank(WarningSeverity.moderate);
    for (final warning in changes) {
      if (warningSeverityRank(warning.severity) < minRank) continue;
      await NotificationService.instance.showWarningNotification(warning);
    }
  }
}

final warningSyncControllerProvider =
    NotifierProvider.family<WarningSyncController, AsyncValue<void>, String>(
      WarningSyncController.new,
    );
