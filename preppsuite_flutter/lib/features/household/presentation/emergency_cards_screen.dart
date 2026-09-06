import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../local_db/database.dart';
import '../../sharing/presentation/folder_encryption_section.dart';
import '../application/household_member_controller.dart';
import 'emergency_card_form_screen.dart';

/// The household's people, and what an ambulance would want to know.
class EmergencyCardsScreen extends ConsumerWidget {
  const EmergencyCardsScreen({super.key, required this.householdId});

  final String householdId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final membersAsync = ref.watch(householdMembersProvider(householdId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.emergencyCardsTitle)),
      body: membersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(l10n.errorGeneric('$error'))),
        data: (members) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            Text(l10n.emergencyCardsIntro, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
            const _HealthDataNotice(),
            const SizedBox(height: 12),
            if (members.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  l10n.emergencyCardsEmpty,
                  style: theme.textTheme.bodyLarge,
                ),
              )
            else
              for (final member in members)
                _MemberCard(
                  member: member,
                  householdId: householdId,
                  l10n: l10n,
                ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => EmergencyCardFormScreen(
              householdId: householdId,
              sortOrder: membersAsync.value?.length ?? 0,
            ),
          ),
        ),
        icon: const Icon(Icons.person_add_outlined),
        label: Text(l10n.emergencyCardAdd),
      ),
    );
  }
}

/// Says what this data is and where it goes, before anyone types it in.
///
/// Not a footnote: everything on this screen travels through the shared
/// folder to every device, and until that folder is encrypted it is
/// readable by whoever hosts it. Someone deciding whether to write down a
/// diagnosis deserves to know that first.
class _HealthDataNotice extends ConsumerWidget {
  const _HealthDataNotice();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final encrypted = ref.watch(folderEncryptedProvider).value;

    // No shared folder at all: nothing leaves the device, so there is
    // nothing to warn about.
    if (encrypted == null) return const SizedBox.shrink();

    final (background, foreground, icon) = encrypted
        ? (
            theme.colorScheme.secondaryContainer,
            theme.colorScheme.onSecondaryContainer,
            Icons.lock_outline,
          )
        : (
            theme.colorScheme.errorContainer,
            theme.colorScheme.onErrorContainer,
            Icons.lock_open_outlined,
          );

    return Card(
      color: background,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: foreground, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                encrypted
                    ? l10n.emergencyCardsHealthEncrypted
                    : l10n.emergencyCardsHealthWarning,
                style: theme.textTheme.bodySmall?.copyWith(color: foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberCard extends ConsumerWidget {
  const _MemberCard({
    required this.member,
    required this.householdId,
    required this.l10n,
  });

  final HouseholdMember member;
  final String householdId;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              foregroundColor: theme.colorScheme.onPrimaryContainer,
              child: Text(_initial(member.name)),
            ),
            title: Text(member.name),
            subtitle: member.birthYear == null
                ? null
                : Text('${member.birthYear}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: l10n.emergencyCardEdit,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EmergencyCardFormScreen(
                        householdId: householdId,
                        existing: member,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  // Names the person: in a household of five, five
                  // buttons called "remove" are five chances to pick the
                  // wrong one.
                  tooltip: l10n.emergencyCardRemoveConfirm(member.name),
                  onPressed: () => _remove(context, ref),
                ),
              ],
            ),
          ),
          for (final line in _lines())
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 140,
                    child: Text(
                      line.$1,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(line.$2, style: theme.textTheme.bodyMedium),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  /// Only the fields that were filled in. An empty row would read as
  /// "no allergies" when it means "nobody said".
  List<(String, String)> _lines() => [
    if (member.bloodType != null)
      (l10n.emergencyCardBloodType, member.bloodType!),
    if (member.allergies != null)
      (l10n.emergencyCardAllergies, member.allergies!),
    if (member.medication != null)
      (l10n.emergencyCardMedication, member.medication!),
    if (member.conditions != null)
      (l10n.emergencyCardConditions, member.conditions!),
    if (member.insurance != null)
      (l10n.emergencyCardInsurance, member.insurance!),
    if (member.doctor != null) (l10n.emergencyCardDoctor, member.doctor!),
    if (member.emergencyContact != null)
      (l10n.emergencyCardContact, member.emergencyContact!),
    if (member.notes != null) (l10n.emergencyCardNotes, member.notes!),
  ];

  static String _initial(String name) {
    final trimmed = name.trim();
    return trimmed.isEmpty ? '?' : trimmed.characters.first.toUpperCase();
  }

  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.emergencyCardRemoveConfirm(member.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.deleteButton),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await ref
        .read(householdMemberControllerProvider(householdId))
        .remove(member);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.emergencyCardRemoved)));
  }
}
