import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../local_db/database.dart';
import '../../transfer/presentation/qr_code_view.dart';
import '../application/neighbour_offer_controller.dart';

import 'neighbour_offer_l10n.dart';

/// One of the household's offers, as a code a neighbour can film (#152).
///
/// The text under the code is the code: what is shown is exactly what
/// anybody pointing a camera at the screen gets, and nothing more. It can
/// also go out as text, for a neighbour who is not at the door -- the same
/// text, which PreppSuite on the other end takes in through "Text
/// einfügen".
class NeighbourOfferCodeScreen extends StatelessWidget {
  const NeighbourOfferCodeScreen({super.key, required this.offer});

  final NeighbourOffer offer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final text = neighbourOfferText(l10n, offer.code);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.neighbourhoodCodeTitle)),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // As large as the screen allows and no larger than a camera
          // across a doorway needs.
          final side = (constraints.maxWidth - 32).clamp(160.0, 360.0);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: QrCodeView(
                  data: text,
                  size: side,
                  semanticLabel: l10n.neighbourhoodCodeSemantics,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(text, style: theme.textTheme.bodyLarge),
                ),
              ),
              const SizedBox(height: 12),
              Text(l10n.neighbourhoodCodeHint),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () =>
                    SharePlus.instance.share(ShareParams(text: text)),
                icon: const Icon(Icons.share_outlined),
                label: Text(l10n.neighbourhoodShareText),
              ),
            ],
          );
        },
      ),
    );
  }
}
