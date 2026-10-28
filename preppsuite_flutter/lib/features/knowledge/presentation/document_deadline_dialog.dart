import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/notification_capabilities.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/document_deadline.dart';
import '../application/personal_document_store.dart';

class DocumentDeadlineDraft {
  const DocumentDeadlineDraft({
    required this.validUntil,
    required this.remindOn,
    required this.reviewedOn,
    required this.originalLocation,
  });
  final DateTime? validUntil, remindOn, reviewedOn;
  final String originalLocation;
}

/// Owns its controller until the dialog has finished fading out.
class DocumentDeadlineDialog extends StatefulWidget {
  const DocumentDeadlineDialog({super.key, required this.document});
  final PersonalDocument document;

  @override
  State<DocumentDeadlineDialog> createState() => _DocumentDeadlineDialogState();
}

class _DocumentDeadlineDialogState extends State<DocumentDeadlineDialog> {
  late DateTime? _validUntil = widget.document.validUntil;
  late DateTime? _remindOn = widget.document.remindOn;
  late DateTime? _reviewedOn = widget.document.reviewedOn;
  late final _original = TextEditingController(
    text: widget.document.originalLocation,
  );
  bool _invalidReminder = false;

  @override
  void dispose() {
    _original.dispose();
    super.dispose();
  }

  Future<void> _pick(
    DateTime? value,
    ValueChanged<DateTime?> changed, {
    bool past = false,
  }) async {
    final first = DateTime(1900);
    final last = past ? documentDay(DateTime.now()) : DateTime(2200, 12, 31);
    var initial = value ?? documentDay(DateTime.now());
    if (initial.isBefore(first)) initial = first;
    if (initial.isAfter(last)) initial = last;
    final chosen = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );
    if (chosen != null && mounted) {
      setState(() {
        changed(chosen);
        _invalidReminder = false;
      });
    }
  }

  Widget _date(
    String title,
    DateTime? value,
    ValueChanged<DateTime?> changed, {
    bool past = false,
  }) {
    final l = AppLocalizations.of(context)!;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(
        value == null
            ? l.documentDateUnset
            : DateFormat.yMMMd(l.localeName).format(value),
      ),
      onTap: () => _pick(value, changed, past: past),
      trailing: value == null
          ? const Icon(Icons.calendar_month_outlined)
          : IconButton(
              tooltip: l.documentDateClear(title),
              icon: const Icon(Icons.clear),
              onPressed: () => setState(() {
                changed(null);
                _invalidReminder = false;
              }),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l.documentDeadlineEdit),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.document.label),
              _date(l.documentValidUntil, _validUntil, (d) => _validUntil = d),
              _date(l.documentRemindOn, _remindOn, (d) => _remindOn = d),
              if (_invalidReminder)
                Text(
                  l.documentReminderAfterExpiry,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              Text(
                supportsScheduledNotifications
                    ? l.documentReminderHint
                    : l.documentReminderInAppOnly,
              ),
              _date(
                l.documentReviewedOn,
                _reviewedOn,
                (d) => _reviewedOn = d,
                past: true,
              ),
              TextButton.icon(
                onPressed: () =>
                    setState(() => _reviewedOn = documentDay(DateTime.now())),
                icon: const Icon(Icons.fact_check_outlined),
                label: Text(l.documentReviewedToday),
              ),
              TextField(
                controller: _original,
                maxLength: 240,
                minLines: 1,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: l.documentOriginalLocation,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          onPressed: () {
            if (_remindOn != null &&
                _validUntil != null &&
                _remindOn!.isAfter(_validUntil!)) {
              setState(() => _invalidReminder = true);
              return;
            }
            Navigator.of(context).pop(
              DocumentDeadlineDraft(
                validUntil: _validUntil,
                remindOn: _remindOn,
                reviewedOn: _reviewedOn,
                originalLocation: _original.text.trim(),
              ),
            );
          },
          child: Text(l.documentDeadlineSave),
        ),
      ],
    );
  }
}
