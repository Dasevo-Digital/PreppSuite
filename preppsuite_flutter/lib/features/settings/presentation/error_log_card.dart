import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/error_log.dart';
import '../../../l10n/generated/app_localizations.dart';

/// The error log, to look at, pass on or clear (#141).
///
/// Passing it on is the person's own act through the share sheet or the
/// clipboard; the app has nowhere to send it and would not.
class ErrorLogCard extends StatefulWidget {
  const ErrorLogCard({super.key, this.log});

  /// Injectable for tests.
  final ErrorLog? log;

  @override
  State<ErrorLogCard> createState() => _ErrorLogCardState();
}

class _ErrorLogCardState extends State<ErrorLogCard> {
  ErrorLog get _log => widget.log ?? ErrorLog.instance;
  int? _count;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final count = await _log.count();
    if (mounted) setState(() => _count = count);
  }

  Future<void> _show() async {
    final l10n = AppLocalizations.of(context)!;
    final text = await _log.read();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.errorLogTitle),
        content: SizedBox(
          width: 640,
          child: SingleChildScrollView(
            child: SelectableText(
              text,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Clipboard.setData(ClipboardData(text: text)),
            icon: const Icon(Icons.copy),
            label: Text(MaterialLocalizations.of(context).copyButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(MaterialLocalizations.of(context).closeButtonLabel),
          ),
        ],
      ),
    );
  }

  Future<void> _share() async {
    final text = await _log.read();
    if (text.isEmpty) return;
    await SharePlus.instance.share(ShareParams(text: text));
  }

  Future<void> _clear() async {
    await _log.clear();
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final count = _count;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.errorLogTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              count == null || count == 0
                  ? l10n.errorLogEmpty
                  : l10n.errorLogCount(count),
            ),
            if (count != null && count > 0)
              Wrap(
                spacing: 8,
                children: [
                  TextButton(onPressed: _show, child: Text(l10n.errorLogShow)),
                  TextButton(
                    onPressed: _share,
                    child: Text(l10n.errorLogShare),
                  ),
                  TextButton(
                    onPressed: _clear,
                    child: Text(l10n.errorLogClear),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
