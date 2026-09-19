import 'dart:async' show unawaited;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../inventory/presentation/prepper_recipes_screen.dart';
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
        : MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(_data.crisisMode ? 1.25 : 1),
            ),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Alle Angaben bleiben auf diesem Gerät. Exportierst du ein Ereignisprotokoll, entscheidest du selbst über den Empfänger.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                _section(
                  'Autarkie-Status',
                  Icons.monitor_heart_outlined,
                  'Geprüfte Reichweite in Tagen. Der niedrigste Wert zeigt den nächsten Engpass.',
                  _autonomy(),
                ),
                _section(
                  'Wasser und Hygiene',
                  Icons.water_drop_outlined,
                  'Trink- und Brauchwasser, Aufbereitung, Kanisterrotation, Toilette und Abfall getrennt planen.',
                  _planNote(
                    note: _data.waterHygiene,
                    label: 'Wasser- und Hygieneplan',
                    hint:
                        'Trinkwasser: …\nBrauchwasser: …\nQuellen und Aufbereitung: …\nKanisterrotation: …\nToilette, Abfall und Reinigungsmittel: …',
                    onSave: (value) =>
                        _change(_data.copyWith(waterHygiene: value)),
                  ),
                ),
                _section(
                  'Stromausfall-Plan',
                  Icons.power_outlined,
                  'Startzeit, Kühlkette, Ladeprioritäten, Licht, Information und sichere Wärme vorbereiten.',
                  _planNote(
                    note: _data.powerOutage,
                    label: 'Stromausfall-Plan',
                    hint:
                        'Startzeit notieren. Kühl- und Gefriergeräte geschlossen halten. Ladeprioritäten, Radio, Licht, sichere Wärme und Ansprechpartner festhalten.',
                    onSave: (value) =>
                        _change(_data.copyWith(powerOutage: value)),
                  ),
                ),
                _section(
                  'Vorratsküche',
                  Icons.soup_kitchen_outlined,
                  'Mahlzeiten nach Vorrat, Wasser- und Brennstoffbedarf planen.',
                  _cookingPlan(),
                ),
                _section(
                  'Redundanz-Check',
                  Icons.account_tree_outlined,
                  'Zweite Wege für Wasser, Licht, Kochen, Information und Kommunikation festhalten.',
                  _planNote(
                    note: _data.redundancy,
                    label: 'Redundanz-Check',
                    hint:
                        'Wasser: Hauptweg / Ersatzweg\nLicht: Hauptweg / Ersatzweg\nKochen: Hauptweg / Ersatzweg\nInformation und Kommunikation: Hauptweg / Ersatzweg',
                    onSave: (value) =>
                        _change(_data.copyWith(redundancy: value)),
                  ),
                ),
                _section(
                  'Kälte- und Hitze-Schutzraum',
                  Icons.thermostat_outlined,
                  'Geeigneten Aufenthaltsraum, Kleidung, Lüftung und sichere Wärme oder Kühlung vorab bestimmen.',
                  _planNote(
                    note: _data.climateRoom,
                    label: 'Schutzraum für Kälte und Hitze',
                    hint:
                        'Raum: …\nWärme/Kühlung: …\nDecken und Kleidung: …\nLüftung: …\nCO-Melder und sichere Geräte: …',
                    onSave: (value) =>
                        _change(_data.copyWith(climateRoom: value)),
                  ),
                ),
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
                  'Kommunikationsplan',
                  Icons.forum_outlined,
                  'Kontakt-Reihenfolge, externe Kontaktperson und kurze Statusmeldungen für überlastete Netze.',
                  _planNote(
                    note: _data.communication,
                    label: 'Kommunikationsplan',
                    hint:
                        'Wer wird in welcher Reihenfolge kontaktiert? Welche externe Kontaktperson koordiniert?\n\nVorlage: Wir sind sicher. Nächster Kontakt um …',
                    onSave: (value) =>
                        _change(_data.copyWith(communication: value)),
                    templates: const [
                      'Wir sind sicher. Nächster Kontakt um …',
                      'Wir brauchen Unterstützung bei … Treffpunkt: …',
                    ],
                  ),
                ),
                _section(
                  'Unterstützungsplan',
                  Icons.accessible_forward_outlined,
                  'Persönliche Unterstützung, Medikamente, Hilfsmittel und Transport bei einer Evakuierung.',
                  _planNote(
                    note: _data.support,
                    label: 'Unterstützungsplan',
                    hint:
                        'Nur notwendige Angaben: benötigte Hilfe, Medikamente, Hilfsmittel, verlässliche Unterstützung und Transport.',
                    onSave: (value) => _change(_data.copyWith(support: value)),
                  ),
                ),
                _section(
                  'Haustier-Notfallplan',
                  Icons.pets_outlined,
                  'Transport, Futter, Medikamente, Betreuung und Ausweichunterkunft für Tiere vorbereiten.',
                  _planNote(
                    note: _data.pets,
                    label: 'Haustier-Notfallplan',
                    hint:
                        'Transportbox, Vorräte, Tierarzt, Betreuung, tierfreundliche Unterkunft und Dokumentenkopien.',
                    onSave: (value) => _change(_data.copyWith(pets: value)),
                  ),
                ),
                _section(
                  'Fahrzeug und Mobilität',
                  Icons.directions_car_outlined,
                  'Fahrzeug-Notgepäck, Energie- oder Tankreserve, alternative Verkehrsmittel und Abholung.',
                  _planNote(
                    note: _data.mobility,
                    label: 'Mobilitätsplan',
                    hint:
                        'Fahrzeug, Lade- oder Tankziel, Notgepäck, alternative Route, ÖPNV und Abholung.',
                    onSave: (value) => _change(_data.copyWith(mobility: value)),
                  ),
                ),
                _section(
                  'Versorgungs-Unterbrechung',
                  Icons.power_off_outlined,
                  'Absperrorte und manuelle Alternativen für Strom, Wasser, Gas, Heizung und Telekommunikation.',
                  _planNote(
                    note: _data.utilities,
                    label: 'Versorgungsplan',
                    hint:
                        'Absperrorte, Ansprechpartner, Ersatzstrom, Wasserentnahme, Heizung und kontaktlose Kommunikationswege.',
                    onSave: (value) =>
                        _change(_data.copyWith(utilities: value)),
                  ),
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
                _section(
                  'Handlungskarten',
                  Icons.timer_outlined,
                  'Vorbereitung nach Vorwarnzeit: sofort, innerhalb von 48 Stunden und mehrere Tage vorher.',
                  _actionCards(),
                ),
                _section(
                  'Krisenmodus und Briefing',
                  Icons.visibility_outlined,
                  'Größere Darstellung für diese Seite und ein druckbares Briefing für Haushalt oder Notgepäck.',
                  _crisisTools(),
                ),
                _section(
                  'Analoger Fallback',
                  Icons.print_outlined,
                  'Ausdrucke, Karten, Notizen und Ersatzschlüssel ohne Akku oder Netz verfügbar halten.',
                  _planNote(
                    note: _data.analogFallback,
                    label: 'Analoger Fallback',
                    hint:
                        'Gedruckte Karten, Telefonliste, Anleitungen, Bargeld, Ersatzschlüssel und Aufbewahrungsort.',
                    onSave: (value) =>
                        _change(_data.copyWith(analogFallback: value)),
                  ),
                ),
                _section(
                  'Nachbarschaftshilfe',
                  Icons.volunteer_activism_outlined,
                  'Fähigkeiten, Hilfsmittel und sichere Kontaktwege lokal planen; keine Daten werden veröffentlicht.',
                  _planNote(
                    note: _data.mutualAid,
                    label: 'Hilfe- und Tauschkarte',
                    hint:
                        'Eigene Fähigkeiten und Hilfsmittel, benötigte Unterstützung, vertrauenswürdige Kontakte und Übergabeort.',
                    onSave: (value) =>
                        _change(_data.copyWith(mutualAid: value)),
                  ),
                ),
                _section(
                  'Praxis und Wartung',
                  Icons.event_repeat_outlined,
                  'Regelmäßig Wasserfilter, Kochen, Radio, Notgepäck und analoge Abläufe praktisch üben.',
                  _planNote(
                    note: _data.practice,
                    label: 'Praxis-Wartungsplan',
                    hint:
                        'Nächste Übung: …\nWasserfilter testen: …\nOhne Strom kochen: …\nRadio und Notgepäck prüfen: …',
                    onSave: (value) => _change(_data.copyWith(practice: value)),
                  ),
                ),
              ],
            ),
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

  Widget _autonomy() {
    final snapshot = _data.autonomy;
    final limiting = snapshot.limitingDays;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (limiting == 0)
          Text(
            'Autarkie noch unvollständig. Offen: ${snapshot.entries.where((entry) => entry.$2 == 0).map((entry) => entry.$1).join(', ')}.',
          )
        else
          Text(
            '$limiting Tage autark – Engpass: ${snapshot.bottleneck}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        const SizedBox(height: 8),
        for (final entry in snapshot.entries)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              entry.$2 == limiting && limiting > 0
                  ? Icons.priority_high
                  : Icons.check_circle_outline,
            ),
            title: Text(entry.$1),
            trailing: Text(entry.$2 == 0 ? 'offen' : '${entry.$2} Tage'),
          ),
        OutlinedButton.icon(
          onPressed: _editAutonomy,
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Reichweite eintragen'),
        ),
      ],
    );
  }

  Future<void> _editAutonomy() async {
    final snapshot = _data.autonomy;
    final water = TextEditingController(text: '${snapshot.waterDays}');
    final food = TextEditingController(text: '${snapshot.foodDays}');
    final medicine = TextEditingController(text: '${snapshot.medicineDays}');
    final energy = TextEditingController(text: '${snapshot.energyDays}');
    final hygiene = TextEditingController(text: '${snapshot.hygieneDays}');
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Autarkie-Reichweite'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _daysField(water, 'Wasser'),
              _daysField(food, 'Lebensmittel'),
              _daysField(medicine, 'Medikamente'),
              _daysField(energy, 'Energie'),
              _daysField(hygiene, 'Hygiene'),
            ],
          ),
        ),
        actions: _dialogActions(context, () => Navigator.pop(context, true)),
      ),
    );
    if (saved != true) return;
    int read(TextEditingController value) =>
        (int.tryParse(value.text.trim())?.clamp(0, 3650) ?? 0).toInt();
    await _change(
      _data.copyWith(
        autonomy: snapshot.copyWith(
          waterDays: read(water),
          foodDays: read(food),
          medicineDays: read(medicine),
          energyDays: read(energy),
          hygieneDays: read(hygiene),
        ),
      ),
    );
  }

  Widget _daysField(TextEditingController controller, String label) =>
      TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: '$label – Tage'),
      );

  Widget _cookingPlan() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _planNote(
        note: _data.cooking,
        label: 'Vorratsküchenplan',
        hint:
            'Gericht: …\nZutaten aus dem Vorrat: …\nWasser: …\nBrennstoff und Kochzeit: …\nSichere Kochstelle: …',
        onSave: (value) => _change(_data.copyWith(cooking: value)),
      ),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const PrepperRecipesScreen()),
        ),
        icon: const Icon(Icons.menu_book_outlined),
        label: const Text('Offline-Rezepte öffnen'),
      ),
    ],
  );

  Widget _planNote({
    required PlanNote note,
    required String label,
    required String hint,
    required ValueChanged<PlanNote> onSave,
    List<String> templates = const [],
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(note.text.isEmpty ? 'Noch nicht hinterlegt.' : note.text),
      if (note.checkedAt != null) ...[
        const SizedBox(height: 4),
        Text(
          'Zuletzt aktualisiert: ${_date(note.checkedAt)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          OutlinedButton.icon(
            onPressed: () => _editPlanNote(
              title: label,
              current: note,
              hint: hint,
              onSave: onSave,
            ),
            icon: const Icon(Icons.edit_outlined),
            label: Text(note.text.isEmpty ? 'Plan anlegen' : 'Bearbeiten'),
          ),
          for (final template in templates)
            TextButton.icon(
              onPressed: () => Clipboard.setData(ClipboardData(text: template)),
              icon: const Icon(Icons.copy_outlined),
              label: const Text('Vorlage kopieren'),
            ),
        ],
      ),
    ],
  );

  Future<void> _editPlanNote({
    required String title,
    required PlanNote current,
    required String hint,
    required ValueChanged<PlanNote> onSave,
  }) async {
    final controller = TextEditingController(text: current.text);
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 5,
          maxLines: 12,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: _dialogActions(context, () => Navigator.pop(context, true)),
      ),
    );
    if (saved == true) onSave(current.update(controller.text.trim()));
  }

  Widget _actionCards() => Column(
    children: [
      for (final action in _actionTasks)
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: _data.actionDone.containsKey(action.id),
          title: Text(action.title),
          subtitle: Text(
            _data.actionDone[action.id] == null
                ? action.body
                : 'Erledigt: ${_date(_data.actionDone[action.id])}',
          ),
          onChanged: (value) {
            final updated = {..._data.actionDone};
            if (value == true) {
              updated[action.id] = DateTime.now();
            } else {
              updated.remove(action.id);
            }
            unawaited(_change(_data.copyWith(actionDone: updated)));
          },
        ),
    ],
  );

  Widget _crisisTools() => Column(
    children: [
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: _data.crisisMode,
        title: const Text('Vereinfachte, größere Darstellung'),
        subtitle: const Text(
          'Vergrößert Text und Bedienelemente in der Krisenorganisation.',
        ),
        onChanged: (value) => _change(_data.copyWith(crisisMode: value)),
      ),
      Align(
        alignment: Alignment.centerLeft,
        child: FilledButton.icon(
          onPressed: _exportBriefing,
          icon: const Icon(Icons.print_outlined),
          label: const Text('Notfallbriefing als PDF'),
        ),
      ),
    ],
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

  Future<void> _exportBriefing() async {
    final document = pw.Document();
    final plans = [
      ('Kommunikation', _data.communication.text),
      ('Unterstützung', _data.support.text),
      ('Haustiere', _data.pets.text),
      ('Mobilität', _data.mobility.text),
      ('Versorgung', _data.utilities.text),
      ('Notfallmappe', _data.folder.location),
      ('Wasser und Hygiene', _data.waterHygiene.text),
      ('Stromausfall', _data.powerOutage.text),
      ('Vorratsküche', _data.cooking.text),
      ('Redundanz', _data.redundancy.text),
      ('Kälte und Hitze', _data.climateRoom.text),
      ('Analoger Fallback', _data.analogFallback.text),
      ('Nachbarschaftshilfe', _data.mutualAid.text),
      ('Praxis und Wartung', _data.practice.text),
    ];
    document.addPage(
      pw.MultiPage(
        build: (_) => [
          pw.Header(level: 0, child: pw.Text('PreppSuite – Notfallbriefing')),
          pw.Text('Erstellt: ${DateTime.now().toLocal()}'),
          pw.SizedBox(height: 12),
          for (final plan in plans)
            if (plan.$2.isNotEmpty)
              pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 10),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      plan.$1,
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(plan.$2),
                  ],
                ),
              ),
          if (_data.radioPlans.isNotEmpty) ...[
            pw.Text(
              'Radio',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            for (final radio in _data.radioPlans)
              pw.Text(
                '${radio.station}: ${radio.band} ${radio.frequency} · ${radio.receiver}',
              ),
          ],
          if (_data.evacuationCards.isNotEmpty) ...[
            pw.SizedBox(height: 10),
            pw.Text(
              'Evakuierung',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            for (final card in _data.evacuationCards)
              pw.Text('${card.label}: ${card.start} → ${card.destination}'),
          ],
        ],
      ),
    );
    final bytes = await document.save();
    if (mounted) {
      await Printing.sharePdf(
        bytes: Uint8List.fromList(bytes),
        filename: 'preppsuite-notfallbriefing.pdf',
      );
    }
  }
}

class _MaintenanceTask {
  const _MaintenanceTask(this.id, this.title, this.hint);
  final String id, title, hint;
}

class _ActionTask {
  const _ActionTask(this.id, this.title, this.body);
  final String id, title, body;
}

const _actionTasks = [
  _ActionTask(
    'now',
    'Jetzt',
    'Amtliche Meldung lesen, Gefahr vermeiden, Radio einschalten und Angehörige kurz informieren.',
  ),
  _ActionTask(
    'two_days',
    'Innerhalb von 24–48 Stunden',
    'Wasser, Vorrat, Medikamente, Akkus und Fahrzeug prüfen. Haus und Notgepäck vorbereiten.',
  ),
  _ActionTask(
    'days',
    'Mehrere Tage vorher',
    'Evakuierungs-Karte abgleichen, Unterstützung organisieren, Haustier- und Versorgungsplan prüfen.',
  ),
];

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
