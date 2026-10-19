import 'package:flutter/material.dart';

import '../../../core/feel.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../application/household_member_controller.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../core/content_swap.dart';
import '../../../local_db/database.dart';
import '../application/card_species.dart';
import '../application/emergency_plan_report.dart';
import '../application/household_providers.dart';
import '../application/household_plan_controller.dart';
import '../application/meeting_point_places.dart';
import '../../maps/application/personal_place.dart';
import '../../maps/presentation/place_picker_screen.dart';
import 'meeting_point_way.dart';
import '../../../core/error_text.dart';

/// The household's emergency plan.
///
/// One form rather than a list: this is a single agreement, and the whole
/// household edits the same one. Every field is optional — a household
/// that agreed a meeting point and nothing else has a perfectly good plan,
/// and a form that insists on more would get none at all.
class HouseholdPlanScreen extends ConsumerStatefulWidget {
  const HouseholdPlanScreen({super.key, required this.householdId});

  final String householdId;

  @override
  ConsumerState<HouseholdPlanScreen> createState() =>
      _HouseholdPlanScreenState();
}

class _HouseholdPlanScreenState extends ConsumerState<HouseholdPlanScreen> {
  final _controllers = <String, TextEditingController>{};
  bool _loaded = false;
  bool _saving = false;

