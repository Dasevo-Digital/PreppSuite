import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_theme.dart';
import '../../../core/app_ui.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../model/household_profile.dart';
import '../../checklists/application/checklist_providers.dart';
import '../../checklists/application/checklist_satisfaction.dart';
import '../../energy/presentation/outage_screen.dart';
import '../../first_aid/presentation/first_aid_screen.dart';
import '../../household/application/household_member_controller.dart';
import '../../household/application/household_plan_controller.dart';
import '../../household/application/meeting_point_places.dart';
import '../../household/presentation/meeting_point_way.dart';
import '../../inventory/application/inventory_providers.dart';
import '../../kids_comic/application/kids_comic.dart';
import '../../kids_comic/presentation/kids_comic_screen.dart';
import '../../daylight/presentation/daylight_screen.dart';
import '../../maps/presentation/my_position_screen.dart';
import '../../maps/presentation/nearby_screen.dart';
import '../../morse/presentation/morse_screen.dart';
import '../../phrasebook/presentation/phrasebook_screen.dart';
import '../../translator/presentation/translator_screen.dart';
import 'distress_signal_screen.dart';
import 'broadcast_radio_screen.dart';
import 'radio_emergency_screen.dart';
import '../../knowledge/application/knowledge_providers.dart';
import '../../maps/application/offline_map_providers.dart';
import '../../warnings/application/warning_providers.dart';
import '../../warnings/application/warning_relevance.dart';
import '../application/shell_layout.dart';
import 'emergency_information_screen.dart';
import 'preparedness_tools_screen.dart';
import 'readiness_screen.dart';
import 'check_in_screen.dart';
import '../../first_aid/presentation/defibrillator_screen.dart';
import '../../emergency_points/presentation/emergency_points_screen.dart';
import '../../../core/phone_call.dart';
import '../../household/application/card_species.dart';
import '../../warnings/application/warning_translations.dart';

/// The information that must remain quick to reach when time, power or a
/// data connection is scarce. All values are derived from existing records.
class EmergencyScreen extends ConsumerWidget {
  const EmergencyScreen({
    super.key,
    required this.profile,
    required this.onNavigate,
  });

  final HouseholdProfile profile;
  final ValueChanged<ShellDestination> onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final inventory =
        ref.watch(inventoryItemsProvider(profile.id)).value ?? const [];
    final checklist =
        ref.watch(allChecklistItemsProvider(profile.id)).value ?? const [];
    final plan = ref.watch(householdPlanProvider(profile.id)).value;
    final places = ref.watch(meetingPointPlacesProvider).value ?? const {};
    final members =
        ref.watch(householdMembersProvider(profile.id)).value ?? const [];
    final mapReady = ref.watch(offlineMapProvider).value?.isReady ?? false;
    final knowledgeReady = ref.watch(knowledgeProvider).value?.isReady ?? false;
    final warnings = (ref.watch(activeWarningsProvider).value ?? const [])
        .where(
          (warning) => isWarningRelevant(
            warning: warning,
            filter: profile.warningFilter,
          ),
        )
        .toList();

    // Built once, not once per checklist item. `any` short-circuits, so the
    // cost only shows in full when nothing is satisfied yet — which is the
    // fresh household this screen exists for, and 129 built-in items
    // against a stocked pantry is five figures of map insertions on every
    // rebuild. There are seven streams above; a write to any of them
    // rebuilds this.
    final inventoryById = {for (final item in inventory) item.clientId: item};

