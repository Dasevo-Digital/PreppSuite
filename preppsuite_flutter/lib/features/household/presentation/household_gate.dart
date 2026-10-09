import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_database_providers.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../checklists/application/checklist_seeder.dart';
import '../../home/presentation/home_shell.dart';
import '../../sharing/application/sharing_providers.dart';
import '../application/household_providers.dart';
import 'setup_choice_screen.dart';
import '../../../core/error_text.dart';
import '../../../core/emergency_access.dart';

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

  /// The household whose built-in checklists have already been written on
  /// this run. See [_seedChecklists].
  String? _seededFor;

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

  /// Writes the built-in checklists, once per household per launch.
  ///
  /// Still not behind a stored "has this been seeded" flag: such a flag
  /// goes stale the moment the shipped set grows, and the seeder is
  /// deliberately idempotent so that running it again is free of
  /// consequence. What it is not is free of cost -- it reads all eighteen
  /// templates -- and this used to sit unguarded in `build`, so it ran
  /// again on every rebuild of this widget rather than once at start.
  ///
  /// Fire-and-forget on purpose: nothing on screen waits for it. The
  /// checklists arrive through a stream, so the tab fills in when the
  /// write lands.
  void _seedChecklists(String householdId) {
    if (_seededFor == householdId) return;
    _seededFor = householdId;
    ChecklistSeeder(ref.read(appDatabaseProvider)).seed(householdId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profile = ref.watch(householdProfileProvider);

    return profile.when(
      loading: () => const LoadingWithEmergencyAccess(),
      // A database that does not open used to leave only this sentence,
      // and with it no way to 112 or to first aid -- neither of which
      // needs the database (#136).
      error: (error, stackTrace) => Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.error_outline, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    l10n.householdLoadFailedTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(describeError(l10n, error), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => ref.invalidate(householdProfileProvider),
                    child: Text(l10n.householdLoadRetry),
                  ),
                  const SizedBox(height: 24),
                  const EmergencyAccessButton(),
                ],
              ),
            ),
          ),
        ),
      ),
      data: (profile) {
        if (profile == null) return const SetupChoiceScreen();

        _seedChecklists(profile.id);

        return HomeShell(profile: profile);
      },
    );
  }
}
