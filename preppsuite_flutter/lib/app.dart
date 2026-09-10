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
      // Nothing in this app was selectable. A Flutter `Text` is not, on
      // its own, and there are 667 of them against no `SelectableText` and
      // no `SelectionArea` at all — so right-click-copy worked inside
      // input fields and nowhere else, which reads as "it works sometimes"
      // rather than "it is missing".
      //
      // It matters more here than in most apps: the numbers people want to
      // pass on are all read-only labels. How many litres are still
      // needed, the Kreisschlüssel, a shelter's name and distance, the
      // wording of an official warning.
      //
      // Wrapped around the whole app rather than per screen, having
      // measured that it takes nothing away: a map still pans, a list
      // still scrolls and a slider still drags inside one, because those
      // recognizers win the gesture arena. See selection_test.dart, which
      // keeps that true.
      home: const SelectionArea(child: HouseholdGate()),
    );
  }
}
