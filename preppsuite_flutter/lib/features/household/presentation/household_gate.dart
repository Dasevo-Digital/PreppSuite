import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_database_providers.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../checklists/application/checklist_seeder.dart';
import '../../home/presentation/home_shell.dart';
import '../application/household_providers.dart';
import 'profile_setup_screen.dart';

/// Shows first-run setup until a profile exists, then the app.
///
/// What used to be two gates — sign in, then pick a household — is one,
/// because there is nothing to sign in to.
class HouseholdGate extends ConsumerWidget {
  const HouseholdGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final profile = ref.watch(householdProfileProvider);

    return profile.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Scaffold(
        body: Center(child: Text(l10n.errorGeneric(error.toString()))),
      ),
      data: (profile) {
        if (profile == null) return const ProfileSetupScreen();

        // Cheap and idempotent, so it runs on every launch rather than
        // needing a "has this been seeded" flag that could go stale.
        ChecklistSeeder(ref.watch(appDatabaseProvider)).seed(profile.id);

        return HomeShell(profile: profile);
      },
    );
  }
}
