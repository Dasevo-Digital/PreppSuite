import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_database_providers.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../checklists/application/checklist_seeder.dart';
import '../../home/presentation/home_shell.dart';
import '../../sharing/application/sharing_providers.dart';
import '../application/household_providers.dart';
import 'profile_setup_screen.dart';

/// Shows first-run setup until a profile exists, then the app.
///
/// What used to be two gates — sign in, then pick a household — is one,
/// because there is nothing to sign in to.
///
/// Also the place the shared-folder sync is started from. It has to be
/// somewhere that runs on every launch: the provider does nothing until
/// something reads it, and a sync that only happens while the settings
/// screen is open is not a sync.
class HouseholdGate extends ConsumerStatefulWidget {
  const HouseholdGate({super.key});

  @override
  ConsumerState<HouseholdGate> createState() => _HouseholdGateState();
}

class _HouseholdGateState extends ConsumerState<HouseholdGate> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();

    // Read rather than watch: this only has to bring the controller to
    // life — which starts its timer and its first run — without rebuilding
    // the whole app every time a sync begins or ends.
    ref.read(sharedFolderProvider);

    // Coming back to the app is the moment someone actually wants to see
    // what the others changed, and on mobile it is also when the periodic
    // timer has been frozen for however long the app was away.
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.read(sharedFolderProvider.notifier).syncNow(),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
