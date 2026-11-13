import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_database_providers.dart';
import '../../../core/notification_service.dart';
import '../../../model/household_profile.dart';
import '../../inventory/presentation/inventory_item_form_screen.dart';
import '../../knowledge/presentation/personal_documents_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../application/notification_target.dart';
import '../application/shell_layout.dart';

/// Takes a tapped notification to its page (#382). Draws nothing.
///
/// A tap used to open the app and leave it where it was: "time for a
/// backup" on the overview, "the rice expires" with no rice in sight. Built
/// like `AppShortcuts`, beside it in the shell: a tap while the app runs
/// arrives from the stream, and the one that started it is asked for once.
class NotificationTaps extends ConsumerStatefulWidget {
  const NotificationTaps({
    super.key,
    required this.profile,
    required this.onNavigate,
    required this.screenFor,
    this.taps,
    this.launchPayload,
  });

  final HouseholdProfile profile;

  /// Switches the shell to a tab, when nothing is open above it.
  final void Function(ShellDestination destination) onNavigate;

  /// The tab's screen on its own, for when a page is open above the
  /// shell: switching beneath it would show nothing, and closing it could
  /// throw away an edit somebody was in the middle of.
  final Widget Function(ShellDestination destination) screenFor;

  /// Injectable for tests; the notification service's by default.
  final Stream<String>? taps;
  final Future<String?> Function()? launchPayload;

  @override
  ConsumerState<NotificationTaps> createState() => _NotificationTapsState();
}

class _NotificationTapsState extends ConsumerState<NotificationTaps> {
  StreamSubscription<String>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = (widget.taps ?? NotificationService.instance.taps).listen(
      _open,
    );
    final launch =
        widget.launchPayload ?? NotificationService.instance.takeLaunchPayload;
    unawaited(
      launch().then((payload) {
        if (payload == null || !mounted) return;
        // After the next frame: the shell may still be laid out when a
        // start from a notification gets here. Asked for, since a shell
        // that has settled draws no frame of its own accord.
        WidgetsBinding.instance
          ..addPostFrameCallback((_) => _open(payload))
          ..scheduleFrame();
      }),
    );
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  Future<void> _open(String payload) async {
    if (!mounted) return;
    final target = notificationTargetFor(payload);
    if (target == null) return;
    final navigator = Navigator.of(context);
    void push(Widget page) =>
        navigator.push(MaterialPageRoute<void>(builder: (_) => page));

    switch (target) {
      case NotificationTab(:final destination):
        if (navigator.canPop()) {
          push(widget.screenFor(destination));
        } else {
          widget.onNavigate(destination);
        }
      case NotificationBackup():
        SettingsScreen.openDataCategory(context, widget.profile);
      case NotificationDocuments():
        push(const PersonalDocumentsScreen());
      case NotificationItem(:final clientId):
        final householdId = widget.profile.id;
        final rows = await ref
            .read(appDatabaseProvider)
            .inventoryItemsForSync(householdId);
        if (!mounted) return;
        final item = rows
            .where((row) => row.clientId == clientId && row.deletedAt == null)
            .firstOrNull;
        if (item == null) {
          // Used up or deleted since the reminder was planned: the stock
          // is the nearest thing to it.
          if (navigator.canPop()) {
            push(widget.screenFor(ShellDestination.inventory));
          } else {
            widget.onNavigate(ShellDestination.inventory);
          }
          return;
        }
        push(InventoryItemFormScreen(householdId: householdId, existing: item));
    }
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
