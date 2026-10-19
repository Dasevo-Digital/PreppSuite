import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error_text.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../phrasebook/application/phrasebook.dart';
import '../../phrasebook/presentation/phrase_display.dart';
import '../application/translator_catalogue.dart';
import '../application/translator_providers.dart';
import '../application/translator_store.dart';
import 'translator_screen.dart' show TranslatorMissingPacks;

/// One message of a conversation, and what it became in the other
/// language.
class ConversationTurn {
  const ConversationTurn({
    required this.from,
    required this.text,
    this.translation,
    this.error,
  });

  final PhraseLanguage from;
  final String text;

  /// Null while it is being translated, or when that failed.
  final String? translation;
  final Object? error;
}

/// Two people, two languages, one device between them (#202).
///
/// The translator answers one way: it shows the other person a sentence,
/// and then they have nothing to answer with. Here the screen is split.
/// The lower half belongs to whoever holds the device, the upper half to
/// the person across the table, turned upside down on a phone so it reads
/// the right way round from there. Each half shows the whole conversation
/// in its own language and has a field of its own; what is written on
/// one side arrives translated on the other.
///
/// The prompt in each field is the phrasebook's fixed sentence in that
/// half's language, not a machine translation of the app's wording -- the
/// one place a wrong word would leave somebody not knowing what to do.
class TranslatorConversationScreen extends ConsumerStatefulWidget {
  const TranslatorConversationScreen({
    super.key,
    required this.mine,
    required this.theirs,
    this.opening,
  });

  final PhraseLanguage mine;
  final PhraseLanguage theirs;

  /// A translation already made on the translator screen, which becomes
  /// the first turn rather than having to be typed again.
  final ConversationTurn? opening;

  @override
  ConsumerState<TranslatorConversationScreen> createState() =>
      _TranslatorConversationScreenState();
}

class _TranslatorConversationScreenState
    extends ConsumerState<TranslatorConversationScreen> {
  late final _turns = <ConversationTurn>[?widget.opening];

  /// Whether the upper half is turned round. Null until the person
  /// chooses: then it follows the screen, turned on a phone that lies
  /// between two people and not on a computer, where they sit side by
  /// side.
  bool? _flipped;

  Future<void> _send(
    PhraseLanguage from,
    String text,
    Map<TranslatorDirection, InstalledTranslatorPack> present,
  ) async {
    final to = from == widget.mine ? widget.theirs : widget.mine;
    final turn = ConversationTurn(from: from, text: text);
    setState(() => _turns.add(turn));
    ConversationTurn done;
    try {
      final translation = await ref.read(translateTextProvider)(text, [
        for (final direction in directionsFor(from, to)) present[direction]!,
      ]);
      done = ConversationTurn(from: from, text: text, translation: translation);
    } on Object catch (error) {
      done = ConversationTurn(from: from, text: text, error: error);
    }
    if (!mounted) return;
    setState(() => _turns[_turns.indexOf(turn)] = done);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final installed =
        ref.watch(installedTranslatorPacksProvider).value ??
        const <InstalledTranslatorPack>[];
    final present = {for (final pack in installed) pack.direction: pack};
    final missing = {
      for (final direction in [
        ...directionsFor(widget.mine, widget.theirs),
        ...directionsFor(widget.theirs, widget.mine),
      ])
        if (!present.containsKey(direction)) direction,
    }.toList();
    final flipped = _flipped ?? MediaQuery.sizeOf(context).shortestSide < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.mine.endonym} ↔ ${widget.theirs.endonym}',
        ),
        actions: [
          IconButton(
            tooltip: l10n.translatorConversationFlip,
            isSelected: flipped,
            icon: const Icon(Icons.screen_rotation_alt_outlined),
            onPressed: () => setState(() => _flipped = !flipped),
          ),
        ],
      ),
      body: missing.isNotEmpty
          ? ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(l10n.translatorConversationNeedsBoth),
                const SizedBox(height: 12),
                TranslatorMissingPacks(missing: missing),
              ],
            )
          : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: RotatedBox(
                      quarterTurns: flipped ? 2 : 0,
                      child: _Side(
                        language: widget.theirs,
                        turns: _turns,
                        onSend: (text) => _send(widget.theirs, text, present),
                      ),
                    ),
                  ),
                  const Divider(height: 1, thickness: 2),
                  Expanded(
                    child: _Side(
                      language: widget.mine,
                      turns: _turns,
                      onSend: (text) => _send(widget.mine, text, present),
                      note: l10n.translatorMachineNote,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

/// One person's half: the conversation in their language, and their
/// field.
class _Side extends StatefulWidget {
  const _Side({
    required this.language,
    required this.turns,
    required this.onSend,
    this.note,
  });

  final PhraseLanguage language;
  final List<ConversationTurn> turns;
  final ValueChanged<String> onSend;
  final String? note;

  @override
  State<_Side> createState() => _SideState();
}

class _SideState extends State<_Side> {
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    _input.clear();
    widget.onSend(text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final language = widget.language;
    final direction = language.isRtl ? TextDirection.rtl : TextDirection.ltr;
    final turns = widget.turns.reversed.toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: turns.length,
              itemBuilder: (context, index) =>
                  _Bubble(turn: turns[index], language: language),
            ),
          ),
          if (widget.note case final note?)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(note, style: theme.textTheme.bodySmall),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _input,
                  textDirection: direction,
                  minLines: 1,
                  maxLines: 3,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    hintText: _writeHere[language],
                    hintTextDirection: direction,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                tooltip: l10n.translatorTranslate,
                icon: const Icon(Icons.send),
                onPressed: _submit,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

final Phrase _writeHere = phrasebookPhrases.firstWhere(
  (phrase) => phrase.id == 'writeHere',
);

/// A message as one half sees it: what this person wrote, or what the
/// other one wrote, in this person's language.
class _Bubble extends StatelessWidget {
  const _Bubble({required this.turn, required this.language});

  final ConversationTurn turn;
  final PhraseLanguage language;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final own = turn.from == language;
    final direction = language.isRtl ? TextDirection.rtl : TextDirection.ltr;
    final error = turn.error;
    final translation = turn.translation;

    final Widget content;
    if (own) {
      content = Text(turn.text, textDirection: direction);
    } else if (error != null) {
      content = Text(
        l10n.translatorFailed(describeError(l10n, error)),
        style: TextStyle(color: theme.colorScheme.error),
      );
    } else if (translation == null) {
      content = const SizedBox.square(
        dimension: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    } else {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              translation,
              textDirection: direction,
              style: theme.textTheme.titleMedium,
            ),
          ),
          SpeakPhraseButton(text: translation, language: language),
        ],
      );
    }

    return Align(
      alignment: own
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: const BoxConstraints(maxWidth: 520),
        decoration: BoxDecoration(
          color: own
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: content,
      ),
    );
  }
}
