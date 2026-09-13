import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/app_database_providers.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../sharing/application/device_snapshot.dart';
import '../../sharing/application/snapshot_exchange.dart';
import '../../sharing/application/shared_folder_store.dart';
import '../application/local_handover.dart';
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
  const QrReceiveScreen({super.key, required this.householdId});

  /// The household this device belongs to. A snapshot from a different
  /// one is refused rather than merged: two households sharing rows by
  /// accident is not something a merge rule can undo afterwards.
  final String householdId;

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

  Future<void> _handover(LocalHandoverInvitation invitation) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {});
    try {
      final result = await joinLocalHandover(
        db: ref.read(appDatabaseProvider),
        deviceId: await const SharedFolderStore().deviceId(),
        householdId: widget.householdId,
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
      if (snapshot.householdId != widget.householdId) {
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
