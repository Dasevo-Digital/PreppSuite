import 'dart:async' show unawaited;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'warning_translations.dart';

const _extraLanguageKey = 'warningExtraLanguage';

/// A second language to show each warning in, beside the app's own (#357).
///
/// Leichte Sprache for somebody who reads German with difficulty, Turkish
/// or Arabic for a relative staying with the household. Kept on this
/// device and not carried with the household: who reads this screen is a
/// matter of the device, not of the household.
class WarningExtraLanguageController extends Notifier<String?> {
  @override
  String? build() {
    unawaited(_load());
    return null;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_extraLanguageKey);
    if (!ref.mounted) return;
    state = warningTranslationLanguages.contains(stored) ? stored : null;
  }

  Future<void> choose(String? language) async {
    final value = warningTranslationLanguages.contains(language)
        ? language
        : null;
    state = value;
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(_extraLanguageKey);
    } else {
      await prefs.setString(_extraLanguageKey, value);
    }
  }
}

final warningExtraLanguageProvider =
    NotifierProvider<WarningExtraLanguageController, String?>(
      WarningExtraLanguageController.new,
    );
