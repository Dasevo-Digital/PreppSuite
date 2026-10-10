import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../local_db/database.dart';
import '../application/neighbour_offer_code.dart';
import '../application/neighbour_offer_controller.dart';
import 'neighbour_offer_l10n.dart';

/// One of the household's own offers, new or changed (#152).
///
/// Three fields and nothing filled in for the person: not the household's
/// name, not its address, not what the inventory holds. The note under
/// the form says what the code will contain, because a QR code on a
/// screen is readable by anybody who points a camera at it.
class NeighbourOfferFormScreen extends ConsumerStatefulWidget {
  const NeighbourOfferFormScreen({
    super.key,
    required this.householdId,
    this.existing,
  });

  final String householdId;
  final NeighbourOffer? existing;

  @override
  ConsumerState<NeighbourOfferFormScreen> createState() =>
      _NeighbourOfferFormScreenState();
}

class _NeighbourOfferFormScreenState
    extends ConsumerState<NeighbourOfferFormScreen> {
  final _form = GlobalKey<FormState>();
  late final _body = TextEditingController(text: widget.existing?.body);
  late final _contact = TextEditingController(text: widget.existing?.contact);
  late var _kind = widget.existing?.offerKind ?? NeighbourOfferKind.water;

  @override
  void dispose() {
    _body.dispose();
    _contact.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    await ref
        .read(neighbourOfferControllerProvider(widget.householdId))
        .saveOwn(
          kind: _kind,
          body: _body.text,
          contact: _contact.text,
          existing: widget.existing,
        );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existing == null
              ? l10n.neighbourhoodFormNew
              : l10n.neighbourhoodFormEdit,
        ),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<NeighbourOfferKind>(
              initialValue: _kind,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l10n.neighbourhoodKindField,
              ),
              items: [
                for (final kind in NeighbourOfferKind.values)
                  DropdownMenuItem(
                    value: kind,
                    child: Row(
                      children: [
                        Icon(neighbourOfferIcon(kind)),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            localizeNeighbourOfferKind(l10n, kind),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
              onChanged: (kind) {
                if (kind != null) setState(() => _kind = kind);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _body,
              autofocus: widget.existing == null,
              maxLength: neighbourOfferBodyLimit,
              // One line on purpose: a line break would read as the next
              // field of the code. Wrapped on screen all the same.
              keyboardType: TextInputType.text,
              minLines: 1,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: l10n.neighbourhoodBodyField,
                hintText: l10n.neighbourhoodBodyHint,
              ),
              validator: (value) => (value ?? '').trim().isEmpty
                  ? l10n.neighbourhoodBodyRequired
                  : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _contact,
              maxLength: neighbourOfferContactLimit,
              decoration: InputDecoration(
                labelText: l10n.neighbourhoodContactField,
                hintText: l10n.neighbourhoodContactHint,
                hintMaxLines: 3,
              ),
            ),
            const SizedBox(height: 16),
            Text(l10n.neighbourhoodFormNote, style: theme.textTheme.bodySmall),
            const SizedBox(height: 24),
            FilledButton(onPressed: _save, child: Text(l10n.saveButton)),
          ],
        ),
      ),
    );
  }
}
