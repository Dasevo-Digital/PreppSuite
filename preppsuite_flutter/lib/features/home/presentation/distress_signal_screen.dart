import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/feel.dart';

import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../application/distress_signal.dart';

/// The screen as a lamp, in a rhythm somebody recognises.
///
/// The app already says how to reach help when there is a network. This is
/// for when there is none and somebody might still be able to *see* you —
/// a hillside, a stairwell, the other side of a valley.
///
/// Deliberately the display and not the camera light. A torch needs a
/// camera plugin and a permission, exists on two of the five platforms
/// this ships to, and fails silently on the rest; a white screen is on
/// every one of them and can be held up just the same. What it costs is
/// brightness, which is why the screen says so rather than leaving
/// somebody to find out when the battery is flat.
class DistressSignalScreen extends StatefulWidget {
  const DistressSignalScreen({super.key});

  @override
  State<DistressSignalScreen> createState() => _DistressSignalScreenState();
}

class _DistressSignalScreenState extends State<DistressSignalScreen> {
  final _stopwatch = Stopwatch();
  Timer? _ticker;
  var _choice = DistressSignal.sos;
  var _lit = false;
  var _flash = 0;

  DistressSignalPattern get _pattern => DistressSignalPattern(_choice);

  @override
  void dispose() {
    _ticker?.cancel();
    _keepScreenOn(false);
    super.dispose();
  }

  /// Wrapped for the same reason the compression pacer wraps it: this
  /// reaches a different mechanism on every platform, and on Linux a
  /// desktop portal that a given session may simply not have. A signal
  /// that died because nobody answered on D-Bus would be the worst trade
  /// of all — the rhythm matters, the bright screen is a convenience.
  void _keepScreenOn(bool on) {
    unawaited(
      (on ? WakelockPlus.enable() : WakelockPlus.disable()).catchError(
        (Object _) {},
      ),
    );
  }

  void _toggle() {
    if (_stopwatch.isRunning) {
      _ticker?.cancel();
      _stopwatch
        ..stop()
        ..reset();
      _keepScreenOn(false);
      setState(() {
        _lit = false;
        _flash = 0;
      });
      return;
    }

    _stopwatch
      ..reset()
      ..start();
    _keepScreenOn(true);
    // Asked often and answered from the elapsed time, so a late tick
    // shows the right state instead of shifting the rhythm.
    _ticker = Timer.periodic(const Duration(milliseconds: 40), (_) {
      if (!mounted) return;
      final pattern = _pattern;
      final elapsed = _stopwatch.elapsed;
      final lit = pattern.isLitAt(elapsed);
      final flash = pattern.flashNumberAt(elapsed);
      if (lit == _lit && flash == _flash) return;
      if (lit && !_lit) Feel.beat();
      setState(() {
        _lit = lit;
        _flash = flash;
      });
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final running = _stopwatch.isRunning;
    final pattern = _pattern;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.distressTitle)),
      body: SafeArea(
        // Two layouts, not one that stretches. While it is running the
        // lamp is the whole point and gets the whole screen; while it is
        // not, there is prose and three choices to read, and at twice the
        // system font size those do not fit beside anything.
        child: running
            ? Column(
                children: [
                  Expanded(child: _lamp(l10n, theme, pattern, running)),
                  _button(l10n, running),
                ],
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(l10n.distressIntro),
                  const SizedBox(height: 8),
                  Text(l10n.distressBattery, style: theme.textTheme.bodySmall),
                  const SizedBox(height: 12),
                  RadioGroup<DistressSignal>(
                    groupValue: _choice,
                    onChanged: (value) =>
                        setState(() => _choice = value ?? _choice),
                    child: Column(
                      children: [
                        for (final signal in DistressSignal.values)
                          RadioListTile<DistressSignal>(
                            value: signal,
                            title: Text(_titleFor(l10n, signal)),
                            subtitle: Text(_hintFor(l10n, signal)),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 180,
                    child: _lamp(l10n, theme, pattern, running),
                  ),
                  const SizedBox(height: 12),
                  _button(l10n, running),
                ],
              ),
      ),
    );
  }

  Widget _lamp(
    AppLocalizations l10n,
    ThemeData theme,
    DistressSignalPattern pattern,
    bool running,
  ) => GestureDetector(
    onTap: _toggle,
    child: Container(
      width: double.infinity,
      margin: running ? const EdgeInsets.all(16) : EdgeInsets.zero,
      decoration: BoxDecoration(
        // White and not the accent colour: what carries across a dark
        // hillside is brightness, not hue.
        color: _lit ? Colors.white : Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            running
                ? (_flash == 0
                      ? l10n.distressPause
                      : l10n.distressFlash(_flash, pattern.flashesPerPeriod))
                : l10n.distressStart,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: _lit ? Colors.black : Colors.white70,
            ),
          ),
        ),
      ),
    ),
  );

  Widget _button(AppLocalizations l10n, bool running) => Padding(
    padding: running
        ? const EdgeInsets.fromLTRB(16, 0, 16, 16)
        : EdgeInsets.zero,
    child: SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _toggle,
        icon: Icon(running ? Icons.stop : Icons.play_arrow),
        label: Text(running ? l10n.distressStop : l10n.distressStart),
      ),
    ),
  );

  String _titleFor(AppLocalizations l10n, DistressSignal signal) =>
      switch (signal) {
        DistressSignal.sos => l10n.distressSos,
        DistressSignal.alpine => l10n.distressAlpine,
        DistressSignal.alpineAnswer => l10n.distressAlpineAnswer,
      };

  String _hintFor(AppLocalizations l10n, DistressSignal signal) =>
      switch (signal) {
        DistressSignal.sos => l10n.distressSosHint,
        DistressSignal.alpine => l10n.distressAlpineHint,
        DistressSignal.alpineAnswer => l10n.distressAlpineAnswerHint,
      };
}
