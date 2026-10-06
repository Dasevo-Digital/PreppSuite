import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/error_text.dart';
import '../../../core/geolocation_service.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../household/application/household_member_controller.dart';
import '../../household/application/household_plan_controller.dart';
import '../application/check_in.dart';

/// "I am all right", to the people who are waiting to hear it (#116).
///
/// Composed here, sent by the phone's own messaging app: nothing goes
/// through a server of this app, and nothing is sent without the person
/// pressing send in the app that sends it.
class CheckInScreen extends ConsumerStatefulWidget {
  const CheckInScreen({
    super.key,
    required this.householdId,
    this.geolocation,
    this.store = const CheckInContactStore(),
    this.launch,
  });

  final String householdId;

  /// Injectable for tests.
  final GeolocationService? geolocation;
  final CheckInContactStore store;
  final Future<bool> Function(Uri uri)? launch;

  @override
  ConsumerState<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends ConsumerState<CheckInScreen> {
  late final GeolocationService _geolocation =
      widget.geolocation ?? GeolocationService();
  final _note = TextEditingController();

  var _status = CheckInStatus.safe;
  List<CheckInContact> _contacts = const [];
  String? _location;
  var _locating = false;

  @override
  void initState() {
    super.initState();
    widget.store.load().then((contacts) {
      if (mounted) setState(() => _contacts = contacts);
    });
    _note.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _note.dispose();
    if (widget.geolocation == null) _geolocation.close();
    super.dispose();
  }

  /// Where messaging can be opened at all. Windows and Linux have no
  /// standard handler for `sms:`; there the text is copied or shared.
  bool get _canText =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS);

  String _message(AppLocalizations l10n, String? meetingPoint) {
    final status = switch (_status) {
      CheckInStatus.safe => l10n.checkInSafe,
      CheckInStatus.needHelp => l10n.checkInNeedHelp,
      CheckInStatus.onMyWay =>
        meetingPoint == null || meetingPoint.isEmpty
            ? l10n.checkInOnMyWay
            : l10n.checkInOnMyWayTo(meetingPoint),
    };
    final time = DateFormat.MMMd(
      l10n.localeName,
    ).add_Hm().format(DateTime.now());
    return composeCheckIn(
      status: status,
      time: l10n.checkInTime(time),
      location: _location,
      note: _note.text,
    );
  }

