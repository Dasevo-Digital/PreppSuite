import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../application/morse_code.dart';
import '../application/morse_keyer.dart';
import '../../home/application/signal_tone.dart';
import '../../home/presentation/signal_tone_player.dart';

/// Morse code: a translator both ways, the screen as a lamp for a
/// message, and the whole table (#180).
///
/// Beside the distress signal rather than inside it. That one sends one
/// rhythm everybody knows; this sends whatever somebody types, to somebody
/// who can read it -- and reads back what they flash in return.
class MorseScreen extends StatefulWidget {
  const MorseScreen({super.key, @visibleForTesting this.keyClock});

  /// The clock the Morse key is timed with; a test's own, so presses can
  /// be held for an exact length.
  final Duration Function()? keyClock;

  @override
  State<MorseScreen> createState() => _MorseScreenState();
}

class _MorseScreenState extends State<MorseScreen>
    with SingleTickerProviderStateMixin {
  final _input = TextEditingController();
  late final TabController _tabs = TabController(length: 2, vsync: this)
    // Changing tab ends a message being sent: a lamp that goes on
    // flashing behind the table is one nobody is holding up.
    ..addListener(() {
      if (_rhythm != null) setState(_stop);
    });
  var _toMorse = true;
  var _speed = MorseSpeed.slow;

  final _stopwatch = Stopwatch();
  Timer? _ticker;
  MorseRhythm? _rhythm;

  /// Keying by hand (#191): presses in time with a lamp become the code
  /// in the field. [_keyedFrom] is what the field held before this run of
  /// presses, so the keyer can rewrite its own part as it learns the
  /// speed.
  final _keyer = MorseKeyer();
  final _keyClock = Stopwatch()..start();
  final _keyFocus = FocusNode(debugLabel: 'morse key');
  var _keyedFrom = '';
  var _keyDown = false;

  /// Sounding what the lamp flashes (#188), one choice with the distress
  /// signal's.
  final _tone = SignalTonePlayer();
  var _withTone = false;
  var _starting = false;

  @override
  void initState() {
    super.initState();
    unawaited(
      const SignalToneSetting().load().then((on) {
        if (mounted) setState(() => _withTone = on);
      }),
    );
  }

  /// What is being sent, worked out once at the start: each character as
  /// the sender typed it, and its signal.
  List<String> _characters = const [];
  List<String> _codes = const [];
  var _lit = false;
  int? _character;

  @override
  void dispose() {
    _stop();
    unawaited(_tone.dispose());
    _keyFocus.dispose();
    _tabs.dispose();
    _input.dispose();
    super.dispose();
  }

  /// Wrapped as the distress signal wraps it: a desktop session without
  /// the portal behind it must not cost the signal itself.
  void _keepScreenOn(bool on) {
    unawaited(
      (on ? WakelockPlus.enable() : WakelockPlus.disable()).catchError(
        (Object _) {},
      ),
    );
  }

  Future<void> _start(MorseEncoding message) async {
    if (_starting) return;
    final rhythm = MorseRhythm(message, unit: _speed.unit);
    // Rendered before the lamp starts, so tone and light begin together.
    if (_withTone && _tone.available) {
      _starting = true;
      await _tone.prepare(rhythm, hertz: morseToneHertz);
      _starting = false;
      if (!mounted) return;
    }
    _rhythm = rhythm;
    _characters = _sentCharacters(_input.text);
    _codes = [for (final word in message.words) ...word];
    _stopwatch
      ..reset()
      ..start();
    _keepScreenOn(true);
    // Asked every frame and answered from the elapsed time, so a late
    // tick shows the right state instead of stretching a dot into a dash.
    _ticker = Timer.periodic(const Duration(milliseconds: 16), (_) {
      final rhythm = _rhythm;
      if (!mounted || rhythm == null) return;
      final elapsed = _stopwatch.elapsed;
      final lit = rhythm.isLitAt(elapsed);
      final character = rhythm.characterAt(elapsed);
      if (_withTone) _tone.follow(elapsed);
      if (lit == _lit && character == _character) return;
      setState(() {
        _lit = lit;
        _character = character;
      });
    });
    setState(() {});
  }

  void _stop() {
    _ticker?.cancel();
    _ticker = null;
    unawaited(_tone.stop());
    if (_stopwatch.isRunning) _keepScreenOn(false);
    _stopwatch
      ..stop()
      ..reset();
    _rhythm = null;
    _characters = const [];
    _codes = const [];
    _lit = false;
    _character = null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sending = _rhythm != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.morseTitle),
        bottom: sending
            ? null
            : TabBar(
                controller: _tabs,
                tabs: [
                  Tab(text: l10n.morseTabTranslate),
                  Tab(text: l10n.morseTabChart),
                ],
              ),
      ),
      body: SafeArea(
        child: sending
            ? _lamp(context, l10n)
            : TabBarView(
                controller: _tabs,
                children: [_translator(context, l10n), const _MorseChart()],
              ),
      ),
    );
  }

  Widget _translator(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final input = _input.text;
    final encoded = _toMorse ? encodeMorse(input) : null;
    final decoded = _toMorse ? null : decodeMorse(input);
    final result = encoded?.format() ?? decoded!.text;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SegmentedButton<bool>(
          segments: [
            ButtonSegment(value: true, label: Text(l10n.morseToMorse)),
            ButtonSegment(value: false, label: Text(l10n.morseToText)),
          ],
          selected: {_toMorse},
          onSelectionChanged: (selection) => setState(() {
            // The result goes the other way round: what was the answer is
            // now the question, which is how a reply gets read back.
            final previous = _toMorse
                ? encodeMorse(_input.text).format()
                : decodeMorse(_input.text).text;
            _toMorse = selection.first;
            _keyer.reset();
            _input.text = previous;
          }),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _input,
          minLines: 2,
          maxLines: 6,
          // Typing by hand ends a run of keyed presses: the keyer must not
          // rewrite what somebody has just corrected.
          onChanged: (_) => setState(_keyer.reset),
          decoration: InputDecoration(
            labelText: _toMorse ? l10n.morseTextLabel : l10n.morseCodeLabel,
            helperText: _toMorse ? null : l10n.morseCodeHint,
            helperMaxLines: 3,
            border: const OutlineInputBorder(),
          ),
        ),
        if (!_toMorse) ...[
          const SizedBox(height: 12),
          _morseKey(context, l10n),
        ],
        const SizedBox(height: 12),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.morseResult,
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.morseCopy,
                      icon: const Icon(Icons.copy_outlined),
                      onPressed: result.isEmpty
                          ? null
                          : () => _copy(context, l10n, result),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    result.isEmpty ? '–' : result,
                    style: _toMorse
                        ? theme.textTheme.titleLarge?.copyWith(
                            letterSpacing: 2,
                          )
                        : theme.textTheme.titleLarge,
                  ),
                ),
                if (encoded != null && encoded.unknown.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.morseCannotSend(encoded.unknown.join(' ')),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
                if (decoded != null && decoded.unknown.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.morseUnknownCodes(decoded.unknown.join('  ')),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ),
        if (encoded != null && !encoded.isEmpty) ...[
          const SizedBox(height: 16),
          Text(l10n.morseSpeed, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<MorseSpeed>(
            segments: [
              ButtonSegment(
                value: MorseSpeed.slow,
                label: Text(l10n.morseSpeedSlow),
              ),
              ButtonSegment(
                value: MorseSpeed.medium,
                label: Text(l10n.morseSpeedMedium),
              ),
              ButtonSegment(
                value: MorseSpeed.fast,
                label: Text(l10n.morseSpeedFast),
              ),
            ],
            selected: {_speed},
            onSelectionChanged: (selection) =>
                setState(() => _speed = selection.first),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _withTone,
            onChanged: (on) {
              setState(() => _withTone = on);
              unawaited(const SignalToneSetting().save(on));
            },
            secondary: const Icon(Icons.volume_up_outlined),
            title: Text(l10n.signalToneSwitch),
            subtitle: Text(
              _tone.available
                  ? l10n.signalToneHint
                  : l10n.signalToneUnavailable,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => _start(encoded),
            icon: const Icon(Icons.highlight_outlined),
            label: Text(l10n.morseSend),
          ),
          const SizedBox(height: 8),
          Text(l10n.morseLampHint, style: theme.textTheme.bodySmall),
        ],
      ],
    );
  }

  void _keyPress() {
    if (_keyDown) return;
    if (_keyer.isEmpty) {
      final before = _input.text.trimRight();
      _keyedFrom = before.isEmpty ? '' : '$before / ';
    }
    _keyer.down(widget.keyClock?.call() ?? _keyClock.elapsed);
    setState(() => _keyDown = true);
  }

  void _keyRelease() {
    if (!_keyDown) return;
    _keyer.up(widget.keyClock?.call() ?? _keyClock.elapsed);
    _input.text = _keyedFrom + _keyer.code;
    setState(() => _keyDown = false);
  }

  /// A large key, pressed for as long as the light is on. Raw pointer
  /// events rather than a tap recogniser, which waits a moment before it
  /// reports a press down and would make every press look shorter; the
  /// space bar works the same where there is a keyboard.
  Widget _morseKey(BuildContext context, AppLocalizations l10n) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Focus(
          focusNode: _keyFocus,
          onKeyEvent: (node, event) {
            if (event.logicalKey != LogicalKeyboardKey.space) {
              return KeyEventResult.ignored;
            }
            if (event is KeyDownEvent) _keyPress();
            if (event is KeyUpEvent) _keyRelease();
            return KeyEventResult.handled;
          },
          child: Semantics(
            button: true,
            label: l10n.morseKey,
            child: Listener(
              onPointerDown: (_) {
                _keyFocus.requestFocus();
                _keyPress();
              },
              onPointerUp: (_) => _keyRelease(),
              onPointerCancel: (_) => _keyRelease(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 60),
                height: 120,
                decoration: BoxDecoration(
                  color: _keyDown ? scheme.primary : scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Text(
                  l10n.morseKey,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: _keyDown
                        ? scheme.onPrimary
                        : scheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(l10n.morseKeyHint, style: Theme.of(context).textTheme.bodySmall),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton(
            onPressed: () => setState(() {
              _keyer.reset();
              _input.clear();
            }),
            child: Text(l10n.morseKeyClear),
          ),
        ),
      ],
    );
  }

  Future<void> _copy(
    BuildContext context,
    AppLocalizations l10n,
    String text,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: text));
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.morseCopied)));
  }

  /// The whole screen as the lamp, the character being sent written on
  /// it so the sender can follow where the message is.
  Widget _lamp(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final rhythm = _rhythm!;
    final letters = _codes;
    final characters = _characters;
    final at = _character;
    return Column(
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              // White and not the accent colour: what carries is
              // brightness, not hue.
              color: _lit ? Colors.white : Colors.black,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      at == null || at >= characters.length
                          ? ' '
                          : characters[at],
                      style: theme.textTheme.displayMedium?.copyWith(
                        color: _lit ? Colors.black : Colors.white,
                      ),
                    ),
                    Text(
                      at == null || at >= letters.length
                          ? ' '
                          : drawMorse(letters[at]),
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: _lit ? Colors.black54 : Colors.white70,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.morseLampSending(
                        (at ?? 0) + 1,
                        rhythm.characters,
                      ),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: _lit ? Colors.black54 : Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => setState(_stop),
              icon: const Icon(Icons.stop),
              label: Text(l10n.morseStop),
            ),
          ),
        ),
      ],
    );
  }

  /// The characters that are sent, in order -- what [encodeMorse] keeps
  /// of [text], as letters a sender recognises.
  static List<String> _sentCharacters(String text) {
    final kept = <String>[];
    for (final rune in text.runes) {
      final character = String.fromCharCode(rune);
      if (character.trim().isEmpty) continue;
      if (encodeMorse(character).isEmpty) continue;
      kept.add(character == 'ß' ? character : character.toUpperCase());
    }
    return kept;
  }
}

