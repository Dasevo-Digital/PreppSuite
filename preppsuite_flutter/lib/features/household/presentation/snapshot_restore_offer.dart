import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/app_database_providers.dart';
import '../../../core/database_snapshots.dart';
import '../../../core/local_database_encryption.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/household_providers.dart';

/// On the screen of a household that does not load: the newest automatic
/// copy that opens cleanly, offered to be put back (#140).
///
/// Only one that passes SQLite's quick check under this device's key is
/// offered. A copy that is damaged itself, or one this device cannot read,
/// would only replace one error with the next.
class SnapshotRestoreOffer extends ConsumerStatefulWidget {
  const SnapshotRestoreOffer({super.key, this.snapshots});

  /// Injectable for tests; the household database's own otherwise.
  final DatabaseSnapshots? snapshots;

  @override
  ConsumerState<SnapshotRestoreOffer> createState() =>
      _SnapshotRestoreOfferState();
}

class _SnapshotRestoreOfferState extends ConsumerState<SnapshotRestoreOffer> {
  DatabaseSnapshots? _snapshots;
  File? _copy;
  DateTime? _takenAt;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    _find();
  }

  Future<void> _find() async {
    try {
      final snapshots =
          widget.snapshots ??
          DatabaseSnapshots(
            LocalDatabaseEncryption.instance.databaseFile(
              localDatabaseFilePrefix,
            ),
          );
      for (final copy in await snapshots.list()) {
        if (!LocalDatabaseEncryption.instance.opensCleanly(copy)) continue;
        if (!mounted) return;
        setState(() {
          _snapshots = snapshots;
          _copy = copy;
          _takenAt = snapshots.takenAt(copy);
        });
        return;
      }
    } on Object {
      // Nothing to offer.
    }
  }

  Future<void> _restore(String when) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.snapshotRestoreTitle),
        content: Text(l10n.snapshotRestoreBody(when)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.snapshotRestoreConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      // Closed first and awaited: Windows will not rename a file that is
      // still open, and nothing may write into it while it is moved.
      await ref.read(appDatabaseProvider).close();
      ref.invalidate(appDatabaseProvider);
      await _snapshots!.restore(_copy!);
      ref.invalidate(householdProfileProvider);
    } on Object {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.snapshotRestoreFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final takenAt = _takenAt;
    if (_copy == null || takenAt == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final when = DateFormat.yMMMd(
      l10n.localeName,
    ).add_Hm().format(takenAt.toLocal());
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: _busy
          ? const LinearProgressIndicator()
          : OutlinedButton.icon(
              onPressed: () => _restore(when),
              icon: const Icon(Icons.history),
              label: Text(l10n.snapshotRestoreAction(when)),
            ),
    );
  }
}
