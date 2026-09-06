import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/locale_provider.dart';
import 'core/theme_provider.dart';
import 'features/household/presentation/household_gate.dart';
import 'l10n/generated/app_localizations.dart';

/// Forest green — chosen for the prepper/civil-protection theme rather
/// than a generic Material default; used as the seed for both light and
/// dark schemes so accents stay green in either mode.
const appSeedColor = Color(0xFF2E7D32);

class PreppSuiteApp extends ConsumerWidget {
  const PreppSuiteApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      locale: ref.watch(localeOverrideProvider),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(colorSchemeSeed: appSeedColor, useMaterial3: true),
      darkTheme: ThemeData(
        colorSchemeSeed: appSeedColor,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      themeMode: ref.watch(themeModeProvider),
      home: const HouseholdGate(),
    );
  }
}
