import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:preppsuite_client/preppsuite_client.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';

import '../../../core/locale_provider.dart';
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
            onPressed: () => client.auth.signOutDevice(),
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
          const SizedBox(height: 24),
          Text(
            l10n.settingsSectionTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: Text(l10n.languageLabel),
                  trailing: _LanguagePicker(l10n: l10n),
                ),
                const Divider(height: 1),
                ListTile(
                  title: Text(l10n.serverAddressLabel),
                  subtitle: SelectableText(serverUrl),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguagePicker extends ConsumerWidget {
  const _LanguagePicker({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(localeOverrideProvider);

    return DropdownButton<Locale?>(
      value: current,
      underline: const SizedBox.shrink(),
      items: [
        DropdownMenuItem(value: null, child: Text(l10n.languageSystemOption)),
        DropdownMenuItem(
          value: const Locale('de'),
          child: Text(l10n.languageGermanOption),
        ),
        DropdownMenuItem(
          value: const Locale('en'),
          child: Text(l10n.languageEnglishOption),
        ),
      ],
      onChanged: (locale) =>
          ref.read(localeOverrideProvider.notifier).setLocale(locale),
    );
  }
}
