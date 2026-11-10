import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../../../core/feel.dart';

import 'package:flutter/scheduler.dart';
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
  const CompressionPacerScreen({
    super.key,
    this.compressionsPerCycle = 30,
    @visibleForTesting this.stopwatch,
  });

  /// 30, or 15 for a helper trained in resuscitating children, who picks
  /// it on the screen. The 2025 guidelines give 30:2 to everybody else,
  /// children included.
  final int compressionsPerCycle;

  /// The clock, for a test to wind on.
  final Stopwatch? stopwatch;

  @override
  State<CompressionPacerScreen> createState() => _CompressionPacerScreenState();
}

class _CompressionPacerScreenState extends State<CompressionPacerScreen>
    with SingleTickerProviderStateMixin {
  late int _cycle = widget.compressionsPerCycle;
  var _rate = CompressionPacer.defaultBeatsPerMinute;

  late final _stopwatch = widget.stopwatch ?? Stopwatch();
  Ticker? _ticker;

  /// What tapping has cut from the pauses for the breaths.
  var _skipped = Duration.zero;

  /// The round whose breaths have been announced, so it buzzes once.
  var _breathsAnnounced = 0;
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
    _skipped = Duration.zero;
    _breathsAnnounced = 0;
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
    final tick = _pacer.at(_stopwatch.elapsed, skipped: _skipped);
    if (tick.isBreathing && tick.cycle != _breathsAnnounced) {
      _breathsAnnounced = tick.cycle;
      Feel.breathe();
    }
    if (tick.beat != _soundedBeat) {
      _soundedBeat = tick.beat;
      _sound();
    }
    if (tick.swapsDue > _swapsAnnounced) {
      _swapsAnnounced = tick.swapsDue;
      // A stronger buzz than the beat's, so the changeover is felt and
      // not only seen.
      Feel.beatChange();
    }
    setState(() => _tick = tick);
  }

  /// Done with the breaths before the pause is over.
  void _endBreaths() {
    final tick = _tick;
    if (tick == null || !tick.isBreathing) return;
    _skipped += tick.breathLeft;
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
    Feel.beat();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final tick = _tick;

    final notes = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
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
      ],
    );

    final dial = _Dial(
      tick: tick,
      running: _running,
      l10n: l10n,
      onBreathsDone: _endBreaths,
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.pacerTitle)),
      body: SafeArea(
        // Two layouts, because the two moments ask for different things.
        // Before it starts there is time to scroll. While it runs nothing
        // may move out of sight, so the dial takes what is there, the notes
        // scroll inside their share, and Stop stays where it is (#337).
        child: _running
            ? Column(
                children: [
                  Expanded(flex: 3, child: dial),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: notes,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 64,
                      child: FilledButton.tonalIcon(
                        onPressed: _stop,
                        icon: const Icon(Icons.stop),
                        label: Text(l10n.pacerStop),
                      ),
                    ),
                  ),
                ],
              )
            : SingleChildScrollView(
                child: Column(
                  children: [
                    dial,
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          notes,
                          const SizedBox(height: 16),
                          _RateChoice(
                            rate: _rate,
                            enabled: true,
                            onChanged: (value) => setState(() => _rate = value),
                            l10n: l10n,
                          ),
                          const SizedBox(height: 8),
                          _CycleChoice(
                            cycle: _cycle,
                            enabled: true,
                            onChanged: (value) =>
                                setState(() => _cycle = value),
                            l10n: l10n,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 64,
                            child: FilledButton.icon(
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
  const _Dial({
    required this.tick,
    required this.running,
    required this.l10n,
    required this.onBreathsDone,
  });

  final PacerTick? tick;
  final bool running;
  final AppLocalizations l10n;
  final VoidCallback onBreathsDone;

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
    final pausing = tick.isBreathing;
    // Every beat swaps the colour, with no fade: this is the flash the idle
    // text promises, and for somebody who cannot hear the tone and has no
    // vibration it is the beat. At 120 a minute that is two changes a
    // second, well under the three a second that can trigger a seizure.
    final lit = !breathing && tick.beat.isOdd;
    final background = breathing
        ? scheme.tertiaryContainer
        : lit
        ? scheme.primary
        : scheme.primaryContainer;
    final foreground = breathing
        ? scheme.onTertiaryContainer
        : lit
        ? scheme.onPrimary
        : scheme.onPrimaryContainer;
    final digits = theme.textTheme.displayLarge?.copyWith(
      fontWeight: FontWeight.w700,
      color: foreground,
      // Digits of the same width, so the count does not shuffle sideways
      // between 9 and 10.
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final secondsLeft = tick.breathLeft.inMicroseconds == 0
        ? 0
        : (tick.breathLeft.inMicroseconds / 1000000).ceil();
    // Six seconds from each changeover, and through the pause for the
    // breaths that follows within a round of it. The pause is where two
    // rescuers change over, and the call to breathe used to cover the
    // note for most of it (#337).
    final sinceSwap =
        tick.elapsed - CompressionPacer.swapInterval * tick.swapsDue;
    final swapNote =
        tick.swapsDue > 0 &&
        (sinceSwap < const Duration(seconds: 6) ||
            (breathing && sinceSwap < const Duration(seconds: 30)));

    return LayoutBuilder(
      // Its own node with its own words: a button without a label read as
      // "button", and the countdown inside it was read out every second
      // (#337).
      builder: (context, constraints) => Semantics(
        container: true,
        explicitChildNodes: true,
        button: pausing,
        label: pausing ? l10n.pacerBreatheHint : null,
        onTap: pausing ? onBreathsDone : null,
        // The whole area: the hands have just come off a chest, and nobody
        // is going to aim.
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: pausing ? onBreathsDone : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Expanded(
                  flex: 5,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 220,
                        maxHeight: 220,
                      ),
                      // No implicit animation: a 200 ms fade at 110 beats a
                      // minute is still fading when the next beat lands, and
                      // the result reads as a wobble rather than a beat.
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: background,
                          ),
                          child: Center(
                            child: FittedBox(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: pausing
                                    ? ExcludeSemantics(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.air,
                                              size: 48,
                                              color: foreground,
                                            ),
                                            Text(
                                              '$secondsLeft s',
                                              style: digits,
                                            ),
                                          ],
                                        ),
                                      )
                                    : Text(
                                        '${tick.compression}',
                                        style: digits,
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      tick.compressionsPerCycle == 0
                          ? l10n.pacerPushOnly
                          : l10n.pacerOfCycle(
                              tick.compressionsPerCycle,
                              tick.cycle,
                            ),
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // An IndexedStack is as tall as its tallest child, so the
                // circle does not jump on every thirtieth beat. Scaled down
                // rather than cut off when the text is larger than the room
                // for it (#337): the call to breathe is the one line on this
                // screen that has to be readable whole.
                Flexible(
                  flex: 3,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: SizedBox(
                      width: math.max(0, constraints.maxWidth - 32),
                      child: IndexedStack(
                        alignment: Alignment.center,
                        index: breathing
                            ? 1
                            : swapNote
                            ? 2
                            : 0,
                        children: [
                          const SizedBox.shrink(),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Announced once when it appears, and nothing
                              // else in it: the hint is the button's label.
                              Semantics(
                                container: true,
                                liveRegion: breathing,
                                child: Text(
                                  l10n.pacerBreathe,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(
                                        color: scheme.tertiary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                              ExcludeSemantics(
                                child: Text(
                                  l10n.pacerBreatheHint,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.titleMedium,
                                ),
                              ),
                              // Always there and only sometimes visible, so
                              // the pause takes the same room either way.
                              Opacity(
                                opacity: breathing && swapNote ? 1 : 0,
                                child: Text(
                                  l10n.pacerSwapNow,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: scheme.error,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            l10n.pacerSwapNow,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: scheme.error,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
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
