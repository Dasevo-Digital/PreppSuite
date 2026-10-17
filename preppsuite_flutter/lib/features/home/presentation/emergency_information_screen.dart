import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../../../core/adaptive_columns.dart';
import '../../first_aid/application/poison_centres.dart';
import '../../maps/presentation/my_position_screen.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../core/phone_call.dart';

const _contactsKey = 'nearbyEmergencyContacts';

class EmergencyInformationScreen extends StatefulWidget {
  const EmergencyInformationScreen({super.key});

  @override
  State<EmergencyInformationScreen> createState() =>
      _EmergencyInformationScreenState();
}

class _EmergencyInformationScreenState
    extends State<EmergencyInformationScreen> {
  var _contacts = <_NearbyContact>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final raw = (await SharedPreferences.getInstance()).getString(_contactsKey);
    if (raw == null) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List && mounted) {
        setState(() {
          _contacts = [
            for (final item in decoded) ?_NearbyContact.fromJson(item),
          ];
        });
      }
    } on FormatException {
      return;
    }
  }

  Future<void> _save() => SharedPreferences.getInstance().then(
    (prefs) => prefs.setString(
      _contactsKey,
      jsonEncode([for (final contact in _contacts) contact.toJson()]),
    ),
  );

  /// The one dialog for both adding and changing a contact.
  ///
  /// Editing was missing entirely: a contact typed with a digit wrong
  /// could only be deleted and entered again, which on the screen people
  /// reach for in an emergency is the wrong kind of work. [existing] is
  /// null when adding.
  Future<void> _edit({_NearbyContact? existing}) async {
    final l10n = AppLocalizations.of(context)!;
    final name = TextEditingController(text: existing?.name ?? '');
    final phone = TextEditingController(text: existing?.phone ?? '');
    final address = TextEditingController(text: existing?.address ?? '');
    final coordinates = TextEditingController(
      text: existing?.coordinates ?? '',
    );
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          existing == null
              ? l10n.emergencyContactAdd
              : l10n.emergencyContactEdit,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: l10n.emergencyContactName,
                ),
              ),
              TextField(
                controller: phone,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: l10n.emergencyContactPhone,
                ),
              ),
              TextField(
                controller: address,
                decoration: InputDecoration(
                  labelText: l10n.emergencyContactAddress,
                ),
              ),
              TextField(
                controller: coordinates,
                keyboardType: const TextInputType.numberWithOptions(
                  signed: true,
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: l10n.emergencyContactCoordinates,
                  hintText: '52.2689, 10.5268',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.saveButton),
          ),
        ],
      ),
    );
    if (accepted != true || name.text.trim().isEmpty) return;

    // The id is carried over when editing, so anything else holding on to
    // this contact still points at the same one.
    final edited = _NearbyContact(
      id: existing?.id ?? const Uuid().v4(),
      name: name.text.trim(),
      phone: phone.text.trim(),
      address: address.text.trim(),
      coordinates: coordinates.text.trim(),
    );
    setState(() {
      _contacts = existing == null
          ? [..._contacts, edited]
          : [
              for (final contact in _contacts)
                contact.id == existing.id ? edited : contact,
            ];
    });
    await _save();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // A frequency band in the reader's own numbers: "87,5" was written
    // into the code, which an English locale reads as two values.
    final number = NumberFormat.decimalPattern(l10n.localeName)
      ..turnOffGrouping();
    // Whole numbers as they are ("108"), the rest to [digits] places, so
    // a channel raster like 149,0250 keeps its last zero.
    String figure(num value, int digits) {
      final places = value == value.roundToDouble() ? 0 : digits;
      number
        ..minimumFractionDigits = places
        ..maximumFractionDigits = places;
      return number.format(value);
    }

    String band(num from, num to, int digits, String unit) =>
        '${figure(from, digits)}–${figure(to, digits)} $unit';

    return Scaffold(
      appBar: AppBar(title: Text(l10n.emergencyDirectoryTitle)),
      body: AdaptiveColumns(
        padding: const EdgeInsets.all(16),
        // Seven poison-control centres, five radio bands and eight more
        // entries are a long single column on a phone and a very wide,
        // very empty one on a desktop, with the call icon a screen's
        // width from the number it belongs to. Each heading travels with
        // what is under it.
        blocks: [
          // First, because it is the question every one of these calls
          // begins with and the only one this app can answer for the
          // caller: where are you. The rest of what used to follow -- the
          // signals, Morse, the phrasebook and the translator, the live
          // readings -- moved to where it is looked for (#187): the
          // emergency tab's "Verständigen ohne Netz" and the warnings.
          Card(
            child: ListTile(
              leading: const Icon(Icons.share_location_outlined),
              title: Text(l10n.myPositionTitle),
              subtitle: Text(l10n.myPositionDmsHint),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const MyPositionScreen(),
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.medical_services_outlined),
            title: Text(l10n.emergencyMedicalService),
            trailing: const Icon(Icons.call_outlined),
            onTap: () => _call('116117'),
          ),
          _Block(
            children: [
              Text(
                l10n.emergencyPoisonTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(l10n.emergencyPoisonHint),
              const SizedBox(height: 8),
              for (final centre in poisonCentresByRegion)
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.local_hospital_outlined),
                  title: Text(centre.label),
                  subtitle: Text(centre.phone),
                  trailing: const Icon(Icons.call_outlined),
                  onTap: () => _call(centre.phone),
                ),
            ],
          ),
          // Before the radio section on purpose: the signal is what tells
          // somebody to turn the radio on, so the two read in the order
          // they happen.
          _Block(
            children: [
              Text(
                l10n.emergencySirenTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(l10n.emergencySirenHint),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.campaign_outlined),
                      title: Text(l10n.emergencySirenWarning),
                      subtitle: Text(l10n.emergencySirenWarningMeaning),
                    ),
                    ListTile(
                      leading: const Icon(Icons.check_circle_outline),
                      title: Text(l10n.emergencySirenAllClear),
                      subtitle: Text(l10n.emergencySirenAllClearMeaning),
                    ),
                    // Listed although it is not a public warning, because it
                    // is the one people hear most often and read as one.
                    ListTile(
                      leading: const Icon(Icons.local_fire_department_outlined),
                      title: Text(l10n.emergencySirenFire),
                      subtitle: Text(l10n.emergencySirenFireMeaning),
                    ),
                  ],
                ),
              ),
            ],
          ),
          _Block(
            children: [
              Text(
                l10n.emergencyRadioTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(l10n.emergencyRadioHint),
              const SizedBox(height: 8),
              // No longer const: the channel counts are localised, and "16
              // Kanäle" was German on an English locale.
              Card(
                child: Column(
                  children: [
                    ListTile(
                      title: Text(l10n.emergencyRadioFm),
                      subtitle: Text(band(87.5, 108, 1, 'MHz')),
                    ),
                    ListTile(
                      title: const Text('DAB+ Band III'),
                      subtitle: Text(band(174, 240, 0, 'MHz')),
                    ),
                    ListTile(
                      title: Text(l10n.emergencyRadioMediumWave),
                      subtitle: Text(band(526.5, 1606.5, 1, 'kHz')),
                    ),
                    ListTile(
                      title: const Text('PMR446'),
                      subtitle: Text(
                        '${band(446.00625, 446.19375, 5, 'MHz')} · '
                        '${l10n.emergencyRadioChannels(16)}',
                      ),
                    ),
                    ListTile(
                      title: Text(l10n.emergencyRadioFreenet),
                      subtitle: Text(
                        '${band(149.025, 149.1125, 4, 'MHz')} · '
                        '${l10n.emergencyRadioChannels(6)}',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          _Block(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.emergencyContactsTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: l10n.emergencyContactAdd,
                    onPressed: () => _edit(),
                    icon: const Icon(Icons.person_add_alt),
                  ),
                ],
              ),
              if (_contacts.isEmpty)
                ListTile(title: Text(l10n.emergencyContactsEmpty))
              else
                for (final contact in _contacts)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.person_pin_circle_outlined),
                      title: Text(contact.name),
                      subtitle: Text(
                        [
                          if (contact.phone.isNotEmpty) contact.phone,
                          if (contact.address.isNotEmpty) contact.address,
                          if (contact.coordinates.isNotEmpty)
                            contact.coordinates,
                        ].join('\n'),
                      ),
                      onTap: contact.phone.isEmpty
                          ? null
                          : () => _call(contact.phone),
                      trailing: PopupMenuButton<String>(
                        onSelected: (action) async {
                          if (action == 'map') await _map(contact);
                          if (action == 'edit') await _edit(existing: contact);
                          if (action == 'delete') {
                            setState(
                              () => _contacts.removeWhere(
                                (c) => c.id == contact.id,
                              ),
                            );
                            await _save();
                          }
                        },
                        itemBuilder: (_) => [
                          if (contact.address.isNotEmpty ||
                              contact.coordinates.isNotEmpty)
                            PopupMenuItem(
                              value: 'map',
                              child: Text(l10n.emergencyOpenMapAction),
                            ),
                          PopupMenuItem(
                            value: 'edit',
                            child: Text(l10n.emergencyContactEdit),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text(l10n.emergencyContactDelete),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _call(String number) => callNumber(context, number);

  Future<void> _map(_NearbyContact contact) {
    final query = contact.coordinates.isNotEmpty
        ? contact.coordinates
        : contact.address;
    return launchUrl(
      Uri.parse(
        'https://www.openstreetmap.org/search?query=${Uri.encodeQueryComponent(query)}',
      ),
      mode: LaunchMode.externalApplication,
    );
  }
}

class _NearbyContact {
  const _NearbyContact({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.coordinates,
  });
  final String id;
  final String name;
  final String phone;
  final String address;
  final String coordinates;

  Map<String, String> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'address': address,
    'coordinates': coordinates,
  };

  static _NearbyContact? fromJson(Object? value) {
    if (value is! Map || value['id'] is! String || value['name'] is! String) {
      return null;
    }
    return _NearbyContact(
      id: value['id'] as String,
      name: value['name'] as String,
      phone: value['phone'] as String? ?? '',
      address: value['address'] as String? ?? '',
      coordinates: value['coordinates'] as String? ?? '',
    );
  }
}

/// One section of the directory, kept in one piece when the page is laid
/// out in columns.
class _Block extends StatelessWidget {
  const _Block({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: children,
  );
}
