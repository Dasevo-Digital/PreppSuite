import 'dart:async' show unawaited;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../application/preparedness_hub_store.dart';

/// Private, offline planning tools. The screen intentionally has no map or
/// cloud action: routes and sensitive document locations stay on this device.
class PreparednessHubScreen extends StatefulWidget {
  const PreparednessHubScreen({super.key});

  @override
  State<PreparednessHubScreen> createState() => _PreparednessHubScreenState();
}

class _PreparednessHubScreenState extends State<PreparednessHubScreen> {
  static const _store = PreparednessHubStore();
  PreparednessHubData _data = const PreparednessHubData();
  var _loading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final data = await _store.load();
    if (mounted) {
      setState(() {
        _data = data;
        _loading = false;
      });
    }
  }

  Future<void> _change(PreparednessHubData value) async {
    setState(() => _data = value);
    await _store.save(value);
  }

  String _date(DateTime? value) => value == null
      ? 'noch nicht geprüft'
      : MaterialLocalizations.of(context).formatMediumDate(value);

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Krisenorganisation')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Alle Angaben bleiben auf diesem Gerät. Exportierst du ein Ereignisprotokoll, entscheidest du selbst über den Empfänger.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              _section(
                'Radio-Empfangsplan',
                Icons.radio_outlined,
                'Lokale UKW- und DAB-Stationen, Geräte und Stromversorgung festhalten.',
                _radioPlan(),
              ),
              _section(
                'Notfallmappe',
                Icons.folder_copy_outlined,
                'Dokumentenmappe ohne Inhalte oder Personenangaben verwalten.',
                _folder(),
              ),
              _section(
                'Wartungszentrale',
                Icons.build_outlined,
                'Regelmäßig prüfen, damit wichtige Ausrüstung im Notfall einsatzbereit ist.',
                _maintenance(),
              ),
              _section(
                'Evakuierungs-Karten',
                Icons.route_outlined,
                'Treffpunkte und sichere Wege als offline lesbare Karten notieren.',
                _evacuation(),
              ),
              _section(
                'Ereignisprotokoll',
                Icons.history_edu_outlined,
                'Beobachtungen und Maßnahmen mit Uhrzeit dokumentieren und bei Bedarf als PDF exportieren.',
                _events(),
              ),
            ],
          ),
  );

  Widget _section(
    String title,
    IconData icon,
    String description,
    Widget content,
  ) => Card(
    clipBehavior: Clip.antiAlias,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(description),
          const SizedBox(height: 12),
          content,
        ],
      ),
    ),
  );

  Widget _radioPlan() => Column(
    children: [
      for (final plan in _data.radioPlans)
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(plan.station),
          subtitle: Text(
            '${plan.band} · ${plan.frequency}\n${plan.receiver} · ${plan.power}\nGetestet: ${_date(plan.checkedAt)}',
          ),
          isThreeLine: true,
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Eintrag entfernen',
            onPressed: () => _change(
              _data.copyWith(
                radioPlans: [
                  for (final item in _data.radioPlans)
                    if (item.id != plan.id) item,
                ],
              ),
            ),
          ),
        ),
      Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          onPressed: _addRadio,
          icon: const Icon(Icons.add),
          label: const Text('Empfang hinzufügen'),
        ),
      ),
    ],
  );

  Widget _folder() {
    final folder = _data.folder;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.place_outlined),
          title: const Text('Aufbewahrungsort'),
          subtitle: Text(
            folder.location.isEmpty ? 'nicht hinterlegt' : folder.location,
          ),
          trailing: const Icon(Icons.edit_outlined),
          onTap: _editFolderLocation,
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: folder.copiesReady,
          title: const Text('Kopien wichtiger Unterlagen vorhanden'),
          onChanged: (value) => _change(
            _data.copyWith(folder: folder.copyWith(copiesReady: value == true)),
          ),
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: folder.takeWhenLeaving,
          title: const Text('Bei Evakuierung mitnehmen'),
          onChanged: (value) => _change(
            _data.copyWith(
              folder: folder.copyWith(takeWhenLeaving: value == true),
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => _change(
              _data.copyWith(
                folder: folder.copyWith(lastChecked: DateTime.now()),
              ),
            ),
            icon: const Icon(Icons.verified_outlined),
            label: Text(
              'Heute geprüft${folder.lastChecked == null ? '' : ' · zuletzt ${_date(folder.lastChecked)}'}',
            ),
          ),
        ),
      ],
    );
  }

  Widget _maintenance() => Column(
    children: [
      for (final task in _maintenanceTasks)
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: _data.maintenance.containsKey(task.id),
          title: Text(task.title),
          subtitle: Text(
            _data.maintenance[task.id] == null
                ? task.hint
                : 'Zuletzt geprüft: ${_date(_data.maintenance[task.id])}',
          ),
          onChanged: (value) {
            final updated = {..._data.maintenance};
            if (value == true) {
              updated[task.id] = DateTime.now();
            } else {
              updated.remove(task.id);
            }
            unawaited(_change(_data.copyWith(maintenance: updated)));
          },
        ),
    ],
  );

  Widget _evacuation() => Column(
    children: [
      for (final card in _data.evacuationCards)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.map_outlined),
          title: Text(card.label),
          subtitle: Text(
            '${card.start.isEmpty ? 'Start offen' : card.start} → ${card.destination.isEmpty ? 'Ziel offen' : card.destination}\nGeprüft: ${_date(card.checkedAt)}',
          ),
          isThreeLine: true,
          onTap: () => _showEvacuation(card),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Karte entfernen',
            onPressed: () => _change(
              _data.copyWith(
                evacuationCards: [
                  for (final item in _data.evacuationCards)
                    if (item.id != card.id) item,
                ],
              ),
            ),
          ),
        ),
      Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          onPressed: () => _editEvacuation(),
          icon: const Icon(Icons.add),
          label: const Text('Karte hinzufügen'),
        ),
      ),
    ],
  );

  Widget _events() => Column(
    children: [
      for (final event in _data.events.take(5))
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.notes_outlined),
          title: Text(event.kind),
          subtitle: Text(
            '${_dateTime(event.at)}\n${event.note.isEmpty ? event.action : event.note}',
          ),
          isThreeLine: true,
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Eintrag entfernen',
            onPressed: () => _change(
              _data.copyWith(
                events: [
                  for (final item in _data.events)
                    if (item.id != event.id) item,
                ],
              ),
            ),
          ),
        ),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          OutlinedButton.icon(
            onPressed: _addEvent,
            icon: const Icon(Icons.add),
            label: const Text('Eintrag hinzufügen'),
          ),
          if (_data.events.isNotEmpty)
            FilledButton.icon(
              onPressed: _exportEvents,
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('PDF exportieren'),
            ),
        ],
      ),
    ],
  );

  String _dateTime(DateTime date) =>
      '${_date(date)} · ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(date))}';

  Future<void> _addRadio() async {
    final station = TextEditingController();
    final frequency = TextEditingController();
    final receiver = TextEditingController();
    final power = TextEditingController(text: 'Batterien');
    var band = 'UKW';
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Radio-Empfang hinzufügen'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: station,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Sender'),
                ),
                DropdownButtonFormField(
                  initialValue: band,
                  decoration: const InputDecoration(labelText: 'Band'),
                  items: const [
                    DropdownMenuItem(value: 'UKW', child: Text('UKW')),
                    DropdownMenuItem(value: 'DAB+', child: Text('DAB+')),
                  ],
                  onChanged: (value) => setDialogState(() => band = value!),
                ),
                TextField(
                  controller: frequency,
                  decoration: const InputDecoration(
                    labelText: 'Frequenz oder Kanal',
                  ),
                ),
                TextField(
                  controller: receiver,
                  decoration: const InputDecoration(labelText: 'Empfänger'),
                ),
                TextField(
                  controller: power,
                  decoration: const InputDecoration(
                    labelText: 'Stromversorgung',
                  ),
                ),
              ],
            ),
          ),
          actions: _dialogActions(context, () => Navigator.pop(context, true)),
        ),
      ),
    );
    if (saved == true && station.text.trim().isNotEmpty) {
      await _change(
        _data.copyWith(
          radioPlans: [
            ..._data.radioPlans,
            RadioReceptionPlan.create(
              station: station.text.trim(),
              band: band,
              frequency: frequency.text.trim(),
              receiver: receiver.text.trim(),
              power: power.text.trim(),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _editFolderLocation() async {
    final location = TextEditingController(text: _data.folder.location);
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aufbewahrungsort'),
        content: TextField(
          controller: location,
          autofocus: true,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'z. B. abschließbarer Schrank',
          ),
        ),
        actions: _dialogActions(context, () => Navigator.pop(context, true)),
      ),
    );
    if (saved == true) {
      await _change(
        _data.copyWith(
          folder: _data.folder.copyWith(location: location.text.trim()),
        ),
      );
    }
  }

  Future<void> _editEvacuation([EvacuationCard? current]) async {
    final label = TextEditingController(text: current?.label ?? '');
    final start = TextEditingController(text: current?.start ?? '');
    final destination = TextEditingController(text: current?.destination ?? '');
    final route = TextEditingController(text: current?.route ?? '');
    final locations = TextEditingController(text: current?.locations ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(current == null ? 'Evakuierungs-Karte' : current.label),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: label,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Bezeichnung, z. B. Zuhause',
                ),
              ),
              TextField(
                controller: start,
                decoration: const InputDecoration(labelText: 'Startpunkt'),
              ),
              TextField(
                controller: destination,
                decoration: const InputDecoration(
                  labelText: 'Treffpunkt oder Ziel',
                ),
              ),
              TextField(
                controller: route,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Weg und Alternativen',
                ),
              ),
              TextField(
                controller: locations,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Wichtige Orte unterwegs',
                ),
              ),
            ],
          ),
        ),
        actions: _dialogActions(context, () => Navigator.pop(context, true)),
      ),
    );
    if (saved != true || label.text.trim().isEmpty) return;
    final edited = EvacuationCard.create(
      label: label.text.trim(),
      start: start.text.trim(),
      destination: destination.text.trim(),
      route: route.text.trim(),
      locations: locations.text.trim(),
    );
    await _change(
      _data.copyWith(
        evacuationCards: current == null
            ? [..._data.evacuationCards, edited]
            : [
                for (final item in _data.evacuationCards)
                  if (item.id == current.id) edited else item,
              ],
      ),
    );
  }

  Future<void> _showEvacuation(EvacuationCard card) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(card.label),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Start: ${card.start.isEmpty ? '–' : card.start}'),
            Text('Ziel: ${card.destination.isEmpty ? '–' : card.destination}'),
            const SizedBox(height: 12),
            const Text(
              'Weg und Alternativen',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(card.route.isEmpty ? '–' : card.route),
            const SizedBox(height: 12),
            const Text(
              'Wichtige Orte',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(card.locations.isEmpty ? '–' : card.locations),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Schließen'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context);
            _editEvacuation(card);
          },
          child: const Text('Bearbeiten'),
        ),
      ],
    ),
  );

  Future<void> _addEvent() async {
    final kind = TextEditingController(text: 'Beobachtung');
    final note = TextEditingController();
    final action = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ereignis dokumentieren'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: kind,
                decoration: const InputDecoration(labelText: 'Art'),
              ),
              TextField(
                controller: note,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Beobachtung oder Schaden',
                ),
              ),
              TextField(
                controller: action,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Getroffene Maßnahme',
                ),
              ),
            ],
          ),
        ),
        actions: _dialogActions(context, () => Navigator.pop(context, true)),
      ),
    );
    if (saved == true &&
        (note.text.trim().isNotEmpty || action.text.trim().isNotEmpty)) {
      await _change(
        _data.copyWith(
          events: [
            IncidentEntry.create(
              kind: kind.text.trim().isEmpty ? 'Ereignis' : kind.text.trim(),
              note: note.text.trim(),
              action: action.text.trim(),
            ),
            ..._data.events,
          ],
        ),
      );
    }
  }

  List<Widget> _dialogActions(BuildContext context, VoidCallback save) => [
    TextButton(
      onPressed: () => Navigator.pop(context),
      child: const Text('Abbrechen'),
    ),
    FilledButton(onPressed: save, child: const Text('Speichern')),
  ];

  Future<void> _exportEvents() async {
    final document = pw.Document();
    document.addPage(
      pw.MultiPage(
        build: (_) => [
          pw.Header(level: 0, child: pw.Text('PreppSuite – Ereignisprotokoll')),
          for (final event in _data.events)
            pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 12),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    event.kind,
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(event.at.toLocal().toString()),
                  if (event.note.isNotEmpty)
                    pw.Text('Beobachtung: ${event.note}'),
                  if (event.action.isNotEmpty)
                    pw.Text('Maßnahme: ${event.action}'),
                ],
              ),
            ),
        ],
      ),
    );
    final bytes = await document.save();
    if (mounted) {
      await Printing.sharePdf(
        bytes: Uint8List.fromList(bytes),
        filename: 'preppsuite-ereignisprotokoll.pdf',
      );
    }
  }
}

class _MaintenanceTask {
  const _MaintenanceTask(this.id, this.title, this.hint);
  final String id, title, hint;
}

const _maintenanceTasks = [
  _MaintenanceTask(
    'batteries',
    'Akkus, Batterien und Powerbanks',
    'Ladezustand und Ersatzbatterien prüfen',
  ),
  _MaintenanceTask(
    'radio',
    'Radio und Empfangsplan',
    'Sender, Antenne und Stromversorgung testen',
  ),
  _MaintenanceTask(
    'water_filter',
    'Wasserfilter und Kanister',
    'Filterzustand, Dichtungen und Vorrat prüfen',
  ),
  _MaintenanceTask(
    'kit',
    'Notgepäck',
    'Kleidung, Licht und persönliche Bedarfe prüfen',
  ),
  _MaintenanceTask(
    'medicine',
    'Hausapotheke',
    'Haltbarkeit und persönliche Medikamente prüfen',
  ),
  _MaintenanceTask(
    'extinguisher',
    'Feuerlöscher und Rauchmelder',
    'Prüftermin und Batterien prüfen',
  ),
  _MaintenanceTask(
    'vehicle',
    'Fahrzeug und Mobilität',
    'Kraftstoff, Reifen und alternative Wege prüfen',
  ),
];
