import 'dart:async' show unawaited;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _localeOverridePrefsKey = 'localeOverride';

/// The user's explicit language choice from Settings, or `null` to follow
/// the OS locale (the default — Flutter resolves this automatically via
/// `MaterialApp.supportedLocales` when `locale` is null).
class LocaleOverrideController extends Notifier<Locale?> {
  @override
  Locale? build() {
    // Starts as "follow system" (null) until the stored preference loads;
    // the brief flash back to system locale on cold start is an acceptable
    // trade-off for not blocking app startup on a prefs read.
    unawaited(_loadInitial());
    return null;
  }

  Future<void> _loadInitial() async {
    final prefs = await SharedPreferences.getInstance();
    // The provider can be disposed while this await is in flight (e.g. the
    // app never leaves the sign-in screen); writing to `state` after that
    // throws, per Riverpod's own guidance on checking `mounted` after an
    // async gap.
    if (!ref.mounted) return;
    final code = prefs.getString(_localeOverridePrefsKey);
    if (code != null) state = Locale(code);
  }

  Future<void> setLocale(Locale? locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(_localeOverridePrefsKey);
    } else {
      await prefs.setString(_localeOverridePrefsKey, locale.languageCode);
    }
  }
}

final localeOverrideProvider = NotifierProvider<LocaleOverrideController, Locale?>(
  LocaleOverrideController.new,
);