  Future<void> _toggleLocation(bool on) async {
    if (!on) {
      setState(() => _location = null);
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    setState(() => _locating = true);
    try {
      final fix = await _geolocation.getCurrentFix();
      if (!mounted) return;
      setState(
        () => _location = describePosition(
          fix.latitude,
          fix.longitude,
          accuracyMetres: fix.accuracyMetres,
        ),
      );
    } on LocationUnavailableException catch (error) {
      _say(describeError(l10n, error));
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _send(CheckInContact contact, String text) async {
    final l10n = AppLocalizations.of(context)!;
    final uri = smsUri(contact.phone, text, ios: !kIsWeb && Platform.isIOS);
    bool opened;
    try {
      opened = await (widget.launch ?? launchUrl)(uri);
    } on Object {
      opened = false;
    }
    if (!opened) _say(l10n.checkInNoSmsApp);
  }

  Future<void> _share(String text) =>
      SharePlus.instance.share(ShareParams(text: text));

  Future<void> _copy(String text) async {
    final l10n = AppLocalizations.of(context)!;
    await Clipboard.setData(ClipboardData(text: text));
    _say(l10n.checkInCopied);
  }

  Future<void> _save(List<CheckInContact> contacts) async {
    setState(() => _contacts = contacts);
    await widget.store.save(contacts);
  }

  Future<void> _addContact({String? name, String? phone}) async {
    final l10n = AppLocalizations.of(context)!;
    final added = await showDialog<CheckInContact>(
      context: context,
      builder: (_) => _ContactDialog(l10n: l10n, name: name, phone: phone),
    );
    if (added == null) return;
    await _save([..._contacts, added]);
  }

  void _say(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final plan = ref.watch(householdPlanProvider(widget.householdId)).value;
    final members =
        ref.watch(householdMembersProvider(widget.householdId)).value ??
        const [];
    final text = _message(l10n, plan?.meetingPointNear);
    final suggestions = _suggestions(plan?.contactName, plan?.contactPhone, [
      for (final member in members) ?member.emergencyContact,
    ]);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.checkInTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.checkInEntryHint),
          const SizedBox(height: 16),
          Text(l10n.checkInStatusLabel, style: theme.textTheme.titleMedium),
          RadioGroup<CheckInStatus>(
            groupValue: _status,
            onChanged: (value) =>
                setState(() => _status = value ?? CheckInStatus.safe),
            child: Column(
              children: [
                for (final status in CheckInStatus.values)
                  RadioListTile<CheckInStatus>(
                    value: status,
                    contentPadding: EdgeInsets.zero,
                    title: Text(switch (status) {
                      CheckInStatus.safe => l10n.checkInSafe,
                      CheckInStatus.needHelp => l10n.checkInNeedHelp,
                      CheckInStatus.onMyWay => l10n.checkInOnMyWay,
                    }),
                  ),
              ],
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _location != null,
            onChanged: _locating ? null : _toggleLocation,
            title: Text(l10n.checkInAttachLocation),
            subtitle: _locating ? Text(l10n.checkInLocating) : null,
          ),
          TextField(
            controller: _note,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: l10n.checkInNote,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Text(l10n.checkInPreview, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SelectableText(text),
            ),
          ),
          const SizedBox(height: 16),
          Text(l10n.checkInRecipients, style: theme.textTheme.titleMedium),
          if (_contacts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(l10n.checkInNoRecipients),
            ),
          for (final contact in _contacts)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(contact.name),
              subtitle: Text(contact.phone),
              leading: IconButton(
                tooltip: l10n.checkInRemoveContact,
                icon: const Icon(Icons.close),
                onPressed: () => _save([
                  for (final other in _contacts)
                    if (other != contact) other,
                ]),
              ),
              trailing: _canText
                  ? FilledButton.icon(
                      onPressed: () => _send(contact, text),
                      icon: const Icon(Icons.sms_outlined),
                      label: Text(l10n.checkInSendTo(contact.name)),
                    )
                  : null,
            ),
          for (final suggestion in suggestions)
            if (!_contacts.any((c) => c.phone == suggestion.phone))
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.person_add_alt_outlined),
                title: Text(l10n.checkInSuggestion(suggestion.name)),
                subtitle: Text(suggestion.phone),
                onTap: () => _addContact(
                  name: suggestion.name,
                  phone: suggestion.phone,
                ),
              ),
          TextButton.icon(
            onPressed: _addContact,
            icon: const Icon(Icons.add),
            label: Text(l10n.checkInAddContact),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _share(text),
                icon: const Icon(Icons.share_outlined),
                label: Text(l10n.checkInShare),
              ),
              OutlinedButton.icon(
                onPressed: () => _copy(text),
                icon: const Icon(Icons.copy),
                label: Text(l10n.checkInCopy),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(l10n.checkInPrivacy, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }

  /// People the household has already written down with a number: the
  /// contact outside the region in the plan, and the emergency contact
  /// on each member's card.
  static List<CheckInContact> _suggestions(
    String? planName,
    String? planPhone,
    List<String> memberContacts,
  ) {
    final found = <String, CheckInContact>{};
    final planNumber = planPhone == null ? null : normalisePhone(planPhone);
    if (planNumber != null) {
      found[planNumber] = CheckInContact(
        name: planName?.trim().isNotEmpty == true
            ? planName!.trim()
            : planNumber,
        phone: planNumber,
      );
    }
    for (final line in memberContacts) {
      for (final number in phoneNumbersIn(line)) {
        final name = line.split(RegExp(r'[,;:(]|\+|[0-9]')).first.trim();
        found.putIfAbsent(
          number,
          () =>
              CheckInContact(name: name.isEmpty ? number : name, phone: number),
        );
      }
    }
    return found.values.toList();
  }
}

class _ContactDialog extends StatefulWidget {
  const _ContactDialog({required this.l10n, this.name, this.phone});

  final AppLocalizations l10n;
  final String? name;
  final String? phone;

  @override
  State<_ContactDialog> createState() => _ContactDialogState();
}

class _ContactDialogState extends State<_ContactDialog> {
  late final _name = TextEditingController(text: widget.name);
  late final _phone = TextEditingController(text: widget.phone);
  var _invalid = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _submit() {
    final number = normalisePhone(_phone.text);
    if (_name.text.trim().isEmpty || number == null) {
      setState(() => _invalid = true);
      return;
    }
    Navigator.of(
      context,
    ).pop(CheckInContact(name: _name.text.trim(), phone: number));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return AlertDialog(
      title: Text(l10n.checkInAddContact),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              autofocus: widget.name == null,
              decoration: InputDecoration(labelText: l10n.checkInContactName),
            ),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: l10n.checkInContactPhone,
                errorText: _invalid ? l10n.checkInContactInvalid : null,
              ),
              onSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(MaterialLocalizations.of(context).okButtonLabel),
        ),
      ],
    );
  }
}
