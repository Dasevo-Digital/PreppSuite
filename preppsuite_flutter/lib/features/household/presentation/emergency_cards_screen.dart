import 'package:flutter/material.dart';

import '../../../core/feel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../core/content_swap.dart';
import '../../../local_db/database.dart';
import '../../sharing/presentation/folder_encryption_section.dart';
import '../application/card_people.dart';
import '../application/household_member_controller.dart';
import 'emergency_card_form_screen.dart';
import '../../../core/error_text.dart';

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
      body: ContentSwap(
        child: membersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text(describeError(l10n, error))),
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
                      line.label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Expanded(
                    child: line.phone == null
                        ? Text(line.value, style: theme.textTheme.bodyMedium)
                        : _CallableValue(
                            value: line.value,
                            phone: line.phone!,
                          ),
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
  List<_CardLine> _lines() => [
    if (member.bloodType != null)
      (
        label: l10n.emergencyCardBloodType,
        value: member.bloodType!,
        phone: null,
      ),
    if (member.allergies != null)
      (
        label: l10n.emergencyCardAllergies,
        value: member.allergies!,
        phone: null,
      ),
    if (member.medication != null)
      (
        label: l10n.emergencyCardMedication,
        value: member.medication!,
        phone: null,
      ),
    if (member.conditions != null)
      (
        label: l10n.emergencyCardConditions,
        value: member.conditions!,
        phone: null,
      ),
    if (member.insurance != null)
      (
        label: l10n.emergencyCardInsurance,
        value: member.insurance!,
        phone: null,
      ),
    ..._people(l10n.emergencyCardDoctor, member.doctor),
    ..._people(l10n.emergencyCardContact, member.emergencyContact),
    if (member.notes != null)
      (label: l10n.emergencyCardNotes, value: member.notes!, phone: null),
  ];

  /// One row per doctor, and one per person to ring.
  ///
  /// The heading is written once and the rest of the group runs under it
  /// without repeating it — four rows all labelled "Ärztin oder Arzt"
  /// would be a label doing no work. The number is carried separately so
  /// it can be dialled; on this screen, of all screens, reading a phone
  /// number off the glass and typing it again is the wrong ending.
  Iterable<_CardLine> _people(String label, String? stored) sync* {
    final people = parseCardPeople(stored);
    for (var index = 0; index < people.length; index++) {
      final person = people[index];
      yield (
        label: index == 0 ? label : '',
        value: person.line,
        phone: person.phone.trim().isEmpty ? null : person.phone.trim(),
      );
    }
  }

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
    Feel.removed();

    await ref
        .read(householdMemberControllerProvider(householdId))
        .remove(member);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.emergencyCardRemoved)));
  }
}

/// One row of a card: what it is called, what it says, and the number in
/// it if there is one.
typedef _CardLine = ({String label, String value, String? phone});

/// A row whose number can be dialled.
///
/// The whole line stays selectable text rather than becoming a link:
/// "Anna Weber (Partnerin) · 0170 987" is a sentence, and only the last
/// part of it is a telephone number.
class _CallableValue extends StatelessWidget {
  const _CallableValue({required this.value, required this.phone});

  final String value;
  final String phone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        IconButton(
          visualDensity: VisualDensity.compact,
          iconSize: 20,
          icon: const Icon(Icons.call_outlined),
          tooltip: phone,
          // Silent where there is no dialler: a desktop without one is
          // not a fault to report, and the number is right there to read.
          onPressed: () => launchUrl(
            Uri(scheme: 'tel', path: phone.replaceAll(' ', '')),
          ).catchError((_) => false),
        ),
      ],
    );
  }
}
