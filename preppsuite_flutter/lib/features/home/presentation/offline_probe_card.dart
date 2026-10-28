import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../application/offline_probe.dart';

class OfflineProbeCard extends StatefulWidget {
  const OfflineProbeCard({super.key, this.probe = const OfflineProbe()});
  final OfflineProbe probe;
  @override
  State<OfflineProbeCard> createState() => _OfflineProbeCardState();
}

class _OfflineProbeCardState extends State<OfflineProbeCard> {
  OfflineProbeControl? _control;
  final _results = <OfflineProbeResult>[];
  bool _networkDisconnected = false;
  bool _testedDisconnected = false;
  bool _running = false;
  bool _failed = false;
  DateTime? _at;

  @override
  void dispose() {
    _control?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    if (_running) return;
    final control = OfflineProbeControl();
    setState(() {
      _control = control;
      _results.clear();
      _failed = false;
      _running = true;
      _testedDisconnected = _networkDisconnected;
      _at = DateTime.now();
    });
    try {
      await for (final result in widget.probe.run(control)) {
        if (!mounted) break;
        setState(() => _results.add(result));
      }
    } on Object {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) {
        setState(() {
          _running = false;
          _control = null;
        });
      }
    }
  }

  String _kind(AppLocalizations l, OfflineProbeKind kind) => switch (kind) {
    OfflineProbeKind.map => l.offlineProbeMap,
    OfflineProbeKind.archive => l.offlineProbeArchive,
    OfflineProbeKind.document => l.offlineProbeDocument,
    OfflineProbeKind.translation => l.offlineProbeTranslation,
    OfflineProbeKind.other => l.offlineProbeOther,
  };

  String _reason(AppLocalizations l, OfflineProbeReason reason) =>
      switch (reason) {
        OfflineProbeReason.readable => l.offlineProbeReadable,
        OfflineProbeReason.missing => l.offlineProbeMissing,
        OfflineProbeReason.unsupported => l.offlineProbeUnsupported,
        OfflineProbeReason.unreadable => l.offlineProbeUnreadable,
        OfflineProbeReason.limit => l.offlineProbeLimit,
        OfflineProbeReason.timeout => l.offlineProbeTimeout,
        OfflineProbeReason.cancelled => l.offlineProbeCancelled,
        OfflineProbeReason.noSample => l.offlineProbeNoSample,
      };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.offlineProbeTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(l.offlineProbeIntro),
            const SizedBox(height: 8),
            Text(l.offlineProbeNetworkHint),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.offlineProbeNetworkDisconnected),
              value: _networkDisconnected,
              onChanged: _running
                  ? null
                  : (value) =>
                        setState(() => _networkDisconnected = value ?? false),
            ),
            if (_running) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              Text(
                _control?.cancelled == true
                    ? l.offlineProbeStopping
                    : l.offlineProbeRunning,
              ),
              TextButton(
                onPressed: _control?.cancelled == true
                    ? null
                    : () => setState(() => _control?.cancel()),
                child: Text(l.offlineProbeStop),
              ),
            ] else
              FilledButton.icon(
                onPressed: _start,
                icon: const Icon(Icons.fact_check_outlined),
                label: Text(
                  _networkDisconnected
                      ? l.offlineProbeStart
                      : l.offlineProbeReadTest,
                ),
              ),
            if (_at != null) ...[
              const SizedBox(height: 12),
              Text(
                l.offlineProbeAt(
                  _testedDisconnected
                      ? l.offlineProbeTitle
                      : l.offlineProbeReadMode,
                  DateFormat.yMMMd(l.localeName).add_Hm().format(_at!),
                ),
              ),
              Text(
                l.offlineProbeSummary(
                  _results
                      .where((r) => r.status == OfflineProbeStatus.passed)
                      .length,
                  _results
                      .where((r) => r.status == OfflineProbeStatus.failed)
                      .length,
                  _results
                      .where((r) => r.status == OfflineProbeStatus.notChecked)
                      .length,
                ),
              ),
            ],
            if (_failed)
              Text(
                l.offlineProbeFailed,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            if (_results.isNotEmpty)
              SizedBox(
                height: math.min(400, _results.length * 110).toDouble(),
                child: ListView.builder(
                  primary: false,
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final result = _results[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(switch (result.status) {
                        OfflineProbeStatus.passed => Icons.check_circle_outline,
                        OfflineProbeStatus.failed => Icons.error_outline,
                        OfflineProbeStatus.notChecked => Icons.help_outline,
                      }),
                      title: Text(
                        result.label.isEmpty
                            ? _kind(l, result.kind)
                            : '${_kind(l, result.kind)}: ${result.label}',
                      ),
                      subtitle: Text(_reason(l, result.reason)),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
