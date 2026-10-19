import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/generated/app_localizations.dart';

/// Where to give something towards the work on the app, for whoever
/// wants to (#196).
///
/// It sits under "Über PreppSuite" and nowhere else: the app asks for
/// nothing, and a request on the overview -- the screen someone opens in
/// an emergency -- would be in the wrong place. The button names the
/// address it opens, so nobody has to trust a label. The app fetches
/// nothing itself; the page opens in the browser.
class SupportCard extends StatelessWidget {
  const SupportCard({super.key, this.launch});

  static final Uri address = Uri.https('ko-fi.com', '/superkuh86');

  /// The address as it reads, without the scheme.
  static String get shownAddress => '${address.host}${address.path}';

  /// Injectable for tests; `launchUrl` in the browser otherwise.
  final Future<bool> Function(Uri uri)? launch;

  static Future<bool> _inBrowser(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);

  Future<void> _open(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    bool opened;
    try {
      opened = await (launch ?? _inBrowser)(address);
    } on Object {
      opened = false;
    }
    if (!opened) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.supportOpenFailed(shownAddress))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.supportTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(l10n.supportBody),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: () => _open(context),
              icon: const Icon(Icons.local_cafe_outlined),
              label: Text(shownAddress),
            ),
          ],
        ),
      ),
    );
  }
}
