import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'resilience_plan.dart';

/// Local-only preparations. These are deliberately kept out of the shared
/// household database: a radio frequency, document location, route, or event
/// note must never leave the device just because household data is synced.
///
/// Not synced is not the same as not kept, though. `BackupService` writes
/// this plan into its own encrypted section of a backup, so a lost or
/// reset device does not take the household's crisis planning with it.
/// That is a deliberate act with a passphrase, not a background copy.
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

  /// Folds a restored plan into the one this device holds.
  ///
  /// Restoring must not wind a plan back: somebody who backs up in March
  /// and restores in September after losing the phone has nothing to lose,
  /// but somebody who restores onto a device they kept using would
  /// otherwise trade the newer plan for the older one.
  Future<void> mergeFrom(PreparednessHubData incoming) async {
    await save((await load()).mergeWith(incoming));
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
    this.autonomy = const AutonomySnapshot(),
    this.waterHygiene = const PlanNote(),
    this.powerOutage = const PlanNote(),
    this.cooking = const PlanNote(),
    this.redundancy = const PlanNote(),
    this.climateRoom = const PlanNote(),
    this.analogFallback = const PlanNote(),
    this.mutualAid = const PlanNote(),
    this.practice = const PlanNote(),
    this.resilience = const ResiliencePlan(),
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
  final AutonomySnapshot autonomy;
  final PlanNote waterHygiene;
  final PlanNote powerOutage;
  final PlanNote cooking;
  final PlanNote redundancy;
  final PlanNote climateRoom;
  final PlanNote analogFallback;
  final PlanNote mutualAid;
  final PlanNote practice;
  final ResiliencePlan resilience;

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
    AutonomySnapshot? autonomy,
    PlanNote? waterHygiene,
    PlanNote? powerOutage,
    PlanNote? cooking,
    PlanNote? redundancy,
    PlanNote? climateRoom,
    PlanNote? analogFallback,
    PlanNote? mutualAid,
    PlanNote? practice,
    ResiliencePlan? resilience,
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
    autonomy: autonomy ?? this.autonomy,
    waterHygiene: waterHygiene ?? this.waterHygiene,
    powerOutage: powerOutage ?? this.powerOutage,
    cooking: cooking ?? this.cooking,
    redundancy: redundancy ?? this.redundancy,
    climateRoom: climateRoom ?? this.climateRoom,
    analogFallback: analogFallback ?? this.analogFallback,
    mutualAid: mutualAid ?? this.mutualAid,
    practice: practice ?? this.practice,
    resilience: resilience ?? this.resilience,
  );

  /// The same rule the household database uses for a shared folder, a QR
  /// chain and a backup: the newer entry is taken, the older one is kept.
  /// Every part of this plan carries the date on which it was last
  /// checked, so "newer" is decided per note, per card and per station
  /// rather than for the plan as a whole.
  PreparednessHubData mergeWith(PreparednessHubData incoming) =>
      PreparednessHubData(
        radioPlans: _mergeById(
          radioPlans,
          incoming.radioPlans,
          (item) => item.id,
          (item) => item.checkedAt,
        ),
        folder: _mergeFolder(folder, incoming.folder),
        maintenance: _mergeDates(maintenance, incoming.maintenance),
        evacuationCards: _mergeById(
          evacuationCards,
          incoming.evacuationCards,
          (item) => item.id,
          (item) => item.checkedAt,
        ),
        // An incident log is a record of what happened, so entries are
        // only ever added. Two devices that were both running during a
        // power cut hold two halves of the same night.
        events: _mergeById(
          events,
          incoming.events,
          (item) => item.id,
          (item) => item.at,
        ),
        communication: _mergeNote(communication, incoming.communication),
        support: _mergeNote(support, incoming.support),
        pets: _mergeNote(pets, incoming.pets),
        mobility: _mergeNote(mobility, incoming.mobility),
        utilities: _mergeNote(utilities, incoming.utilities),
        actionDone: _mergeDates(actionDone, incoming.actionDone),
        // Crisis mode describes what this device is showing right now,
        // not what the household has planned, so a restore never switches
        // it on or off behind somebody's back.
        crisisMode: crisisMode,
        autonomy: _mergeAutonomy(autonomy, incoming.autonomy),
        waterHygiene: _mergeNote(waterHygiene, incoming.waterHygiene),
        powerOutage: _mergeNote(powerOutage, incoming.powerOutage),
        cooking: _mergeNote(cooking, incoming.cooking),
        redundancy: _mergeNote(redundancy, incoming.redundancy),
        climateRoom: _mergeNote(climateRoom, incoming.climateRoom),
        analogFallback: _mergeNote(analogFallback, incoming.analogFallback),
        mutualAid: _mergeNote(mutualAid, incoming.mutualAid),
        practice: _mergeNote(practice, incoming.practice),
        resilience: resilience.mergeWith(incoming.resilience),
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
    'autonomy': autonomy.toJson(),
    'waterHygiene': waterHygiene.toJson(),
    'powerOutage': powerOutage.toJson(),
    'cooking': cooking.toJson(),
    'redundancy': redundancy.toJson(),
    'climateRoom': climateRoom.toJson(),
    'analogFallback': analogFallback.toJson(),
    'mutualAid': mutualAid.toJson(),
    'practice': practice.toJson(),
    'resilience': resilience.toJson(),
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
      autonomy: AutonomySnapshot.fromJson(value['autonomy']),
      waterHygiene: PlanNote.fromJson(value['waterHygiene']),
      powerOutage: PlanNote.fromJson(value['powerOutage']),
      cooking: PlanNote.fromJson(value['cooking']),
      redundancy: PlanNote.fromJson(value['redundancy']),
      climateRoom: PlanNote.fromJson(value['climateRoom']),
      analogFallback: PlanNote.fromJson(value['analogFallback']),
      mutualAid: PlanNote.fromJson(value['mutualAid']),
      practice: PlanNote.fromJson(value['practice']),
      resilience: ResiliencePlan.fromJson(value['resilience']),
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

/// The part of the household's range only it can state.
///
/// This used to hold all five figures and work out the bottleneck from
/// them, beside an inventory that already answered four — the same
/// second, silently disagreeing number the supply calculator once kept.
/// `autonomy_overview.dart` divides the records now; what is left here is
/// the fallback for what they cannot answer, and hygiene, which nothing
/// in this app counts.
class AutonomySnapshot {
  const AutonomySnapshot({
    this.waterDays = 0,
    this.foodDays = 0,
    this.medicineDays = 0,
    this.energyDays = 0,
    this.hygieneDays = 0,
    this.checkedAt,
  });
  final int waterDays, foodDays, medicineDays, energyDays, hygieneDays;
  final DateTime? checkedAt;
  AutonomySnapshot copyWith({
    int? waterDays,
    int? foodDays,
    int? medicineDays,
    int? energyDays,
    int? hygieneDays,
  }) => AutonomySnapshot(
    waterDays: waterDays ?? this.waterDays,
    foodDays: foodDays ?? this.foodDays,
    medicineDays: medicineDays ?? this.medicineDays,
    energyDays: energyDays ?? this.energyDays,
    hygieneDays: hygieneDays ?? this.hygieneDays,
    checkedAt: DateTime.now(),
  );
  Map<String, Object?> toJson() => {
    'waterDays': waterDays,
    'foodDays': foodDays,
    'medicineDays': medicineDays,
    'energyDays': energyDays,
    'hygieneDays': hygieneDays,
    'checkedAt': checkedAt?.toUtc().toIso8601String(),
  };
  static AutonomySnapshot fromJson(Object? value) {
    if (value is! Map) return const AutonomySnapshot();
    int read(String key) => (value[key] as num?)?.toInt().clamp(0, 3650) ?? 0;
    return AutonomySnapshot(
      waterDays: read('waterDays'),
      foodDays: read('foodDays'),
      medicineDays: read('medicineDays'),
      energyDays: read('energyDays'),
      hygieneDays: read('hygieneDays'),
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

/// A note that was never touched loses to one that was; otherwise the
/// later check wins. Text alone does not decide it — an entry without a
/// date is a plan nobody has confirmed.
PlanNote _mergeNote(PlanNote held, PlanNote incoming) {
  if (held.checkedAt == null && held.text.isEmpty) return incoming;
  return _isNewer(incoming.checkedAt, held.checkedAt) ? incoming : held;
}

bool _isNewer(DateTime? candidate, DateTime? held) {
  if (candidate == null) return false;
  if (held == null) return true;
  return candidate.isAfter(held);
}

/// Union by id, held order first, so a restore adds what is missing
/// without reshuffling the list somebody reads under pressure.
List<T> _mergeById<T>(
  List<T> held,
  List<T> incoming,
  String Function(T) idOf,
  DateTime Function(T) dateOf,
) {
  final byId = {for (final item in held) idOf(item): item};
  final order = [for (final item in held) idOf(item)];
  for (final item in incoming) {
    final id = idOf(item);
    final existing = byId[id];
    if (existing == null) {
      order.add(id);
      byId[id] = item;
    } else if (dateOf(item).isAfter(dateOf(existing))) {
      byId[id] = item;
    }
  }
  return [for (final id in order) byId[id] as T];
}

Map<String, DateTime> _mergeDates(
  Map<String, DateTime> held,
  Map<String, DateTime> incoming,
) {
  final result = Map<String, DateTime>.from(held);
  for (final entry in incoming.entries) {
    final existing = result[entry.key];
    if (existing == null || entry.value.isAfter(existing)) {
      result[entry.key] = entry.value;
    }
  }
  return result;
}

EmergencyFolderStatus _mergeFolder(
  EmergencyFolderStatus held,
  EmergencyFolderStatus incoming,
) {
  if (held.lastChecked == null && held.location.isEmpty) return incoming;
  return _isNewer(incoming.lastChecked, held.lastChecked) ? incoming : held;
}

AutonomySnapshot _mergeAutonomy(
  AutonomySnapshot held,
  AutonomySnapshot incoming,
) => _isNewer(incoming.checkedAt, held.checkedAt) ? incoming : held;
