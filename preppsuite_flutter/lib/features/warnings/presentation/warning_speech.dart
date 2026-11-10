import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../local_db/database.dart';
import '../../../model/categories.dart';
import '../../first_aid/application/step_speech.dart';
import '../../phrasebook/application/phrasebook.dart' show PhraseLanguage;
import '../../phrasebook/presentation/phrase_display.dart'
    show phraseSpeechProvider, phraseVoiceProvider;
import '../application/warning_translations.dart';

/// Reading a warning out loud (#201).
///
/// For whoever cannot read it right now: without glasses, with poor
/// sight, or with the phone across the room at night. The device's own
/// voices, offline, through the same engine and the same voice lookup as
/// the phrasebook; where the device has no voice for the language, or the
/// platform none at all (Linux), there is no button.
///
/// What is read is the publisher's text and nothing of the app's. The
/// labels around it are in the app's language and the warning in the
/// publisher's, and one voice cannot read both: the BBK writes German,
/// the MeteoAlarm feed English. So a German warning is read in German in
/// a Spanish app too -- it is German text.
PhraseLanguage warningLanguage(WarningSource source) => switch (source) {
  WarningSource.bbk => PhraseLanguage.de,
  WarningSource.meteoalarm => PhraseLanguage.en,
};

/// Headline, description and what to do, in that order, in [language]
/// where the BBK translated into it (#357).
String warningSpeechText(Warning warning, {String language = 'de'}) {
  final text = warning.textIn(language);
  return [
    text.headline,
    ?text.description,
    ?text.instruction,
  ].where((part) => part.trim().isNotEmpty).join('\n');
}

class SpeakWarningButton extends ConsumerStatefulWidget {
  const SpeakWarningButton({
    super.key,
    required this.warning,
    required this.source,
  });

  final Warning warning;
  final WarningSource source;

  @override
  ConsumerState<SpeakWarningButton> createState() => _SpeakWarningButtonState();
}

class _SpeakWarningButtonState extends ConsumerState<SpeakWarningButton> {
  late final StepSpeech _speech;
  bool _speaking = false;

  @override
  void initState() {
    super.initState();
    // Kept, not read again: closing the details stops the voice, and by
    // then the widget may no longer ask anything of the container.
    _speech = ref.read(phraseSpeechProvider);
  }

  @override
  void dispose() {
    if (_speaking) _speech.stop();
    super.dispose();
  }

  Future<void> _toggle(String voice) async {
    if (_speaking) {
      setState(() => _speaking = false);
      await _speech.stop();
      return;
    }
    setState(() => _speaking = true);
    await _speech.speak(
      warningSpeechText(widget.warning, language: _language(context)),
      languageCode: voice,
    );
  }

  /// The app's language when the warning is translated into it, so that
  /// the words and the voice match.
  String _language(BuildContext context) {
    final app = Localizations.localeOf(context).languageCode;
    return widget.warning.isTranslatedFor(app) ? app : 'de';
  }

  @override
  Widget build(BuildContext context) {
    final language = _language(context);
    final voice = ref
        .watch(
          phraseVoiceProvider(
            language == 'de'
                ? warningLanguage(widget.source)
                : PhraseLanguage.values.byName(language),
          ),
        )
        .value;
    if (voice == null) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    return TextButton.icon(
      onPressed: () => _toggle(voice),
      icon: Icon(
        _speaking ? Icons.stop_circle_outlined : Icons.volume_up_outlined,
      ),
      label: Text(
        _speaking ? l10n.warningStopReading : l10n.warningReadAloud,
      ),
    );
  }
}
