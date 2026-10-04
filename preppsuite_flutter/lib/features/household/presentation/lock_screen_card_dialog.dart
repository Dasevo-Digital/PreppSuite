import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/error_text.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../local_db/database.dart';
import '../application/lock_screen_card.dart';

/// Lets the person choose what goes onto the lock-screen picture, then
/// hands the picture to the share sheet, from where it is saved to the
/// photos and set as the background (#103).
///
/// Only the fields the card has anything in are offered, and the warning
/// that anybody holding the phone can read it sits above the choice,
/// where the choice is made.
class LockScreenCardDialog extends StatefulWidget {
  const LockScreenCardDialog({super.key, required this.card});

  final HouseholdMember card;

  @override
  State<LockScreenCardDialog> createState() => _LockScreenCardDialogState();
}

class _LockScreenCardDialogState extends State<LockScreenCardDialog> {
  late final _available = availableLockScreenFields(widget.card);
  late final _chosen = {
    for (final field in _available)
      if (defaultLockScreenFields.contains(field)) field,
  };
  var _working = false;

  String _label(AppLocalizations l10n, LockScreenField field) =>
      switch (field) {
        LockScreenField.name => l10n.emergencyCardName,
        LockScreenField.birthYear => l10n.emergencyCardBirthYear,
        LockScreenField.bloodType => l10n.emergencyCardBloodType,
        LockScreenField.allergies => l10n.emergencyCardAllergies,
        LockScreenField.medication => l10n.emergencyCardMedication,
        LockScreenField.conditions => l10n.emergencyCardConditions,
        LockScreenField.careNeeds => l10n.emergencyCardCareTitle,
        LockScreenField.contacts => l10n.lockScreenCardCall,
      };

  /// The phone's own screen in physical pixels, upright. A desktop or a
  /// tablet held sideways gets a common phone size instead: the picture
  /// is for a phone either way.
  Size _targetSize(BuildContext context) {
    final media = MediaQuery.of(context);
    final physical = media.size * media.devicePixelRatio;
    final upright = physical.height >= physical.width * 1.6;
    return upright ? physical : const Size(1179, 2556);
  }

  Future<void> _create(AppLocalizations l10n) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final size = _targetSize(context);
    setState(() => _working = true);
    try {
      final png = await renderLockScreenCard(
        heading: l10n.lockScreenCardHeading,
        lines: lockScreenLines(
          widget.card,
          _chosen,
          label: (field) => _label(l10n, field),
        ),
        size: size,
      );
      // The temporary directory: this copy exists only for the seconds
      // it takes the share sheet to hand it on.
      final file = File(
        '${(await getTemporaryDirectory()).path}'
        '${Platform.pathSeparator}notfallkarte-sperrbildschirm.png',
      );
      await file.writeAsBytes(png, flush: true);
      navigator.pop();
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path, mimeType: 'image/png')]),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '${l10n.lockScreenCardFailed} ${describeError(l10n, error)}',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return AlertDialog(
      scrollable: true,
      title: Text(l10n.lockScreenCardTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.lockScreenCardIntro),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.visibility_outlined, color: theme.colorScheme.error),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.lockScreenCardPrivacy,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final field in _available)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _chosen.contains(field),
              title: Text(_label(l10n, field)),
              onChanged: (value) => setState(
                () =>
                    value == true ? _chosen.add(field) : _chosen.remove(field),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancelButton),
        ),
        FilledButton(
          onPressed: _working || _chosen.isEmpty ? null : () => _create(l10n),
          child: Text(l10n.lockScreenCardCreate),
        ),
      ],
    );
  }
}