/// Every sign, grouped the way the Recommendation groups them, with the
/// extensions kept apart and labelled as such.
class _MorseChart extends StatelessWidget {
  const _MorseChart();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    Widget section(String title, List<(String, String)> signs, {String? note}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            if (note != null) ...[
              const SizedBox(height: 4),
              Text(note, style: theme.textTheme.bodySmall),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (label, code) in signs)
                  _SignTile(
                    label: label,
                    code: code,
                    dot: l10n.morseDotSpoken,
                    dash: l10n.morseDashSpoken,
                  ),
              ],
            ),
          ],
        ),
      );
    }

    List<(String, String)> of(List<MorseSymbol> symbols) => [
      for (final symbol in symbols) (symbol.character, symbol.code),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        section(l10n.morseChartLetters, of(morseLetters)),
        section(l10n.morseChartDigits, of(morseDigits)),
        section(l10n.morseChartPunctuation, of(morsePunctuation)),
        section(
          l10n.morseChartExtensions,
          of(morseExtensions),
          note: l10n.morseChartExtensionsNote,
        ),
        section(l10n.morseChartProsigns, [
          for (final prosign in MorseProsign.values)
            (_prosignName(l10n, prosign), prosign.code),
        ]),
        Text(l10n.morseSource, style: theme.textTheme.bodySmall),
      ],
    );
  }

  static String _prosignName(AppLocalizations l10n, MorseProsign prosign) =>
      switch (prosign) {
        MorseProsign.sos => l10n.morseProsignSos,
        MorseProsign.error => l10n.morseProsignError,
        MorseProsign.understood => l10n.morseProsignUnderstood,
        MorseProsign.wait => l10n.morseProsignWait,
        MorseProsign.start => l10n.morseProsignStart,
        MorseProsign.endOfMessage => l10n.morseProsignEndOfMessage,
        MorseProsign.endOfWork => l10n.morseProsignEndOfWork,
      };
}

class _SignTile extends StatelessWidget {
  const _SignTile({
    required this.label,
    required this.code,
    required this.dot,
    required this.dash,
  });

  final String label;
  final String code;

  /// How a screen reader says the elements: "kurz", "lang".
  final String dot;
  final String dash;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // One node per sign, so a screen reader steps through the table sign
    // by sign; without `container` a whole group merged into one label.
    // Said in words, not as the names of two punctuation marks.
    final spoken = code.split('').map((e) => e == '.' ? dot : dash).join(' ');
    return Semantics(
      container: true,
      label: '$label: $spoken',
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minWidth: 96),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: theme.textTheme.titleMedium),
            Text(
              drawMorse(code),
              style: theme.textTheme.titleMedium?.copyWith(
                letterSpacing: 2,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
