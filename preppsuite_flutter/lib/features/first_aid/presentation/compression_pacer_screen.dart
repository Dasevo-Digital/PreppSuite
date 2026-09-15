import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../application/compression_pacer.dart';

/// The beat, on a screen meant to be glanced at from a metre away.
///
/// Everything here is sized for the one situation it is used in: kneeling
/// on a floor, hands busy, looking up for a fraction of a second at a time.
/// That is why the count is enormous and nothing else on the screen moves
/// while the pacer runs.
///
/// Three channels, because each of them fails somewhere: the tone is
/// inaudible in a crowd and unavailable on a Linux box with no GStreamer,
/// the vibration does not exist on desktop, and the flash is useless if
/// nobody looks. Together they get through.
class CompressionPacerScreen extends StatefulWidget {
  const CompressionPacerScreen({super.key, this.compressionsPerCycle = 30});

  /// 30 for an adult, 15 for a child — set by whichever guide opened this.
  final int compressionsPerCycle;

  @override
  State<CompressionPacerScreen> createState() => _CompressionPacerScreenState();
}

class _CompressionPacerScreenState extends State<CompressionPacerScreen>
    with SingleTickerProviderStateMixin {
  late int _cycle = widget.compressionsPerCycle;
  var _rate = CompressionPacer.defaultBeatsPerMinute;

  final _stopwatch = Stopwatch();
  Ticker? _ticker;
  AudioPlayer? _player;

  /// Whether a tone could be played at all. False turns into a line on
  /// the screen rather than silence nobody can explain.
  var _hasSound = true;

  /// The last beat that was sounded, so one beat makes exactly one click
  /// however many frames fall inside it.
  var _soundedBeat = -1;
  var _swapsAnnounced = 0;

  PacerTick? _tick;
  var _running = false;

  CompressionPacer get _pacer =>
      CompressionPacer(beatsPerMinute: _rate, compressionsPerCycle: _cycle);

  @override
  void initState() {
    super.initState();
    unawaited(_prepareSound());
  }

  @override
  void dispose() {
    _ticker?.dispose();
    unawaited(_player?.dispose());
    // Never leave the screen pinned on after leaving this page.
    _keepScreenOn(false);
    super.dispose();
  }

  Future<void> _prepareSound() async {
    try {
      final player = AudioPlayer();
      // Low latency keeps the sample loaded and ready; the ordinary mode
      // re-opens the file on every play, which at two clicks a second
      // drifts audibly behind the flash.
      await player.setPlayerMode(PlayerMode.lowLatency);
      await player.setReleaseMode(ReleaseMode.stop);
      await player.setSource(AssetSource('sounds/metronome_click.wav'));
      if (!mounted) {
        await player.dispose();
        return;
      }
      _player = player;
    } on Object {
      // No sound card, no GStreamer, a platform that refuses — none of
      // these may stop the pacer, which still flashes and vibrates.
      if (mounted) setState(() => _hasSound = false);
    }
  }

  /// Holds the display awake, or lets it go.
  ///
  /// Wrapped because this reaches a different mechanism on every platform
  /// -- a plugin on the phones and on macOS, FFI on Windows, D-Bus on
  /// Linux -- and the Linux one talks to a desktop portal that a given
  /// session may simply not have. A pacer that dies because nobody
  /// answered on D-Bus would be the worst possible trade: the beat
  /// matters, the bright screen is a convenience.
  void _keepScreenOn(bool on) {
    unawaited(
      (on ? WakelockPlus.enable() : WakelockPlus.disable()).catchError(
        (Object _) {},
      ),
    );
  }

  void _start() {
    if (_running) return;
    _soundedBeat = -1;
    _swapsAnnounced = 0;
    _stopwatch
      ..reset()
      ..start();
    _ticker ??= createTicker(_onFrame);
    _ticker!.start();
    _keepScreenOn(true);
    setState(() {
      _running = true;
      _tick = _pacer.at(Duration.zero);
    });
  }

  void _stop() {
    _ticker?.stop();
    _stopwatch
      ..stop()
      ..reset();
    _keepScreenOn(false);
    setState(() {
      _running = false;
      _tick = null;
    });
  }

  /// Once per frame: work out which beat we are in and, if it is a new
  /// one, sound it.
  ///
  /// The beat is computed from the stopwatch rather than counted, so a
  /// frame that arrives late — and under load they do — cannot lose a
  /// beat or shift the count of thirty.
  void _onFrame(Duration _) {
    final tick = _pacer.at(_stopwatch.elapsed);
    if (tick.beat != _soundedBeat) {
      _soundedBeat = tick.beat;
      _sound();
    }
    if (tick.swapsDue > _swapsAnnounced) {
      _swapsAnnounced = tick.swapsDue;
      // A stronger buzz than the beat's, so the changeover is felt and
      // not only seen.
      unawaited(HapticFeedback.vibrate());
    }
    setState(() => _tick = tick);
  }

  void _sound() {
    final player = _player;
    if (player != null) {
      // Not awaited: a click that arrives a frame late is better than a
      // pacer that waits for the sound card.
      unawaited(
        player
            .seek(Duration.zero)
            .then((_) => player.resume())
            .catchError((Object _) {}),
      );
    }
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      unawaited(HapticFeedback.heavyImpact());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final tick = _tick;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.pacerTitle)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _Dial(tick: tick, running: _running, l10n: l10n),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (tick != null)
                    Text(
                      l10n.pacerElapsed(_clock(tick.elapsed)),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium,
                    ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.pacerDepth,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall,
                  ),
                  if (!_hasSound) ...[
                    const SizedBox(height: 4),
                    Text(
                      l10n.pacerNoSound,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  // The settings are disabled while it runs rather than
                  // hidden: nobody should be changing the ratio mid-count,
                  // and a control that vanishes makes the screen jump.
                  _RateChoice(
                    rate: _rate,
                    enabled: !_running,
                    onChanged: (value) => setState(() => _rate = value),
                    l10n: l10n,
                  ),
                  const SizedBox(height: 8),
                  _CycleChoice(
                    cycle: _cycle,
                    enabled: !_running,
                    onChanged: (value) => setState(() => _cycle = value),
                    l10n: l10n,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 64,
                    child: _running
                        ? FilledButton.tonalIcon(
                            onPressed: _stop,
                            icon: const Icon(Icons.stop),
                            label: Text(l10n.pacerStop),
                          )
                        : FilledButton.icon(
                            onPressed: _start,
                            icon: const Icon(Icons.play_arrow),
                            label: Text(l10n.pacerStart),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _clock(Duration elapsed) {
    final minutes = elapsed.inMinutes;
    final seconds = elapsed.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

/// The count, the flash and the changeover notice.
class _Dial extends StatelessWidget {
  const _Dial({required this.tick, required this.running, required this.l10n});

  final PacerTick? tick;
  final bool running;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // Into a local because a widget's public field cannot be promoted to
    // non-null, and every line below reads from it.
    final tick = this.tick;

    if (tick == null || !running) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l10n.pacerIdle,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
        ),
      );
    }

    final breathing = tick.isLastOfCycle;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // No implicit animation: a 200 ms fade at 110 beats a minute
            // is still fading when the next beat lands, and the result
            // reads as a wobble rather than a beat.
            Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: breathing
                    ? scheme.tertiaryContainer
                    : scheme.primaryContainer,
              ),
              alignment: Alignment.center,
              child: FittedBox(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    '${tick.compression}',
                    style: theme.textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: breathing
                          ? scheme.onTertiaryContainer
                          : scheme.onPrimaryContainer,
                      // Digits of the same width, so the count does not
                      // shuffle sideways between 9 and 10.
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              tick.compressionsPerCycle == 0
                  ? l10n.pacerPushOnly
                  : l10n.pacerOfCycle(
                      tick.compressionsPerCycle,
                      tick.cycle,
                    ),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            // The space is held whether or not there is anything in it,
            // so nothing below jumps on every thirtieth beat.
            SizedBox(
              height: 40,
              child: breathing
                  ? Text(
                      l10n.pacerBreathe,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: scheme.tertiary,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : tick.swapsDue > 0 && tick.elapsed.inSeconds % 120 < 6
                  ? Text(
                      l10n.pacerSwapNow,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: scheme.error,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _RateChoice extends StatelessWidget {
  const _RateChoice({
    required this.rate,
    required this.enabled,
    required this.onChanged,
    required this.l10n,
  });

  final int rate;
  final bool enabled;
  final ValueChanged<int> onChanged;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    // Only the three the guideline allows. A free dial would let somebody
    // set 80, and a metronome at 80 is worse than none.
    const rates = [
      CompressionPacer.minimumBeatsPerMinute,
      CompressionPacer.defaultBeatsPerMinute,
      CompressionPacer.maximumBeatsPerMinute,
    ];
    return SegmentedButton<int>(
      segments: [
        for (final value in rates)
          ButtonSegment(value: value, label: Text(l10n.pacerPerMinute(value))),
      ],
      selected: {rate},
      onSelectionChanged: enabled ? (set) => onChanged(set.first) : null,
      showSelectedIcon: false,
    );
  }
}

class _CycleChoice extends StatelessWidget {
  const _CycleChoice({
    required this.cycle,
    required this.enabled,
    required this.onChanged,
    required this.l10n,
  });

  final int cycle;
  final bool enabled;
  final ValueChanged<int> onChanged;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<int>(
      segments: [
        const ButtonSegment(value: 30, label: Text('30:2')),
        const ButtonSegment(value: 15, label: Text('15:2')),
        ButtonSegment(value: 0, label: Text(l10n.pacerPushOnlyShort)),
      ],
      selected: {cycle},
      onSelectionChanged: enabled ? (set) => onChanged(set.first) : null,
      showSelectedIcon: false,
    );
  }
}
