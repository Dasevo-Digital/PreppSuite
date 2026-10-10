import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/adaptive_columns.dart';
import '../../../core/content_swap.dart';
import '../../../core/error_text.dart';
import '../../../core/feel.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../local_db/database.dart';
import '../application/neighbour_offer_code.dart';
import '../application/neighbour_offer_controller.dart';
import 'neighbour_offer_code_screen.dart';
import 'neighbour_offer_form_screen.dart';
import 'neighbour_offer_l10n.dart';
import 'neighbour_offer_scan_screen.dart';

/// What the household offers its neighbours, and what they offer it (#152).
///
/// No server between the two: an offer leaves this phone as a QR code on
/// its screen and arrives on the next one through a camera, or as the
/// same text through a message. See `neighbour_offer_code.dart` for what
/// the code holds, which is nothing but what was typed.
class NeighbourhoodScreen extends ConsumerWidget {
  const NeighbourhoodScreen({
    super.key,
    required this.householdId,
    this.cameraAvailable,
  });

  final String householdId;

  /// Whether to offer the camera. `mobile_scanner` has nothing on Windows
  /// and Linux, where pasting the text is the way in. Set by tests.
  final bool? cameraAvailable;

  bool get _camera =>
      cameraAvailable ?? (!kIsWeb && !Platform.isWindows && !Platform.isLinux);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final offers = ref.watch(neighbourOffersProvider(householdId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.neighbourhoodTitle)),
      body: ContentSwap(
        child: offers.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text(describeError(l10n, error))),
          data: (rows) {
            final own = [
              for (final row in rows)
                if (!row.received) row,
            ];
            final received = [
              for (final row in rows)
                if (row.received) row,
            ];
            return AdaptiveColumns(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              blocks: [
                Text(l10n.neighbourhoodIntro),
                AdaptiveSection(
                  heading: Text(
                    l10n.neighbourhoodOwnSection,
                    style: theme.textTheme.titleMedium,
                  ),
                  rows: [
                    if (own.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(l10n.neighbourhoodOwnEmpty),
                      ),
                    for (final row in own)
                      _OfferTile(row: row, householdId: householdId),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: FilledButton.tonalIcon(
                        onPressed: () => _push(
                          context,
                          NeighbourOfferFormScreen(householdId: householdId),
                        ),
                        icon: const Icon(Icons.add),
                        label: Text(l10n.neighbourhoodCreate),
                      ),
                    ),
                  ],
                ),
                AdaptiveSection(
                  heading: Text(
                    l10n.neighbourhoodReceivedSection,
                    style: theme.textTheme.titleMedium,
                  ),
                  rows: [
                    if (received.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(l10n.neighbourhoodReceivedEmpty),
                      ),
                    for (final row in received)
                      _OfferTile(row: row, householdId: householdId),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (_camera)
                          FilledButton.tonalIcon(
                            onPressed: () => _scan(context, ref),
                            icon: const Icon(Icons.qr_code_scanner),
                            label: Text(l10n.neighbourhoodScan),
                          ),
                        OutlinedButton.icon(
                          onPressed: () => _paste(context, ref),
                          icon: const Icon(Icons.content_paste),
                          label: Text(l10n.neighbourhoodPaste),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static void _push(BuildContext context, Widget screen) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  Future<void> _scan(BuildContext context, WidgetRef ref) async {
    final offer = await Navigator.of(context).push<NeighbourOfferCode>(
      MaterialPageRoute(builder: (_) => const NeighbourOfferScanScreen()),
    );
    if (offer == null || !context.mounted) return;
    await _receive(context, ref, offer);
  }

  Future<void> _paste(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final text = await showDialog<String>(
      context: context,
      builder: (_) => const _PasteDialog(),
    );
    if (text == null || !context.mounted) return;
    switch (NeighbourOfferCode.decode(text)) {
      case ReadNeighbourOffer(:final offer):
        await _receive(context, ref, offer);
      case NeighbourOfferTooNew():
        _tell(context, l10n.neighbourhoodTooNew);
      case NotANeighbourOffer():
        _tell(context, l10n.neighbourhoodNotAnOffer);
    }
  }

  /// Asks before the offer goes into the list, showing it as it will
  /// stand there: what came through a camera is worth a look before it
  /// is kept.
  Future<void> _receive(
    BuildContext context,
    WidgetRef ref,
    NeighbourOfferCode offer,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final take = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.neighbourhoodReceiveTitle),
        content: SingleChildScrollView(
          child: _OfferSummary(offer: offer, showDate: true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.neighbourhoodReceiveConfirm),
          ),
        ],
      ),
    );
    if (take != true || !context.mounted) return;
    final added = await ref
        .read(neighbourOfferControllerProvider(householdId))
        .receive(offer);
    if (!context.mounted) return;
    if (added) Feel.chose();
    _tell(
      context,
      added ? l10n.neighbourhoodReceived : l10n.neighbourhoodAlreadyKnown,
    );
  }

  /// Replaces whatever was said last rather than queueing behind it:
  /// the second scan of the same code should hear "already there" now,
  /// not after the first message has run its four seconds.
  static void _tell(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

enum _OfferAction { code, edit, delete }

class _OfferTile extends ConsumerWidget {
  const _OfferTile({required this.row, required this.householdId});

  final NeighbourOffer row;
  final String householdId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final own = !row.received;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(neighbourOfferIcon(row.offerKind)),
        title: Text(row.body),
        subtitle: Text(_details(l10n, row.code, showDate: !own)),
        onTap: own
            ? () => NeighbourhoodScreen._push(
                context,
                NeighbourOfferCodeScreen(offer: row),
              )
            : null,
        trailing: PopupMenuButton<_OfferAction>(
          onSelected: (action) {
            switch (action) {
              case _OfferAction.code:
                NeighbourhoodScreen._push(
                  context,
                  NeighbourOfferCodeScreen(offer: row),
                );
              case _OfferAction.edit:
                NeighbourhoodScreen._push(
                  context,
                  NeighbourOfferFormScreen(
                    householdId: householdId,
                    existing: row,
                  ),
                );
              case _OfferAction.delete:
                Feel.removed();
                ref
                    .read(neighbourOfferControllerProvider(householdId))
                    .delete(row);
            }
          },
          itemBuilder: (_) => [
            if (own) ...[
              PopupMenuItem(
                value: _OfferAction.code,
                child: Text(l10n.neighbourhoodShowCode),
              ),
              PopupMenuItem(
                value: _OfferAction.edit,
                child: Text(l10n.neighbourhoodEdit),
              ),
            ],
            PopupMenuItem(
              value: _OfferAction.delete,
              child: Text(l10n.neighbourhoodDelete),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kind, contact and -- for an offer that came from somebody else -- the
/// day it was made, which is how old the "20 l water" is.
String _details(
  AppLocalizations l10n,
  NeighbourOfferCode offer, {
  required bool showDate,
}) => [
  localizeNeighbourOfferKind(l10n, offer.kind),
  ?offer.contact,
  if (showDate)
    l10n.neighbourhoodOfferedOn(
      DateFormat.yMMMd(l10n.localeName).format(offer.offeredOn.toUtc()),
    ),
].join(' · ');

class _OfferSummary extends StatelessWidget {
  const _OfferSummary({required this.offer, required this.showDate});

  final NeighbourOfferCode offer;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(neighbourOfferIcon(offer.kind)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(offer.body, style: theme.textTheme.titleMedium),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(_details(l10n, offer, showDate: showDate)),
      ],
    );
  }
}

class _PasteDialog extends StatefulWidget {
  const _PasteDialog();

  @override
  State<_PasteDialog> createState() => _PasteDialogState();
}

class _PasteDialogState extends State<_PasteDialog> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.neighbourhoodPasteTitle),
      content: TextField(
        controller: _text,
        autofocus: true,
        minLines: 3,
        maxLines: 6,
        decoration: InputDecoration(
          hintText: l10n.neighbourhoodPasteHint,
          hintMaxLines: 3,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancelButton),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_text.text),
          child: Text(l10n.neighbourhoodPasteConfirm),
        ),
      ],
    );
  }
}
