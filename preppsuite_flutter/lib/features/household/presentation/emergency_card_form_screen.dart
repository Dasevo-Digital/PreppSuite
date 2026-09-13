import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error_text.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../local_db/database.dart';
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
    _fields['doctor'] = TextEditingController(text: existing?.doctor ?? '');
    _fields['contact'] = TextEditingController(
      text: existing?.emergencyContact ?? '',
    );
    _fields['notes'] = TextEditingController(text: existing?.notes ?? '');
  }

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
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
          _Field(
            controller: _fields['doctor']!,
            label: l10n.emergencyCardDoctor,
            icon: Icons.local_hospital_outlined,
          ),
          _Field(
            controller: _fields['contact']!,
            label: l10n.emergencyCardContact,
            icon: Icons.phone_outlined,
          ),
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
              doctor: _fields['doctor']!.text,
              emergencyContact: _fields['contact']!.text,
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
