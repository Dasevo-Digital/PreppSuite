import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'warning_providers.dart';

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
      await ref.read(syncServiceProvider).syncWarnings(householdId);
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }
}

final warningSyncControllerProvider = NotifierProvider.family<
  WarningSyncController,
  AsyncValue<void>,
  String
>(WarningSyncController.new);
