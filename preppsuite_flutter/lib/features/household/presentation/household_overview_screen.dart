import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:preppsuite_client/preppsuite_client.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';

import '../../../core/push_registration_provider.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../main.dart';
import '../application/household_exception_l10n.dart';
import '../application/household_providers.dart';

class HouseholdOverviewScreen extends ConsumerWidget {
  const HouseholdOverviewScreen({super.key, required this.membership});

  final HouseholdMembershipInfo membership;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final household = membership.household;
    final isOwner = membership.member.role == HouseholdRole.owner;
    final membersAsync = ref.watch(
      householdMembersProvider(household.id!),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(household.name),
        actions: [
          IconButton(
            tooltip: l10n.signOutButton,
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(ref),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l10n.inviteCodeSectionTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              title: SelectableText(
                household.inviteCode,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              trailing: Wrap(
                spacing: 4,
                children: [
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () => Clipboard.setData(
                      ClipboardData(text: household.inviteCode),
                    ),
                  ),
                  if (isOwner)
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: l10n.rotateInviteCodeButton,
                      onPressed: () async {
                        try {
                          await client.household.rotateInviteCode(
                            household.id!,
                          );
                          ref.invalidate(myHouseholdProvider);
                        } catch (error) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  localizeHouseholdError(l10n, error),
                                ),
                              ),
                            );
                          }
                        }
                      },
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.membersSectionTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          membersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) =>
                Text(localizeHouseholdError(l10n, error)),
            data: (members) => Card(
              child: Column(
                children: [
                  for (final member in members)
                    ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(member.displayName),
                      trailing: Text(
                        member.role == HouseholdRole.owner
                            ? l10n.roleOwner
                            : l10n.roleMember,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Revokes this device's push registration before dropping the session.
  ///
  /// Order matters: the call needs the token that is about to be thrown
  /// away. Signing out first would leave the server pushing this
  /// household's warnings to a phone that no longer belongs to it, with no
  /// way left to say otherwise.
  Future<void> _signOut(WidgetRef ref) async {
    await unregisterPushOnSignOut(ref.read(pushRegistrationServiceProvider));
    await client.auth.signOutDevice();
  }
}
