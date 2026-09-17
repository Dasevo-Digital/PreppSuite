import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Local-only preparations. These are deliberately kept out of the shared
/// household database: a radio frequency, document location, route, or event
/// note must never leave the device just because household data is synced.
class PreparednessHubStore {
  const PreparednessHubStore();

  static const _key = 'preparednessHubV1';

  Future<PreparednessHubData> load() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_key);
      if (raw == null) return const PreparednessHubData();
      return PreparednessHubData.fromJson(jsonDecode(raw));
    } on Object {
      return const PreparednessHubData();
    }
  }

  Future<void> save(PreparednessHubData value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(value.toJson()));
  }
}

class PreparednessHubData {
  const PreparednessHubData({
    this.radioPlans = const [],
    this.folder = const EmergencyFolderStatus(),
    this.maintenance = const {},
    this.evacuationCards = const [],
    this.events = const [],
    this.communication = const PlanNote(),
    this.support = const PlanNote(),
    this.pets = const PlanNote(),
    this.mobility = const PlanNote(),
    this.utilities = const PlanNote(),
    this.actionDone = const {},
    this.crisisMode = false,
  });

  final List<RadioReceptionPlan> radioPlans;
  final EmergencyFolderStatus folder;

  /// Task id to the date on which it was last checked.
  final Map<String, DateTime> maintenance;
  final List<EvacuationCard> evacuationCards;
  final List<IncidentEntry> events;
  final PlanNote communication;
  final PlanNote support;
  final PlanNote pets;
  final PlanNote mobility;
  final PlanNote utilities;
  final Map<String, DateTime> actionDone;
  final bool crisisMode;

  PreparednessHubData copyWith({
    List<RadioReceptionPlan>? radioPlans,
    EmergencyFolderStatus? folder,
    Map<String, DateTime>? maintenance,
    List<EvacuationCard>? evacuationCards,
    List<IncidentEntry>? events,
    PlanNote? communication,
    PlanNote? support,
    PlanNote? pets,
    PlanNote? mobility,
    PlanNote? utilities,
    Map<String, DateTime>? actionDone,
    bool? crisisMode,
  }) => PreparednessHubData(
    radioPlans: radioPlans ?? this.radioPlans,
    folder: folder ?? this.folder,
    maintenance: maintenance ?? this.maintenance,
    evacuationCards: evacuationCards ?? this.evacuationCards,
    events: events ?? this.events,
    communication: communication ?? this.communication,
    support: support ?? this.support,
    pets: pets ?? this.pets,
    mobility: mobility ?? this.mobility,
    utilities: utilities ?? this.utilities,
    actionDone: actionDone ?? this.actionDone,
    crisisMode: crisisMode ?? this.crisisMode,
  );

  Map<String, Object?> toJson() => {
    'radioPlans': [for (final item in radioPlans) item.toJson()],
    'folder': folder.toJson(),
    'maintenance': maintenance.map(
      (key, value) => MapEntry(key, value.toUtc().toIso8601String()),
    ),
    'evacuationCards': [for (final item in evacuationCards) item.toJson()],
    'events': [for (final item in events) item.toJson()],
    'communication': communication.toJson(),
    'support': support.toJson(),
    'pets': pets.toJson(),
    'mobility': mobility.toJson(),
    'utilities': utilities.toJson(),
    'actionDone': actionDone.map(
      (key, value) => MapEntry(key, value.toUtc().toIso8601String()),
    ),
    'crisisMode': crisisMode,
  };

  static PreparednessHubData fromJson(Object? value) {
    if (value is! Map) return const PreparednessHubData();
    List<T> items<T>(String key, T? Function(Object?) parse) {
      final raw = value[key];
      if (raw is! List) return const [];
      return raw.map(parse).whereType<T>().toList();
    }

    Map<String, DateTime> dates(String key) {
      final raw = value[key];
      final result = <String, DateTime>{};
      if (raw is Map) {
        for (final entry in raw.entries) {
          final parsed = entry.value is String
              ? DateTime.tryParse(entry.value as String)?.toLocal()
              : null;
          if (entry.key is String && parsed != null) {
            result[entry.key as String] = parsed;
          }
        }
      }
      return result;
    }

    return PreparednessHubData(
      radioPlans: items('radioPlans', RadioReceptionPlan.fromJson),
      folder: EmergencyFolderStatus.fromJson(value['folder']),
      maintenance: dates('maintenance'),
      evacuationCards: items('evacuationCards', EvacuationCard.fromJson),
      events: items('events', IncidentEntry.fromJson),
      communication: PlanNote.fromJson(value['communication']),
      support: PlanNote.fromJson(value['support']),
      pets: PlanNote.fromJson(value['pets']),
      mobility: PlanNote.fromJson(value['mobility']),
      utilities: PlanNote.fromJson(value['utilities']),
      actionDone: dates('actionDone'),
      crisisMode: value['crisisMode'] == true,
    );
  }
}

/// A deliberately free-form, local plan. People should write only what their
/// household needs; the app never supplies names, medical information or an
/// address as a default.
class PlanNote {
  const PlanNote({this.text = '', this.checkedAt});
  final String text;
  final DateTime? checkedAt;
  PlanNote update(String value) =>
      PlanNote(text: value, checkedAt: DateTime.now());
  Map<String, Object?> toJson() => {
    'text': text,
    'checkedAt': checkedAt?.toUtc().toIso8601String(),
  };
  static PlanNote fromJson(Object? value) {
    if (value is! Map) return const PlanNote();
    return PlanNote(
      text: value['text'] is String ? value['text'] as String : '',
      checkedAt: value['checkedAt'] is String
          ? DateTime.tryParse(value['checkedAt'] as String)?.toLocal()
          : null,
    );
  }
}

