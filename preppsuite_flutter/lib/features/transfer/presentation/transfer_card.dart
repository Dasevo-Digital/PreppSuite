import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import 'qr_receive_screen.dart';
import 'qr_send_screen.dart';

/// The way to hand a household over with nothing in between.
///
/// Sits beside the shared folder rather than replacing it. The folder is
/// the one that keeps running by itself; this is the one that still works
/// when there is no folder, no cloud and no account — two people in a
/// room, one screen and one camera. In the scenario this app is built
/// for, that is not the unlikely case.
///
/// Two roads behind one pair of buttons: over the local network when
/// there is one, and a run of pictures when there is not. The sending
/// screen picks; the camera on the other side works out which it is
/// looking at.
class TransferCard extends StatelessWidget {
  const TransferCard({
    super.key,
    required this.householdId,
    required this.l10n,
  });

  final String householdId;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.qr_code_2_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.transferTitle,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(l10n.transferIntro, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 6),
            Text(
              l10n.transferSendOverNetworkHint,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            // Wrapped rather than in a Row: at twice the font size two
            // buttons side by side do not fit on a phone.
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => QrSendScreen(householdId: householdId),
                    ),
                  ),
                  icon: const Icon(Icons.qr_code_2),
                  label: Text(l10n.transferSend),
                ),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => QrReceiveScreen(householdId: householdId),
                    ),
                  ),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: Text(l10n.transferReceive),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
