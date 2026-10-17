import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../first_aid/application/step_speech.dart';
import '../application/phrasebook.dart';

/// Reading a sentence out, for the phrasebook and the translator (#189).
///
/// For the person on the other side who cannot read it -- a child, someone
/// without their glasses, someone who never learned the script -- and for
/// the one holding the phone, who cannot pronounce it. The device's own
/// voices, offline, as the first aid read-aloud uses them; a language this
/// device has no voice for gets no button rather than one that reads
/// Persian with an English voice.
final phraseSpeechProvider = Provider<StepSpeech>(
  (ref) => PlatformStepSpeech(),
);

/// The voice tags to try for [language], most specific first.
///
/// Platforms name their voices differently: macOS calls its Arabic voice
/// `ar-001`, Android's engines `ar-SA` or plain `ar`. The first one the
/// engine says it has is the one used.
List<String> phraseSpeechTags(PhraseLanguage language) => switch (language) {
  PhraseLanguage.de => const ['de-DE', 'de'],
  PhraseLanguage.en => const ['en-GB', 'en-US', 'en'],
  PhraseLanguage.es => const ['es-ES', 'es'],
  PhraseLanguage.fr => const ['fr-FR', 'fr'],
  PhraseLanguage.pl => const ['pl-PL', 'pl'],
  PhraseLanguage.tr => const ['tr-TR', 'tr'],
  PhraseLanguage.ru => const ['ru-RU', 'ru'],
  PhraseLanguage.uk => const ['uk-UA', 'uk'],
  PhraseLanguage.ar => const ['ar-SA', 'ar-001', 'ar'],
  PhraseLanguage.fa => const ['fa-IR', 'fa'],
};

/// The tag this device can speak [language] with, or null.
Future<String?> phraseVoiceFor(
  StepSpeech speech,
  PhraseLanguage language,
) async {
  for (final tag in phraseSpeechTags(language)) {
    if (await speech.isAvailable(tag)) return tag;
  }
  return null;
}

/// The voice for each language, asked once: the phrasebook shows a button
/// on every sentence, and each one asking the engine would be dozens of
/// platform calls for the same answer.
final phraseVoiceProvider = FutureProvider.family<String?, PhraseLanguage>(
  (ref, language) => phraseVoiceFor(ref.watch(phraseSpeechProvider), language),
);

/// A button that reads [text] out in [language], or nothing at all where
/// the device has no voice for it.
class SpeakPhraseButton extends ConsumerWidget {
  const SpeakPhraseButton({
    super.key,
    required this.text,
    required this.language,
  });

  final String text;
  final PhraseLanguage language;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voice = ref.watch(phraseVoiceProvider(language)).value;
    if (voice == null) return const SizedBox.shrink();
    return IconButton(
      tooltip: AppLocalizations.of(context)!.phraseSpeak,
      icon: const Icon(Icons.volume_up_outlined),
      onPressed: () =>
          ref.read(phraseSpeechProvider).speak(text, languageCode: voice),
    );
  }
}

/// The sentence alone, as large as the screen allows, to be held up --
/// with [source] small underneath, so the person holding it knows what
/// they are showing.
Future<void> showPhraseLarge(
  BuildContext context, {
  required String target,
  required String source,
  required PhraseLanguage language,
}) {
  final theme = Theme.of(context);
  return showDialog<void>(
    context: context,
    builder: (context) => Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [SpeakPhraseButton(text: target, language: language)],
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    target,
                    textAlign: TextAlign.center,
                    textDirection: language.isRtl
                        ? TextDirection.rtl
                        : TextDirection.ltr,
                    style: theme.textTheme.displaySmall,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    source,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
