import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/app_database_providers.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../model/household_profile.dart';
import '../../household/application/household_providers.dart';
import '../../sharing/application/device_snapshot.dart';
import '../../sharing/application/snapshot_exchange.dart';
import '../../sharing/application/shared_folder_store.dart';
import '../application/local_handover.dart';
import 'household_conflict_dialog.dart';
import '../application/qr_chain.dart';

/// Films the other device's screen until the household is in.
///
/// One screen for both roads, because the camera can tell them apart and
/// the person holding it should not have to. What it sees is either an
/// invitation — an address and a key, one code, done in a second — or the
/// first of a run of frames, in which case it settles in and collects
/// them.
///
/// What it shows is how far along it is, because without that somebody
/// holding a phone at a screen has no idea whether to keep holding it or
/// whether it is stuck.
class QrReceiveScreen extends ConsumerStatefulWidget {
  const QrReceiveScreen({
    super.key,
    required this.householdId,
    this.adoptHousehold = false,
  });

  /// The household this device belongs to. A snapshot from a different
  /// one is refused rather than merged: two households sharing rows by
  /// accident is not something a merge rule can undo afterwards.
  final String householdId;

  /// Take over the scanned household instead of refusing it.
  ///
  /// Set only by first-run setup, and the refusal above is exactly why:
  /// adopting means re-stamping every local row with somebody else's
  /// household id, which cannot be undone. On a device that was set up a
  /// minute ago there are no rows to re-stamp, so the move is free — and
  /// it is the only moment at which it is. See [SetupChoiceScreen].
  final bool adoptHousehold;

  @override
  ConsumerState<QrReceiveScreen> createState() => _QrReceiveScreenState();
}

