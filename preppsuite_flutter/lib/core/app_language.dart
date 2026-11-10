import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/generated/app_localizations.dart';

/// The app's language where there is no widget tree to ask: the background
/// worker, and a controller announcing a warning.
///
/// The choice in the settings, else the system's, else the first the app
/// has, which is how `MaterialApp` resolves it too.
Future<Locale> appLocaleWithoutContext() async {
  final prefs = await SharedPreferences.getInstance();
  final wanted =
      prefs.getString('localeOverride') ??
      PlatformDispatcher.instance.locale.languageCode;
  final supported = AppLocalizations.supportedLocales;
  return supported.contains(Locale(wanted)) ? Locale(wanted) : supported.first;
}