class RadioReceptionPlan {
  const RadioReceptionPlan({
    required this.id,
    required this.station,
    required this.band,
    required this.frequency,
    required this.receiver,
    required this.power,
    required this.checkedAt,
  });

  factory RadioReceptionPlan.create({
    required String station,
    required String band,
    required String frequency,
    required String receiver,
    required String power,
  }) => RadioReceptionPlan(
    id: const Uuid().v4(),
    station: station,
    band: band,
    frequency: frequency,
    receiver: receiver,
    power: power,
    checkedAt: DateTime.now(),
  );

  final String id;
  final String station;
  final String band;
  final String frequency;
  final String receiver;
  final String power;
  final DateTime checkedAt;

  Map<String, Object?> toJson() => {
    'id': id,
    'station': station,
    'band': band,
    'frequency': frequency,
    'receiver': receiver,
    'power': power,
    'checkedAt': checkedAt.toUtc().toIso8601String(),
  };

  static RadioReceptionPlan? fromJson(Object? value) {
    if (value is! Map) return null;
    final checked = DateTime.tryParse('${value['checkedAt'] ?? ''}');
    final values = [
      value['id'],
      value['station'],
      value['band'],
      value['frequency'],
      value['receiver'],
      value['power'],
    ];
    if (values.any((item) => item is! String) || checked == null) return null;
    return RadioReceptionPlan(
      id: value['id'] as String,
      station: value['station'] as String,
      band: value['band'] as String,
      frequency: value['frequency'] as String,
      receiver: value['receiver'] as String,
      power: value['power'] as String,
      checkedAt: checked.toLocal(),
    );
  }
}

class EmergencyFolderStatus {
  const EmergencyFolderStatus({
    this.location = '',
    this.copiesReady = false,
    this.takeWhenLeaving = false,
    this.lastChecked,
  });
  final String location;
  final bool copiesReady;
  final bool takeWhenLeaving;
  final DateTime? lastChecked;

  EmergencyFolderStatus copyWith({
    String? location,
    bool? copiesReady,
    bool? takeWhenLeaving,
    DateTime? lastChecked,
  }) => EmergencyFolderStatus(
    location: location ?? this.location,
    copiesReady: copiesReady ?? this.copiesReady,
    takeWhenLeaving: takeWhenLeaving ?? this.takeWhenLeaving,
    lastChecked: lastChecked ?? this.lastChecked,
  );
  Map<String, Object?> toJson() => {
    'location': location,
    'copiesReady': copiesReady,
    'takeWhenLeaving': takeWhenLeaving,
    'lastChecked': lastChecked?.toUtc().toIso8601String(),
  };
  static EmergencyFolderStatus fromJson(Object? value) {
    if (value is! Map) return const EmergencyFolderStatus();
    return EmergencyFolderStatus(
      location: value['location'] is String ? value['location'] as String : '',
      copiesReady: value['copiesReady'] == true,
      takeWhenLeaving: value['takeWhenLeaving'] == true,
      lastChecked: value['lastChecked'] is String
          ? DateTime.tryParse(value['lastChecked'] as String)?.toLocal()
          : null,
    );
  }
}

class EvacuationCard {
  const EvacuationCard({
    required this.id,
    required this.label,
    required this.start,
    required this.destination,
    required this.route,
    required this.locations,
    required this.checkedAt,
  });
  factory EvacuationCard.create({
    required String label,
    required String start,
    required String destination,
    required String route,
    required String locations,
  }) => EvacuationCard(
    id: const Uuid().v4(),
    label: label,
    start: start,
    destination: destination,
    route: route,
    locations: locations,
    checkedAt: DateTime.now(),
  );
  final String id, label, start, destination, route, locations;
  final DateTime checkedAt;
  Map<String, Object?> toJson() => {
    'id': id,
    'label': label,
    'start': start,
    'destination': destination,
    'route': route,
    'locations': locations,
    'checkedAt': checkedAt.toUtc().toIso8601String(),
  };
  static EvacuationCard? fromJson(Object? value) {
    if (value is! Map) return null;
    final checked = DateTime.tryParse('${value['checkedAt'] ?? ''}');
    final values = [
      value['id'],
      value['label'],
      value['start'],
      value['destination'],
      value['route'],
      value['locations'],
    ];
    if (values.any((item) => item is! String) || checked == null) return null;
    return EvacuationCard(
      id: value['id'] as String,
      label: value['label'] as String,
      start: value['start'] as String,
      destination: value['destination'] as String,
      route: value['route'] as String,
      locations: value['locations'] as String,
      checkedAt: checked.toLocal(),
    );
  }
}

class IncidentEntry {
  const IncidentEntry({
    required this.id,
    required this.at,
    required this.kind,
    required this.note,
    required this.action,
  });
  factory IncidentEntry.create({
    required String kind,
    required String note,
    required String action,
  }) => IncidentEntry(
    id: const Uuid().v4(),
    at: DateTime.now(),
    kind: kind,
    note: note,
    action: action,
  );
  final String id, kind, note, action;
  final DateTime at;
  Map<String, Object?> toJson() => {
    'id': id,
    'at': at.toUtc().toIso8601String(),
    'kind': kind,
    'note': note,
    'action': action,
  };
  static IncidentEntry? fromJson(Object? value) {
    if (value is! Map) return null;
    final at = DateTime.tryParse('${value['at'] ?? ''}');
    final values = [value['id'], value['kind'], value['note'], value['action']];
    if (values.any((item) => item is! String) || at == null) return null;
    return IncidentEntry(
      id: value['id'] as String,
      at: at.toLocal(),
      kind: value['kind'] as String,
      note: value['note'] as String,
      action: value['action'] as String,
    );
  }
}