class _QrReceiveScreenState extends ConsumerState<QrReceiveScreen> {
  final _receiver = QrChainReceiver();
  var _done = false;
  String? _result;
  bool _failed = false;

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_done) return;

    var changed = false;
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;
      if (value == null || value.isEmpty) continue;

      // The fast road first: an invitation is one code and ends the job
      // straight away, so it must not be fed to the chain collector.
      final invitation = LocalHandoverInvitation.decode(value);
      if (invitation != null) {
        _done = true;
        await _handover(invitation);
        return;
      }

      if (_receiver.take(value)) changed = true;
    }
    if (!changed) return;
    if (mounted) setState(() {});
    if (!_receiver.isComplete) return;

    _done = true;
    await _finish();
  }

  /// The row counts this device would be bringing along.
  Future<int> _ownRows() async => (await readHouseholdSnapshot(
    ref.read(appDatabaseProvider),
    deviceId: 'conflict',
    householdId: widget.householdId,
  )).rowCount;

  /// Settles a differing household, then returns the id to carry on with.
  ///
  /// Null means the person said no and nothing was touched.
  Future<String?> _resolve(String incoming) async {
    if (incoming == widget.householdId) return widget.householdId;

    // First run adopts without asking: the device has no rows of its own
    // yet, so there is nothing to weigh up and nothing to lose.
    if (widget.adoptHousehold) return _adopt(incoming);

    final profile = ref.read(householdProfileProvider).value;
    if (profile == null) return null;
    final rows = await _ownRows();
    if (!mounted) return null;
    final choice = await askAboutHouseholdConflict(
      context,
      mine: profile.name,
      rows: rows,
    );
    if (!mounted) return null;
    switch (choice) {
      case null:
      case HouseholdConflictChoice.keep:
        return null;
      case HouseholdConflictChoice.merge:
        return _adopt(incoming);
      case HouseholdConflictChoice.replace:
        // Deleted before the id moves, or the rows would travel along
        // under the new household and defeat the point of choosing this.
        await ref
            .read(appDatabaseProvider)
            .deleteHouseholdData(widget.householdId);
        return _adopt(incoming);
    }
  }

  /// Takes over [incoming] as this device's household.
  ///
  /// The same two steps `joinFolder` does for a shared folder: re-stamp
  /// the local rows, then move the profile onto the new id. Which
  /// warnings this device wants and how many people it plans for stay
  /// where they are — those belong to the device, not to the shared data.
  ///
  /// Returns the id to carry on with, which is the old one whenever
  /// there is nothing to adopt.
  Future<String> _adopt(String incoming) async {
    if (incoming == widget.householdId) return widget.householdId;
    final profile = ref.read(householdProfileProvider).value;
    if (profile == null) return widget.householdId;

    await ref
        .read(appDatabaseProvider)
        .adoptHouseholdId(from: profile.id, to: incoming);
    await ref
        .read(householdProfileProvider.notifier)
        .adopt(
          HouseholdProfile(
            id: incoming,
            name: profile.name,
            countryCode: profile.countryCode,
            regionKey: profile.regionKey,
            personCount: profile.personCount,
            children: profile.children,
            dogs: profile.dogs,
            cats: profile.cats,
            extraRegions: profile.extraRegions,
          ),
        );
    return incoming;
  }

  Future<void> _handover(LocalHandoverInvitation invitation) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {});
    try {
      final householdId = await _resolve(invitation.householdId);
      if (householdId == null) {
        if (!mounted) return;
        setState(() => _result = l10n.transferConflictCancelled);
        return;
      }
      final result = await joinLocalHandover(
        db: ref.read(appDatabaseProvider),
        deviceId: await const SharedFolderStore().deviceId(),
        householdId: householdId,
        invitation: invitation,
      );
      if (!mounted) return;
      setState(() {
        _result = result.received == 0
            ? l10n.transferHandoverNothing
            : l10n.transferHandoverDone(result.received);
      });
    } on LocalHandoverException catch (error) {
      if (!mounted) return;
      setState(() {
        _failed = true;
        _result = switch (error.reason) {
          LocalHandoverFailure.otherHousehold => l10n.transferWrongHousehold,
          LocalHandoverFailure.unreachable => l10n.transferUnreachable,
          LocalHandoverFailure.unreadable => l10n.transferBroken,
        };
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _failed = true;
        _result = l10n.transferBroken;
      });
    }
  }

  Future<void> _finish() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final bytes = _receiver.payload();
      if (bytes == null) return;

      final snapshot = DeviceSnapshot.decode(utf8.decode(bytes));
      if (snapshot == null) {
        setState(() {
          _failed = true;
          _result = l10n.transferBroken;
        });
        return;
      }
      final householdId = await _resolve(snapshot.householdId);
      if (!mounted) return;
      if (householdId == null) {
        setState(() => _result = l10n.transferConflictCancelled);
        return;
      }
      if (snapshot.householdId != householdId) {
        setState(() {
          _failed = true;
          _result = l10n.transferWrongHousehold;
        });
        return;
      }

      final rows = await applyHouseholdSnapshot(
        ref.read(appDatabaseProvider),
        snapshot,
      );
      if (!mounted) return;
      setState(() {
        _result = rows == 0 ? l10n.transferNothingNew : l10n.transferDone(rows);
      });
    } on Object {
      if (!mounted) return;
      // Anything that goes wrong here is the same thing to the person
      // holding the phone: the pictures did not add up, film them again.
      setState(() {
        _failed = true;
        _result = l10n.transferBroken;
      });
    }
  }

  void _again() {
    _receiver.reset();
    setState(() {
      _done = false;
      _failed = false;
      _result = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final total = _receiver.expected;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.transferReceiveTitle)),
      body: Column(
        children: [
          Expanded(
            child: _done
                ? Center(
                    child: Icon(
                      _failed ? Icons.error_outline : Icons.check_circle,
                      size: 72,
                      color: _failed
                          ? theme.colorScheme.error
                          : theme.colorScheme.primary,
                    ),
                  )
                : MobileScanner(onDetect: _onDetect),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_result case final result?) ...[
                  Text(
                    result,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  if (_failed)
                    FilledButton(
                      onPressed: _again,
                      child: Text(l10n.transferReceive),
                    )
                  else
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text(
                        MaterialLocalizations.of(context).okButtonLabel,
                      ),
                    ),
                ] else ...[
                  Text(l10n.transferReceiveHint, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  Text(
                    total == null
                        ? l10n.transferWaiting
                        : l10n.transferProgress(_receiver.received, total),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  // Indeterminate until the first frame says how many
                  // there are; a bar sitting at zero reads as broken.
                  LinearProgressIndicator(
                    value: total == null ? null : _receiver.progress,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
