import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_database_providers.dart';
import '../../../core/error_text.dart';
import '../../settings/application/backup_service.dart';
import '../../settings/presentation/backup_flow.dart';
import '../../settings/presentation/passphrase_dialog.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../model/household_profile.dart';
import '../../sharing/application/household_file.dart';
import '../../sharing/application/shared_folder_access.dart';
import '../../sharing/application/sharing_providers.dart';
import '../../transfer/presentation/qr_receive_screen.dart';
import '../application/household_providers.dart';
import 'profile_setup_screen.dart';

/// The first question, which the app never used to ask.
///
/// Setting up was a single form, written when one household meant one
/// device. On the second device that form is a trap: it makes a *new*
/// household with a new id, and because every local table is partitioned
/// by that id, the two can never merge afterwards. The way to join an
/// existing one existed — a shared folder, a QR code — but only in the
/// settings, behind a household that had already been created wrongly.
///
/// So the choice comes first. And this is the right moment for it in more
/// than a navigational sense: joining means taking over somebody else's
/// household id and re-stamping every local row with it, which is
/// irreversible. On a device that has no rows yet, there is nothing to
/// re-stamp and nothing to lose.
class SetupChoiceScreen extends ConsumerStatefulWidget {
  const SetupChoiceScreen({super.key});

  @override
  ConsumerState<SetupChoiceScreen> createState() => _SetupChoiceScreenState();
}

class _SetupChoiceScreenState extends ConsumerState<SetupChoiceScreen> {
  var _busy = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.setupChoiceTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(l10n.setupChoiceIntro, style: theme.textTheme.bodyLarge),
                const SizedBox(height: 24),
                _Option(
                  icon: Icons.home_outlined,
                  title: l10n.setupChoiceNewTitle,
                  body: l10n.setupChoiceNewBody,
                  onTap: _busy ? null : _startFresh,
                ),
                _Option(
                  icon: Icons.folder_shared_outlined,
                  title: l10n.setupChoiceFolderTitle,
                  body: l10n.setupChoiceFolderBody,
                  onTap: _busy ? null : _joinFolder,
                ),
                _Option(
                  icon: Icons.qr_code_scanner,
                  title: l10n.setupChoiceScanTitle,
                  body: l10n.setupChoiceScanBody,
                  onTap: _busy ? null : _joinByScan,
                ),
                _Option(
                  icon: Icons.settings_backup_restore,
                  title: l10n.setupChoiceRestoreTitle,
                  body: l10n.setupChoiceRestoreBody,
                  onTap: _busy ? null : _restoreBackup,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.setupChoiceSafeNote,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Leaves first-run setup behind for good.
  ///
  /// Every road out of this screen runs through here, and it exists
  /// because of what the screen is: the gate below swaps itself for the
  /// app the moment a profile appears, but these routes were *pushed* on
  /// top of it and nothing pops them. Without this the last thing
  /// somebody sees after a successful setup is the form they just filled
  /// in, which reads exactly like it did not work.
  void _leaveSetup({String? confirmation}) {
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).popUntil((route) => route.isFirst);
    if (confirmation == null) return;
    // Taken hold of before the pop: this screen is gone by the time the
    // message is shown, and the messenger above it is not.
    messenger.showSnackBar(SnackBar(content: Text(confirmation)));
  }

