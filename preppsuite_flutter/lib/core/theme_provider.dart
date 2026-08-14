import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _themeModePrefsKey = 'themeModeOverride';

/// The user's explicit light/dark choice from Settings, or [ThemeMode.system]
/// (the default) to follow the OS setting. Mirrors `locale_provider.dart`'s
/// shape exactly.
class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    // Starts as "follow system" until the stored preference loads; same
    // brief-flash trade-off as LocaleOverrideController for not blocking
    // app startup on a prefs read.
    unawaited(_loadInitial());
    return ThemeMode.system;
  }

  Future<void> _loadInitial() async {
    final prefs = await SharedPreferences.getInstance();
    // See LocaleOverrideController for why this guard is needed after an
    // async gap.
    if (!ref.mounted) return;
    final name = prefs.getString(_themeModePrefsKey);
    if (name != null) {
      state = ThemeMode.values.asNameMap()[name] ?? ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModePrefsKey, mode.name);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);
