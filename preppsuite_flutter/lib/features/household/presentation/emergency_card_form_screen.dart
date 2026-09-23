import 'package:flutter/material.dart';

import '../../../core/feel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error_text.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../local_db/database.dart';
import '../application/card_people.dart';
import '../application/household_member_controller.dart';

/// One person's emergency card.
///
/// Only the name is required. Every medical field is optional on purpose:
/// a form that insisted on a blood type would be abandoned, and a card
/// that says "Lena, allergic to penicillin" is already worth having.
class EmergencyCardFormScreen extends ConsumerStatefulWidget {
  const EmergencyCardFormScreen({
    super.key,
    required this.householdId,
    this.existing,
    this.sortOrder,
  });

  final String householdId;
  final HouseholdMember? existing;

  /// Where a new card goes in the household's own order.
  final int? sortOrder;

  @override
  ConsumerState<EmergencyCardFormScreen> createState() =>
      _EmergencyCardFormScreenState();
}

class _EmergencyCardFormScreenState
    extends ConsumerState<EmergencyCardFormScreen> {
  final _fields = <String, TextEditingController>{};

  /// One editable row per doctor and per person to ring. Both were one
  /// line each until 1.9.8 — see [CardPerson] for why they are stored
  /// the way they are.
  late List<_PersonRow> _doctors;
  late List<_PersonRow> _contacts;

  String? _nameError;
  String? _yearError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _fields['name'] = TextEditingController(text: existing?.name ?? '');
    _fields['year'] = TextEditingController(
      text: existing?.birthYear?.toString() ?? '',
    );
    _fields['blood'] = TextEditingController(text: existing?.bloodType ?? '');
    _fields['allergies'] = TextEditingController(
      text: existing?.allergies ?? '',
    );
    _fields['medication'] = TextEditingController(
      text: existing?.medication ?? '',
    );
    _fields['conditions'] = TextEditingController(
      text: existing?.conditions ?? '',
    );
    _fields['insurance'] = TextEditingController(
      text: existing?.insurance ?? '',
    );
    _doctors = _rowsFor(existing?.doctor);
    _contacts = _rowsFor(existing?.emergencyContact);
    _fields['careNeeds'] = TextEditingController(
      text: existing?.careNeeds ?? '',
    );
    _fields['notes'] = TextEditingController(text: existing?.notes ?? '');
  }

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    for (final row in [..._doctors, ..._contacts]) {
      row.dispose();
    }
    super.dispose();
  }

  /// The rows a stored column opens as.
  ///
  /// A card that has never named anybody opens with one blank row rather
  /// than none: an empty section with only an "add" button under it
  /// reads as a feature to discover, and this is a form to fill in.
  static List<_PersonRow> _rowsFor(String? stored) {
    final people = parseCardPeople(stored);
    return [
      for (final person in people) _PersonRow.of(person),
      if (people.isEmpty) _PersonRow.of(const CardPerson()),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existing == null
              ? l10n.emergencyCardAdd
              : l10n.emergencyCardEdit,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          _Field(
            controller: _fields['name']!,
            label: l10n.emergencyCardName,
            icon: Icons.person_outline,
            error: _nameError,
          ),
          _Field(
            controller: _fields['year']!,
            label: l10n.emergencyCardBirthYear,
            hint: l10n.emergencyCardBirthYearHint,
            icon: Icons.cake_outlined,
            keyboardType: TextInputType.number,
            error: _yearError,
          ),
          _Field(
            controller: _fields['blood']!,
            label: l10n.emergencyCardBloodType,
            icon: Icons.bloodtype_outlined,
          ),
          _Field(
            controller: _fields['allergies']!,
            label: l10n.emergencyCardAllergies,
            icon: Icons.warning_amber_outlined,
            maxLines: 2,
          ),
          _Field(
            controller: _fields['medication']!,
            label: l10n.emergencyCardMedication,
            hint: l10n.emergencyCardMedicationHint,
            icon: Icons.medication_outlined,
            maxLines: 2,
          ),
          _Field(
            controller: _fields['conditions']!,
            label: l10n.emergencyCardConditions,
            icon: Icons.monitor_heart_outlined,
            maxLines: 2,
          ),
          _Field(
            controller: _fields['insurance']!,
            label: l10n.emergencyCardInsurance,
            icon: Icons.badge_outlined,
          ),
          _PeopleSection(
            title: l10n.emergencyCardDoctors,
            icon: Icons.local_hospital_outlined,
            nameLabel: l10n.emergencyCardName,
            roleLabel: l10n.emergencyCardSpecialty,
            roleHint: l10n.emergencyCardSpecialtyHint,
            phoneLabel: l10n.emergencyCardPhone,
            addLabel: l10n.emergencyCardDoctorAdd,
            removeLabel: l10n.emergencyCardPersonRemove,
            rows: _doctors,
            onChanged: () => setState(() {}),
          ),
          _PeopleSection(
            title: l10n.emergencyCardContacts,
            icon: Icons.phone_outlined,
            nameLabel: l10n.emergencyCardName,
            roleLabel: l10n.emergencyCardRelation,
            roleHint: l10n.emergencyCardRelationHint,
            phoneLabel: l10n.emergencyCardPhone,
            addLabel: l10n.emergencyCardContactAdd,
            removeLabel: l10n.emergencyCardPersonRemove,
            rows: _contacts,
            onChanged: () => setState(() {}),
          ),
          Card(
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.accessible_forward_outlined,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.emergencyCardCareTitle,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSecondaryContainer,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.emergencyCardCareHint,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSecondaryContainer,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _Field(
            controller: _fields['careNeeds']!,
            label: l10n.emergencyCardCareTitle,
            hint: l10n.emergencyCardCareHint,
            icon: Icons.accessible_forward_outlined,
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          _Field(
            controller: _fields['notes']!,
            label: l10n.emergencyCardNotes,
            icon: Icons.notes_outlined,
            maxLines: 3,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saving ? null : () => _save(l10n),
        icon: const Icon(Icons.save_outlined),
        label: Text(l10n.saveButton),
      ),
    );
  }

  Future<void> _save(AppLocalizations l10n) async {
    final name = _fields['name']!.text.trim();
    final yearText = _fields['year']!.text.trim();
    final year = yearText.isEmpty ? null : int.tryParse(yearText);

    setState(() {
      _nameError = name.isEmpty ? l10n.emergencyCardNameRequired : null;
      // A year that will not parse is refused rather than dropped: saving
      // a card while silently discarding what someone typed is worse than
      // asking again.
      _yearError = (yearText.isNotEmpty && (year == null || year < 1900))
          ? l10n.emergencyCardBirthYearInvalid
          : null;
    });
    if (_nameError != null || _yearError != null) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      await ref
          .read(householdMemberControllerProvider(widget.householdId))
          .save(
            HouseholdMemberDraft(
              name: name,
              birthYear: year,
              bloodType: _fields['blood']!.text,
              allergies: _fields['allergies']!.text,
              medication: _fields['medication']!.text,
              conditions: _fields['conditions']!.text,
              insurance: _fields['insurance']!.text,
              doctor: encodeCardPeople(_doctors.map((r) => r.person)),
              emergencyContact: encodeCardPeople(
                _contacts.map((r) => r.person),
              ),
              careNeeds: _fields['careNeeds']!.text,
              notes: _fields['notes']!.text,
            ),
            existing: widget.existing,
            sortOrder: widget.sortOrder,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      // A save that fails silently is the worst of both worlds: the form
      // stays as it was, which looks like nothing happened, and whoever
      // typed the card has no idea whether it is stored. Say so, and keep
      // the form open so the typing is not lost.
      // A message that slides away by itself is the only sign otherwise.
      Feel.failed();
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(describeError(l10n, error))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.error,
    this.maxLines = 1,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? error;
  final IconData icon;
  final int maxLines;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              labelText: label,
              prefixIcon: Icon(icon),
              border: const OutlineInputBorder(),
              errorText: error,
            ),
          ),
          if (hint != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
              child: Text(
                hint!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The controllers behind one doctor or one person to ring.
class _PersonRow {
  _PersonRow.of(CardPerson person)
    : name = TextEditingController(text: person.name),
      role = TextEditingController(text: person.role),
      phone = TextEditingController(text: person.phone);

  final TextEditingController name;
  final TextEditingController role;
  final TextEditingController phone;

  /// Identifies the row rather than its position, so removing the second
  /// of three does not hand the third one's contents to the second's
  /// fields. Without it the list rebuilds by index and the wrong text
  /// stays on screen.
  final key = UniqueKey();

  CardPerson get person =>
      CardPerson(name: name.text, role: role.text, phone: phone.text);

  void dispose() {
    name.dispose();
    role.dispose();
    phone.dispose();
  }
}

/// A list of people, each with a name, a capacity and a number.
///
/// Both sections on this screen are the same three questions asked twice
/// — see [CardPerson]. Only the labels differ, which is why they are all
/// parameters and none of them is decided here.
class _PeopleSection extends StatelessWidget {
  const _PeopleSection({
    required this.title,
    required this.icon,
    required this.nameLabel,
    required this.roleLabel,
    required this.roleHint,
    required this.phoneLabel,
    required this.addLabel,
    required this.removeLabel,
    required this.rows,
    required this.onChanged,
  });

  final String title;
  final IconData icon;
  final String nameLabel;
  final String roleLabel;
  final String roleHint;
  final String phoneLabel;
  final String addLabel;
  final String removeLabel;

  /// Owned by the form, which disposes them. This only adds and removes.
  final List<_PersonRow> rows;

  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(title, style: theme.textTheme.titleSmall),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              for (final row in rows) _entry(context, row),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    rows.add(_PersonRow.of(const CardPerson()));
                    onChanged();
                  },
                  icon: const Icon(Icons.add),
                  label: Text(addLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _entry(BuildContext context, _PersonRow row) {
    final role = TextField(
      controller: row.role,
      decoration: InputDecoration(
        labelText: roleLabel,
        hintText: roleHint,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
    final phone = TextField(
      controller: row.phone,
      keyboardType: TextInputType.phone,
      decoration: InputDecoration(
        labelText: phoneLabel,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );

    return Padding(
      key: row.key,
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: row.name,
                  decoration: InputDecoration(
                    labelText: nameLabel,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: removeLabel,
                // The last row is emptied rather than taken away: a
                // section with nothing in it and only an "add" button
                // under it reads as something to discover, and this is a
                // form to fill in.
                onPressed: () {
                  if (rows.length == 1) {
                    row.name.clear();
                    row.role.clear();
                    row.phone.clear();
                  } else {
                    rows.remove(row);
                    // After the frame, because the fields above are still
                    // mounted in this one.
                    WidgetsBinding.instance.addPostFrameCallback(
                      (_) => row.dispose(),
                    );
                  }
                  onChanged();
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Side by side where there is room for two labels, stacked
          // where a phone would squeeze them into ellipses.
          LayoutBuilder(
            builder: (context, constraints) => constraints.maxWidth < 360
                ? Column(
                    children: [role, const SizedBox(height: 8), phone],
                  )
                : Row(
                    children: [
                      Expanded(child: role),
                      const SizedBox(width: 8),
                      Expanded(child: phone),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
