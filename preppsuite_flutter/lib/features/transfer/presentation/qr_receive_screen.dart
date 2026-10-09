import 'dart:async' show unawaited;
import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../core/feel.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/app_database_providers.dart';
import '../../../core/camera_unavailable.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../household/application/household_providers.dart';
import '../../sharing/application/carried_settings.dart';
import '../../sharing/application/snapshot_exchange.dart';
import '../../sharing/application/settings_sync_store.dart';
import '../../sharing/application/shared_folder_store.dart';
import '../application/handover_payload.dart';
import '../application/local_handover.dart';
import 'household_conflict_dialog.dart';
import '../application/qr_chain.dart';

/// Where a transfer carries on: the household id, and whether this
/// device's own rows are discarded on the way rather than re-stamped.
typedef _Move = ({String id, bool discard});

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
  /// The camera, told what it is actually being pointed at.
  ///
  /// The default is [DetectionSpeed.normal], which ignores everything for
  /// 250 ms after each read — a sensible default for a till, where the
  /// same barcode sits in front of the lens and the saving is memory on
  /// an old phone. This screen is the opposite case: the thing being
  /// filmed is a *run* of different codes, each on screen for about half
  /// a second, and every one of them has to be caught. Throttling to one
  /// look per 250 ms leaves roughly two chances per frame instead of the
  /// fifteen the camera actually offers, and a frame missed on every pass
  /// is a transfer that sits at "1 von 18" for ever.
  ///
  /// The screen lives for seconds and holds one small collector, so the
  /// memory the default protects is not at stake here.
  final _scanner = MobileScannerController(
    detectionSpeed: DetectionSpeed.unrestricted,
    formats: const [BarcodeFormat.qrCode],
  );

  final _receiver = QrChainReceiver();
  var _done = false;
  String? _result;
  bool _failed = false;

  /// How many rows arrived, once something did.
  ///
  /// Handed back when the screen closes, because the caller is the one
  /// that has to say so: during first-run setup this screen is two routes
  /// deep, and "it worked" has to survive both of them being popped.
  int? _rows;

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_done) return;

    // Which picture was last read, so the screen can move even when the
    // count does not. Without it a stuck run says "1 von 18" and nothing
    // else, and the two ways it can be stuck look identical.
    final before = _receiver.lastSeen;
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
    // A camera reading the same picture thirty times a second must not
    // rebuild the screen thirty times a second, so this redraws when
    // something actually moved: a new frame, or a different one in view.
    if (!changed && _receiver.lastSeen == before) return;
    if (mounted) setState(() {});
    if (!_receiver.isComplete) return;

    _done = true;
    // Both hands are holding phones up against each other and the eyes
    // are on the other one's screen. This is the moment to stop.
    Feel.arrived();
    await _finish();
  }

  /// The row counts this device would be bringing along.
  Future<int> _ownRows() async => (await readHouseholdSnapshot(
    ref.read(appDatabaseProvider),
    deviceId: 'conflict',
    householdId: widget.householdId,
  )).rowCount;

  /// Settles a differing household, then says where to carry on.
  ///
  /// Null means the person said no and nothing was touched. Nothing is
  /// touched on a yes either: the move happens in [_moveInto], once the
  /// caller knows when it is safe to.
  Future<_Move?> _resolve(String incoming) async {
    if (incoming == widget.householdId) {
      return (id: widget.householdId, discard: false);
    }

    // First run adopts without asking: the device has no rows of its own
    // yet, so there is nothing to weigh up and nothing to lose.
    if (widget.adoptHousehold) return (id: incoming, discard: false);

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
    return switch (choice) {
      null || HouseholdConflictChoice.keep => null,
      HouseholdConflictChoice.merge => (id: incoming, discard: false),
      HouseholdConflictChoice.replace => (id: incoming, discard: true),
    };
  }

  /// Takes over [move] as this device's household.
  ///
  /// This device keeps its own name for the household — the other one's
  /// arrives with [_adoptSetup] on first run, where there is no name yet
  /// worth keeping.
  Future<void> _moveInto(_Move move) async {
    if (move.id == widget.householdId) return;
    final profile = ref.read(householdProfileProvider).value;
    if (profile == null) return;
    await ref
        .read(householdProfileProvider.notifier)
        .moveInto(profile, move.id, discardOwnRows: move.discard);
  }

  /// Sets this device up the way the other one is.
  ///
  /// First run only, and the restriction is the same one that governs
  /// adopting the household id: on a device that has been in use, copying
  /// somebody else's region, energy plan and reminder settings over its
  /// own would be a silent loss rather than a convenience. On a device
  /// that was created a minute ago there is nothing underneath.
  ///
  /// The profile is written last and deliberately with [householdId]
  /// rather than the id that came in the file: the two agree by now, and
  /// if they ever did not, the one this device has already re-stamped
  /// every row with is the one that must win.
  Future<void> _adoptSetup(String householdId, CarriedHousehold carried) async {
    if (carried.isEmpty) return;
    await applyCarriedSettings(carried.settings);

    final theirs = carried.profile;
    if (theirs == null || !mounted) return;
    await ref
        .read(householdProfileProvider.notifier)
        .adopt(theirs.copyWith(id: householdId));
  }

  Future<void> _handover(LocalHandoverInvitation invitation) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {});
    try {
      final move = await _resolve(invitation.householdId);
      if (move == null) {
        if (!mounted) return;
        setState(() => _result = l10n.transferConflictCancelled);
        return;
      }
      final householdId = move.id;
      // Merging has to move first: what this device offers is read under
      // the new id, so its rows must already be there. That costs nothing
      // if the handover then fails — they are re-stamped, not gone.
      //
      // Replacing waits until the other device's rows are in. Its offer is
      // read under the new id too, where this device holds nothing, so
      // none of what it is about to discard goes across — and nothing is
      // discarded for a handover that never arrived.
      if (!move.discard) await _moveInto(move);
      final result = await joinLocalHandover(
        db: ref.read(appDatabaseProvider),
        deviceId: await const SharedFolderStore().deviceId(),
        householdId: householdId,
        invitation: invitation,
      );
      if (move.discard) await _moveInto(move);
      if (widget.adoptHousehold) {
        await _adoptSetup(householdId, result.household);
      }
      if (!mounted) return;
      setState(() {
        _rows = result.received;
        final rows = result.received == 0
            ? l10n.transferHandoverNothing
            : l10n.transferHandoverDone(result.received);
        _result = result.photos == 0
            ? rows
            : '$rows ${l10n.transferHandoverPhotos(result.photos)}';
      });
    } on LocalHandoverException catch (error) {
      if (!mounted) return;
      setState(() {
        _failed = true;
        _result = switch (error.reason) {
          LocalHandoverFailure.otherHousehold => l10n.transferWrongHousehold,
          LocalHandoverFailure.unreachable => l10n.transferUnreachable,
          LocalHandoverFailure.unreadable => l10n.transferBroken,
          // Not the same sentence as unreachable on purpose: that one
          // sends somebody to look at their wifi, and here the wifi is
          // demonstrably fine.
          LocalHandoverFailure.interrupted => l10n.transferInterrupted,
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

      final payload = HandoverPayload.decode(utf8.decode(bytes));
      final snapshot = payload?.snapshot;
      if (payload == null || snapshot == null) {
        setState(() {
          _failed = true;
          _result = l10n.transferBroken;
        });
        return;
      }
      final move = await _resolve(snapshot.householdId);
      if (!mounted) return;
      if (move == null) {
        setState(() => _result = l10n.transferConflictCancelled);
        return;
      }
      final householdId = move.id;
      if (snapshot.householdId != householdId) {
        setState(() {
          _failed = true;
          _result = l10n.transferWrongHousehold;
        });
        return;
      }

      // Applied before the move, for the same reason as the handover's
      // replace: the rows land under the new id either way, and a device
      // that is told to discard its own has the others' in hand first.
      final rows = await applyHouseholdSnapshot(
        ref.read(appDatabaseProvider),
        snapshot,
      );
      await _moveInto(move);
      await applySyncedSettings(snapshot.settings);
      // No photographs on this road — see `handover_payload.dart` — but
      // the settings fit, and a device being set up should not have to
      // type them again.
      if (widget.adoptHousehold) {
        await _adoptSetup(householdId, payload.household);
      }
      if (!mounted) return;
      setState(() {
        _rows = rows;
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

  @override
  void dispose() {
    // Ours to make, ours to close: a controller handed to [MobileScanner]
    // is not disposed by it.
    unawaited(_scanner.dispose());
    super.dispose();
  }

  void _again() {
    _receiver.reset();
    setState(() {
      _done = false;
      _failed = false;
      _result = null;
      _rows = null;
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
                : MobileScanner(
                    controller: _scanner,
                    onDetect: _onDetect,
                    errorBuilder: (context, error) => CameraUnavailable(
                      error: error,
                      alternative: l10n.cameraAlternativeTransfer,
                    ),
                  ),
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
                      onPressed: () => Navigator.of(context).pop(_rows),
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
                  // What the camera is looking at right now. A count that
                  // stands still says nothing about why; this says
                  // whether the pictures are changing at all.
                  if (_receiver.lastSeen case final seen?) ...[
                    const SizedBox(height: 4),
                    Text(
                      _receiver.discarded > 0
                          ? l10n.transferLastSeenMixed(
                              seen + 1,
                              _receiver.discarded,
                            )
                          : l10n.transferLastSeen(seen + 1),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
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