  TextEditingController _field(String name) =>
      _controllers.putIfAbsent(name, TextEditingController.new);

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Fills the fields once, from whatever the household has.
  ///
  /// Once, deliberately: the plan is a live stream, and another device's
  /// save arriving mid-edit would otherwise overwrite what is being typed.
  void _fillOnce(HouseholdPlan? plan) {
    if (_loaded) return;
    _loaded = true;
    if (plan == null) return;

    _field('near').text = plan.meetingPointNear ?? '';
    _field('far').text = plan.meetingPointFar ?? '';
    _field('name').text = plan.contactName ?? '';
    _field('phone').text = plan.contactPhone ?? '';
    _field('contactPoint').text = plan.localContactPoint ?? '';
    _field('kit').text = plan.kitLocation ?? '';
    _field('shutoff').text = plan.shutoffLocation ?? '';
    _field('notes').text = plan.notes ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final planAsync = ref.watch(householdPlanProvider(widget.householdId));
    final places =
        ref.watch(meetingPointPlacesProvider).value ??
        const <MeetingPoint, PersonalPlace>{};

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.householdPlanTitle),
        actions: [
          if (planAsync.value != null)
            IconButton(
              icon: const Icon(Icons.ios_share_outlined),
              tooltip: l10n.householdPlanShareSafety,
              onPressed: () => _shareSafety(planAsync.value!, l10n),
            ),
          if (planAsync.value != null)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined),
              tooltip: l10n.emergencyPlanExport,
              onPressed: () => _export(planAsync.value!, l10n),
            ),
          if (planAsync.value != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: l10n.householdPlanClear,
              onPressed: () => _clear(planAsync.value!, l10n),
            ),
        ],
      ),
      body: ContentSwap(
        child: planAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text(describeError(l10n, error))),
          data: (plan) {
            _fillOnce(plan);

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                Text(
                  l10n.householdPlanIntro,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                _Field(
                  controller: _field('near'),
                  label: l10n.householdPlanMeetingNear,
                  hint: l10n.householdPlanMeetingNearHint,
                  icon: Icons.place_outlined,
                  below: _MeetingPlace(
                    place: places[MeetingPoint.near],
                    onPick: () => _pickPlace(MeetingPoint.near, places, l10n),
                    onRemove: () => _removePlace(MeetingPoint.near),
                  ),
                ),
                _Field(
                  controller: _field('far'),
                  label: l10n.householdPlanMeetingFar,
                  hint: l10n.householdPlanMeetingFarHint,
                  icon: Icons.alt_route,
                  below: _MeetingPlace(
                    place: places[MeetingPoint.far],
                    onPick: () => _pickPlace(MeetingPoint.far, places, l10n),
                    onRemove: () => _removePlace(MeetingPoint.far),
                  ),
                ),
                _Field(
                  controller: _field('name'),
                  label: l10n.householdPlanContactName,
                  hint: l10n.householdPlanContactNameHint,
                  icon: Icons.person_outline,
                ),
                _Field(
                  controller: _field('phone'),
                  label: l10n.householdPlanContactPhone,
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                _Field(
                  controller: _field('contactPoint'),
                  label: l10n.householdPlanContactPoint,
                  hint: l10n.householdPlanContactPointHint,
                  icon: Icons.local_police_outlined,
                ),
                _Field(
                  controller: _field('kit'),
                  label: l10n.householdPlanKitLocation,
                  hint: l10n.householdPlanKitLocationHint,
                  icon: Icons.backpack_outlined,
                ),
                _Field(
                  controller: _field('shutoff'),
                  label: l10n.householdPlanShutoff,
                  icon: Icons.power_settings_new,
                ),
                _Field(
                  controller: _field('notes'),
                  label: l10n.householdPlanNotes,
                  icon: Icons.notes_outlined,
                  maxLines: 4,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.householdPlanShared,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saving ? null : () => _save(l10n),
        icon: const Icon(Icons.save_outlined),
        label: Text(l10n.saveButton),
      ),
    );
  }

  Future<void> _save(AppLocalizations l10n) async {
    final draft = HouseholdPlanDraft(
      meetingPointNear: _field('near').text,
      meetingPointFar: _field('far').text,
      contactName: _field('name').text,
      contactPhone: _field('phone').text,
      localContactPoint: _field('contactPoint').text,
      kitLocation: _field('kit').text,
      shutoffLocation: _field('shutoff').text,
      notes: _field('notes').text,
    );

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    if (draft.isEmpty) {
      // An empty plan saved over a real one would look like a save and be
      // a deletion — and it would travel to every other device.
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.householdPlanNothingEntered)),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await ref
          .read(householdPlanControllerProvider(widget.householdId))
          .save(draft);
      // The places on the map take the names the plan now has.
      await ref.read(meetingPointStoreProvider).relabel(_placeLabels(l10n));
      ref.invalidate(meetingPointPlacesProvider);
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.householdPlanSaved)));
    } catch (error) {
      // Same reason as on the emergency card: without this the screen
      // reports a save it did not do -- or rather, reports nothing.
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(describeError(l10n, error))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// What each meeting point is called on the map: what the plan says,
  /// or which of the two it is while the field is empty.
  Map<MeetingPoint, String> _placeLabels(AppLocalizations l10n) {
    String label(String field, String fallback) {
      final text = _field(field).text.trim();
      return text.isEmpty ? fallback : text;
    }

    return {
      MeetingPoint.near: label('near', l10n.householdPlanMeetingNear),
      MeetingPoint.far: label('far', l10n.householdPlanMeetingFar),
    };
  }

  /// On the map, kept on this device at once: the point is not part of
  /// the plan that the Save button sends to the other devices (#204).
  Future<void> _pickPlace(
    MeetingPoint point,
    Map<MeetingPoint, PersonalPlace> places,
    AppLocalizations l10n,
  ) async {
    final current = places[point];
    final label = _placeLabels(l10n)[point]!;
    final chosen = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (_) => PlacePickerScreen(
          title: label,
          initial: current == null
              ? null
              : LatLng(current.latitude, current.longitude),
        ),
      ),
    );
    if (chosen == null) return;
    await ref.read(meetingPointStoreProvider).put(point, chosen, label: label);
    ref.invalidate(meetingPointPlacesProvider);
  }

  Future<void> _removePlace(MeetingPoint point) async {
    await ref.read(meetingPointStoreProvider).remove(point);
    ref.invalidate(meetingPointPlacesProvider);
  }

  Future<void> _clear(HouseholdPlan plan, AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.householdPlanClearConfirm),
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
    if (confirmed != true || !mounted) return;
    Feel.removed();

    await ref
        .read(householdPlanControllerProvider(widget.householdId))
        .clear(plan);
    // The points belong to the plan; this device's go with it.
    for (final point in MeetingPoint.values) {
      await ref.read(meetingPointStoreProvider).remove(point);
    }
    ref.invalidate(meetingPointPlacesProvider);
    if (!mounted) return;
    for (final controller in _controllers.values) {
      controller.clear();
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.householdPlanCleared)));
  }

  Future<void> _export(HouseholdPlan plan, AppLocalizations l10n) async {
    final profile = ref.read(householdProfileProvider).value;
    final locale = Localizations.localeOf(context).toString();

    // Asked every time, and never pre-selected. The cards on paper are
    // the copy that survives a dead phone, and they are also a loose
    // sheet naming somebody's blood group and medication — a trade worth
    // making sometimes and not worth making silently.
    final members = profile == null
        ? const <HouseholdMember>[]
        : ref.read(householdMembersProvider(profile.id)).value ?? const [];
    var withCards = false;
    if (members.isNotEmpty) {
      final answer = await _askAboutCards(l10n, members.length);
      if (answer == null) return;
      withCards = answer;
    }
    if (!mounted) return;

    final places = await ref.read(meetingPointStoreProvider).load();
    if (!mounted) return;

    await Printing.layoutPdf(
      onLayout: (_) => const EmergencyPlanReport().build(
        plan: plan,
        meetingPlaces: {
          for (final MapEntry(:key, :value) in places.entries)
            key: formatPlaceCoordinates(value),
        },
        householdName: profile?.name ?? '',
        members: withCards ? members : const [],
        strings: EmergencyPlanReportStrings(
          title: l10n.emergencyPlanPdfTitle,
          generatedOn: l10n.pdfGeneratedOn(
            DateFormat.yMMMMd(locale).add_Hm().format(DateTime.now()),
          ),
          meetingPoints: l10n.emergencyPlanPdfMeetingPoints,
          contact: l10n.emergencyPlanPdfContact,
          contactPoint: l10n.householdPlanContactPoint,
          equipment: l10n.emergencyPlanPdfEquipment,
          notes: l10n.notesLabel,
          empty: l10n.emergencyPlanPdfEmpty,
          cards: l10n.emergencyPlanPdfCards,
          cardsWarning: l10n.emergencyPlanPdfCardsWarning,
          fields: EmergencyCardFieldStrings(
            birthYear: l10n.emergencyCardBirthYear,
            bloodType: l10n.emergencyCardBloodType,
            allergies: l10n.emergencyCardAllergies,
            medication: l10n.emergencyCardMedication,
            conditions: l10n.emergencyCardConditions,
            insurance: l10n.emergencyCardInsurance,
            doctor: l10n.emergencyCardDoctor,
            doctors: l10n.emergencyCardDoctors,
            contact: l10n.emergencyCardContact,
            contacts: l10n.emergencyCardContacts,
            careNeeds: l10n.emergencyCardCareTitle,
            kind: l10n.cardSpeciesLabel,
            speciesName: (species) => localizeCardSpecies(l10n, species),
            chipNumber: l10n.cardChipNumber,
            vet: l10n.cardVet,
            vets: l10n.cardVets,
            shelters: l10n.cardShelters,
            notes: l10n.emergencyCardNotes,
          ),
        ),
      ),
    );
  }

  /// Opens the system's own share sheet. No safety state is sent by the app;
  /// the user chooses both the recipient and whether the message should leave
  /// the device, each time.
  Future<void> _shareSafety(HouseholdPlan plan, AppLocalizations l10n) async {
    final meetingPoint =
        plan.meetingPointNear ??
        plan.meetingPointFar ??
        l10n.householdPlanEmpty;
    final controller = TextEditingController(
      text: l10n.householdPlanSafetyMessage(meetingPoint),
    );
    final message = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.householdPlanShareSafety),
        content: TextField(
          controller: controller,
          minLines: 3,
          maxLines: 6,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(hintText: l10n.householdPlanSafetyHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancelButton),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(controller.text),
            icon: const Icon(Icons.ios_share_outlined),
            label: Text(l10n.householdPlanShareSafety),
          ),
        ],
      ),
    );
    controller.dispose();
    if (message == null || message.trim().isEmpty) return;
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: message.trim(),
          subject: l10n.householdPlanShareSafety,
        ),
      );
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.shareFailed)),
      );
    }
  }

  /// True to include the cards, false for the plan alone, null to abandon
  /// the export entirely.
  Future<bool?> _askAboutCards(AppLocalizations l10n, int count) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.warning_amber_outlined),
        title: Text(l10n.emergencyPlanCardsAskTitle),
        content: Text(l10n.emergencyPlanCardsAskBody(count)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              MaterialLocalizations.of(dialogContext).cancelButtonLabel,
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.emergencyPlanCardsAskWithout),
          ),
          // Not a FilledButton: including them is the more consequential
          // of the two, and the emphasised button is the one people press
          // without reading.
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.emergencyPlanCardsAskWith),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.below,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData icon;
  final int maxLines;
  final TextInputType? keyboardType;

  /// Under the hint: where a meeting point is on the map.
  final Widget? below;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
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
            ),
          ),
          // Under the field rather than inside it: a hint that vanishes on
          // focus is a hint nobody reads while answering.
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
          ?below,
        ],
      ),
    );
  }
}

/// Where a meeting point is on this device's map, or the way to put it
/// there.
class _MeetingPlace extends StatelessWidget {
  const _MeetingPlace({
    required this.place,
    required this.onPick,
    required this.onRemove,
  });

  final PersonalPlace? place;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final place = this.place;
    if (place == null) {
      return Align(
        alignment: AlignmentDirectional.centerStart,
        child: TextButton.icon(
          onPressed: onPick,
          icon: const Icon(Icons.add_location_alt_outlined),
          label: Text(l10n.meetingPlaceSet),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(Icons.location_on_outlined, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(formatPlaceCoordinates(place)),
                Text(
                  l10n.meetingPlaceDeviceOnly,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          MeetingPointWayButton(place: place),
          IconButton(
            tooltip: l10n.meetingPlaceChange,
            icon: const Icon(Icons.edit_location_alt_outlined),
            onPressed: onPick,
          ),
          IconButton(
            tooltip: l10n.meetingPlaceRemove,
            icon: const Icon(Icons.location_off_outlined),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