  /// The way back after a device has lost the key to its own data.
  ///
  /// It has to live here rather than in the settings, because the road
  /// through the settings requires a household — and the household the
  /// app would have just created carries a new id, which its own backup
  /// would then refuse. Here there is nothing to lose and the id in the
  /// file is simply taken over.
  Future<void> _restoreBackup() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    PickedBackup? picked;
    try {
      picked = await pickBackup(dialogTitle: l10n.setupChoiceRestoreTitle);
      if (picked == null || !mounted) return;
      final passphrase = await showDialog<String>(
        context: context,
        builder: (_) => PassphraseDialog(l10n: l10n, confirm: false),
      );
      if (passphrase == null || !mounted) return;

      final service = BackupService(ref.read(appDatabaseProvider));
      final opened = await service.open(picked.file, passphrase);
      if (opened == null) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.setupRestoreFailed)),
        );
        return;
      }
      final restored = await service.restoreOpenedAsNewHousehold(opened);

      // A backup from before the profile travelled with it leaves the
      // household nameless. It is still the right household, and naming
      // it is a rename in the settings rather than a reason to refuse.
      await ref
          .read(householdProfileProvider.notifier)
          .adopt(
            restored.profile?.copyWith(id: restored.householdId) ??
                HouseholdProfile(
                  id: restored.householdId,
                  name: l10n.setupRestoreDefaultName,
                  countryCode: 'DE',
                ),
          );
      if (!mounted) return;

      // The files after the rows: a picture belongs to a row, and on a
      // fresh device the rows have only just arrived.
      String? files;
      try {
        files = describeFilesRestored(
          l10n,
          await restoreBackupFilesWithProgress(context, ref, opened: opened),
        );
      } on Object catch (error) {
        // The household is back. Files that did not follow are worth a
        // sentence, not the whole restore.
        files = isBackupCancelled(error)
            ? l10n.backupCancelled
            : '${l10n.backupFailed} ${describeError(l10n, error)}';
      }
      if (!mounted) return;
      final done = l10n.setupRestoreDone(restored.rows);
      _leaveSetup(confirmation: files == null ? done : '$done $files');
    } on Object {
      messenger.showSnackBar(SnackBar(content: Text(l10n.setupRestoreFailed)));
    } finally {
      await picked?.source.close();
      if (mounted) setState(() => _busy = false);
    }
  }

  void _startFresh() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ProfileSetupScreen(onFilled: (_) async => _leaveSetup()),
    ),
  );

  /// Reads the folder *before* asking anything.
  ///
  /// The household file names the household and its country, and the
  /// documentation calls those "das Angebot an ein beitretendes Gerät".
  /// Showing the offer first means somebody types a name only when there
  /// is none to take, instead of typing one that is then overwritten.
  Future<void> _joinFolder() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    HouseholdFile? found;
    SharedFolderLocation? location;
    try {
      location = await pickSharedFolder(dialogTitle: l10n.setupChoiceTitle);
      if (location == null) return;
      final raw = await syncFolderFor(location.value).readHouseholdFile();
      if (raw != null) found = HouseholdFile.decode(raw);
    } on Object {
      // An unreadable folder is not an error worth a stack trace here:
      // `joinFolder` below reports it properly, in the user's words.
      found = null;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (!mounted || location == null) return;

    final target = location;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProfileSetupScreen(
          intro: found == null
              ? l10n.setupFolderEmpty
              : '${l10n.setupFolderFound(found.name)}\n\n'
                    '${l10n.setupFolderFoundBody}',
          initialName: found?.name,
          initialCountryCode: found?.countryCode,
          onFilled: (profile) => _finishFolder(target, profile),
        ),
      ),
    );
  }

  Future<void> _finishFolder(
    SharedFolderLocation location,
    HouseholdProfile profile,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final error = await ref
        .read(sharedFolderProvider.notifier)
        .joinFolder(location, profile: profile);
    if (!mounted) return;
    if (error == null) {
      _leaveSetup(confirmation: l10n.setupDoneFolder);
      return;
    }

    // The profile exists by now, so the gate would let the app through
    // with a folder that was never joined. Undo it and say why.
    await ref.read(householdProfileProvider.notifier).forget();
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.setupJoinFailed(switch (error) {
            SharedFolderJoinError.unwritable => l10n.sharingErrorUnwritable,
            SharedFolderJoinError.unreadable => l10n.sharingErrorUnreadable,
          }),
        ),
      ),
    );
  }

  /// The form first, then the camera.
  ///
  /// The other way round would read the household id off the code and
  /// then leave somebody filling in a form while the host's invitation
  /// times out behind them.
  void _joinByScan() {
    final l10n = AppLocalizations.of(context)!;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProfileSetupScreen(
          intro: l10n.setupScanHint,
          submitLabel: l10n.setupScanContinue,
          onFilled: _finishScan,
        ),
      ),
    );
  }

  /// What the camera brought back decides whether setup is over.
  ///
  /// A number means the household is in. Null means the camera was closed
  /// without one — and then the profile the form already wrote has to go
  /// again, or the gate would let this device through with exactly the
  /// freshly made second household this screen exists to prevent.
  Future<void> _finishScan(HouseholdProfile profile) async {
    final l10n = AppLocalizations.of(context)!;
    final rows = await Navigator.of(context).push(
      MaterialPageRoute<int>(
        builder: (_) =>
            QrReceiveScreen(householdId: profile.id, adoptHousehold: true),
      ),
    );
    if (!mounted) return;
    if (rows == null) {
      await ref.read(householdProfileProvider.notifier).forget();
      if (!mounted) return;
      _leaveSetup(confirmation: l10n.setupScanCancelled);
      return;
    }
    _leaveSetup(confirmation: l10n.setupDoneScan(rows));
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.icon,
    required this.title,
    required this.body,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String body;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      leading: Icon(icon, size: 32),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(body),
      ),
      isThreeLine: true,
      onTap: onTap,
    ),
  );
}
