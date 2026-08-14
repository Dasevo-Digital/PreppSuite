import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../home/presentation/home_shell.dart';
import '../application/household_providers.dart';
import 'onboarding_choice_screen.dart';

/// Shows onboarding (create/join) if the signed-in user has no household
/// yet, otherwise the household overview.
class HouseholdGate extends ConsumerWidget {
  const HouseholdGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final membership = ref.watch(myHouseholdProvider);

    return membership.when(
      loading: () => Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(l10n.loadingHousehold),
            ],
          ),
        ),
      ),
      error: (error, stackTrace) => Scaffold(
        body: Center(child: Text(l10n.errorGeneric(error.toString()))),
      ),
      data: (info) => info == null
          ? const OnboardingChoiceScreen()
          : HomeShell(membership: info),
    );
  }
}