    final readiness = [
      (
        l10n.readinessInventory,
        inventory.isNotEmpty,
        ShellDestination.inventory,
      ),
      (
        l10n.readinessChecklists,
        checklist.any((item) => isChecklistItemSatisfied(item, inventoryById)),
        ShellDestination.checklists,
      ),
      (l10n.readinessPlan, plan != null, ShellDestination.household),
      // A card for a paramedic is a person's; an animal's alone does
      // not answer this (#151).
      (
        l10n.readinessCards,
        members.any((member) => !member.isAnimal),
        ShellDestination.household,
      ),
      (l10n.readinessMap, mapReady, ShellDestination.map),
      (l10n.readinessKnowledge, knowledgeReady, ShellDestination.knowledge),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.emergencyTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Side by side and the same width, so the thumb does not have to
          // find them; 112 in the one colour on this screen that means it.
          Row(
            children: [
              Expanded(
                child: _CallButton(
                  label: l10n.emergencyCall112,
                  number: '112',
                  urgent: true,
                ),
              ),
              // 110 is the police in Germany and the fire brigade in Norway.
              // Everywhere else this app can be set up, 112 reaches help.
              if (profile.countryCode == 'DE') ...[
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: _CallButton(
                    label: l10n.emergencyCall110,
                    number: '110',
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpace.md),
          // First in the list, and the only entry here that needs nothing
          // downloaded, nothing configured and no network. Somebody
          // opening this screen with a casualty in front of them should
          // not have to read past anything.
          Card(
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: ListTile(
              leading: IconBadge(
                Icons.medical_services_outlined,
                background: Theme.of(context).colorScheme.primary,
                foreground: Theme.of(context).colorScheme.onPrimary,
              ),
              title: Text(
                l10n.firstAidTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              subtitle: Text(l10n.firstAidEntryHint),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const FirstAidScreen()),
              ),
            ),
          ),
          const SizedBox(height: AppSpace.md),
          _EntryCard(
            entries: [
              // Right under first aid, because it belongs to the same
              // minute (#117).
              _Entry(
                icon: Icons.monitor_heart_outlined,
                title: l10n.aedTitle,
                subtitle: l10n.aedEntryHint,
                open: () => const DefibrillatorScreen(),
              ),
              // Water, information and the siren for the long blackout
              // (#127, #128), beside the other thing searched once and
              // kept.
              _Entry(
                icon: Icons.water_drop_outlined,
                title: l10n.emergencyPointsTitle,
                subtitle: l10n.emergencyPointsEntryHint,
                open: () => const EmergencyPointsScreen(),
              ),
              // Then, and with a name of its own rather than three screens
              // down in the crisis organisation, where it was the
              // nineteenth section of twenty: a child, or a parent reading
              // with one, has to be able to find it.
              _Entry(
                icon: Icons.auto_stories_outlined,
                title: kidsComic(l10n.localeName).title,
                subtitle: l10n.emergencyComicHint,
                open: () => const KidsComicScreen(),
              ),
              // Third: after the casualty and the child comes the family
              // that is waiting to hear (#116).
              _Entry(
                icon: Icons.sms_outlined,
                title: l10n.checkInTitle,
                subtitle: l10n.checkInEntryHint,
                open: () => CheckInScreen(householdId: profile.id),
              ),
              _Entry(
                icon: Icons.contact_phone_outlined,
                title: l10n.emergencyDirectoryTitle,
                open: () => const EmergencyInformationScreen(),
              ),
              _Entry(
                icon: Icons.playlist_add_check_circle_outlined,
                title: l10n.drillsTitle,
                subtitle: l10n.drillsSubtitle,
                open: () => PreparednessToolsScreen(householdId: profile.id),
              ),
              _Entry(
                icon: Icons.power_off_outlined,
                title: l10n.outageTitle,
                subtitle: l10n.outageEntryHint,
                open: () => OutageScreen(householdId: profile.id),
              ),
            ],
          ),
          // Every way of being understood when the network is gone, side
          // by side and named as what they are for (#187). They used to be
          // entries three to six of "Notruf, Kontakte & Funk", a title
          // that promises none of them -- and somebody looking for the
          // Morse translator did not find it.
          _Section(
            title: l10n.emergencyCommunicateHeading,
            entries: [
              _Entry(
                icon: Icons.highlight_outlined,
                title: l10n.distressTitle,
                subtitle: l10n.distressAlpineHint,
                open: () => const DistressSignalScreen(),
              ),
              _Entry(
                icon: Icons.linear_scale,
                title: l10n.morseTitle,
                subtitle: l10n.morseEntryHint,
                open: () => const MorseScreen(),
              ),
              _Entry(
                icon: Icons.translate,
                title: l10n.phrasebookTitle,
                subtitle: l10n.phrasebookEntryHint,
                open: () => const PhrasebookScreen(),
              ),
              _Entry(
                icon: Icons.g_translate,
                title: l10n.translatorTitle,
                subtitle: l10n.translatorEntryHint,
                open: () => const TranslatorScreen(),
              ),
              // Listening comes before sending: the broadcast radio is
              // what most households have, and what tells them (#267).
              _Entry(
                icon: Icons.radio,
                title: l10n.broadcastRadioTitle,
                subtitle: l10n.broadcastRadioEntryHint,
                open: () => const BroadcastRadioScreen(),
              ),
              _Entry(
                icon: Icons.settings_input_antenna_outlined,
                title: l10n.radioEmergencyTitle,
                subtitle: l10n.radioEmergencyEntryHint,
                open: () => const RadioEmergencyScreen(),
              ),
            ],
          ),
          // What the device can still answer by itself: where you are,
          // what is near, and how long the light lasts.
          _Section(
            title: l10n.emergencyOrientationHeading,
            entries: [
              _Entry(
                icon: Icons.share_location_outlined,
                title: l10n.myPositionTitle,
                subtitle: l10n.myPositionDmsHint,
                open: () => const MyPositionScreen(),
              ),
              _Entry(
                icon: Icons.travel_explore_outlined,
                title: l10n.nearbyTitle,
                subtitle: l10n.nearbyEntryHint,
                open: () => const NearbyScreen(),
              ),
              _Entry(
                icon: Icons.wb_twilight_outlined,
                title: l10n.daylightTitle,
                subtitle: l10n.daylightEntryHint,
                open: () => const DaylightScreen(),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            l10n.emergencyCurrentWarnings,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Card(
            child: warnings.isEmpty
                ? ListTile(
                    leading: const Icon(Icons.check_circle_outline),
                    title: Text(l10n.emergencyNoWarnings),
                  )
                : Column(
                    children: [
                      for (final warning in warnings)
                        ListTile(
                          leading: const Icon(Icons.warning_amber_rounded),
                          title: Text(
                            warning.textIn(l10n.localeName).headline,
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => onNavigate(ShellDestination.warnings),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.readinessTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.monitor_heart_outlined),
            title: Text(l10n.readinessOpenDashboard),
            subtitle: Text(l10n.readinessDashboardHint),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ReadinessScreen(profile: profile),
              ),
            ),
          ),
          Card(
            child: Column(
              children: [
                for (final entry in readiness)
                  ListTile(
                    leading: Icon(
                      entry.$2
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: entry.$2
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    title: Text(entry.$1),
                    subtitle: Text(
                      entry.$2 ? l10n.readinessReady : l10n.readinessNeedsWork,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => onNavigate(entry.$3),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.readinessOfflinePackages,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    mapReady
                        ? Icons.verified_outlined
                        : Icons.download_outlined,
                  ),
                  title: Text(l10n.emergencyOfflineMapTitle),
                  subtitle: Text(
                    mapReady
                        ? l10n.emergencyMapReady
                        : l10n.emergencyMapMissing,
                  ),
                  onTap: () => onNavigate(ShellDestination.map),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    knowledgeReady
                        ? Icons.verified_outlined
                        : Icons.download_outlined,
                  ),
                  title: Text(l10n.emergencyKnowledgeArchivesTitle),
                  subtitle: Text(
                    knowledgeReady
                        ? l10n.emergencyKnowledgeReady
                        : l10n.emergencyKnowledgeMissing,
                  ),
                  onTap: () => onNavigate(ShellDestination.knowledge),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.emergencyPlanHeading,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Card(
            child: plan == null
                ? ListTile(
                    leading: const Icon(Icons.edit_note),
                    title: Text(l10n.emergencyPlanMissing),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => onNavigate(ShellDestination.household),
                  )
                : Column(
                    children: [
                      // The way there, where this device has the point on
                      // its map (#204).
                      if (plan.meetingPointNear != null)
                        _PlanRow(
                          icon: Icons.place,
                          value: plan.meetingPointNear!,
                          trailing: switch (places[MeetingPoint.near]) {
                            final place? => MeetingPointWayButton(place: place),
                            null => null,
                          },
                        ),
                      if (plan.meetingPointFar != null)
                        _PlanRow(
                          icon: Icons.map_outlined,
                          value: plan.meetingPointFar!,
                          trailing: switch (places[MeetingPoint.far]) {
                            final place? => MeetingPointWayButton(place: place),
                            null => null,
                          },
                        ),
                      if (plan.contactName != null)
                        _PlanRow(
                          icon: Icons.person_outline,
                          value:
                              '${plan.contactName}${plan.contactPhone == null ? '' : ' · ${plan.contactPhone}'}',
                        ),
                      if (plan.kitLocation != null)
                        _PlanRow(
                          icon: Icons.backpack_outlined,
                          value: plan.kitLocation!,
                        ),
                      if (plan.shutoffLocation != null)
                        _PlanRow(
                          icon: Icons.power_settings_new,
                          value: plan.shutoffLocation!,
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _CallButton extends StatelessWidget {
  const _CallButton({
    required this.label,
    required this.number,
    this.urgent = false,
  });
  final String label;
  final String number;

  /// The call for when somebody is hurt.
  final bool urgent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FilledButton.icon(
      style: urgent
          ? FilledButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
            )
          : null,
      onPressed: () => callNumber(context, number),
      icon: const Icon(Icons.call),
      label: Text(label),
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({required this.icon, required this.value, this.trailing});
  final IconData icon;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon),
    title: Text(value),
    trailing: trailing,
  );
}

/// One entry of a [_Section].
class _Entry {
  const _Entry({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.open,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget Function() open;
}

/// A heading and the screens under it, in one card.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.entries});

  final String title;
  final List<_Entry> entries;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SectionHeading(title),
      _EntryCard(entries: entries),
    ],
  );
}

/// The rows of a [_Section], or of the unheaded block under first aid.
class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.entries});

  final List<_Entry> entries;

  @override
  Widget build(BuildContext context) => Card(
    child: Column(
      children: [
        for (final entry in entries)
          ListTile(
            leading: IconBadge(entry.icon),
            title: Text(entry.title),
            subtitle: entry.subtitle == null ? null : Text(entry.subtitle!),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute<void>(builder: (_) => entry.open())),
          ),
      ],
    ),
  );
}
