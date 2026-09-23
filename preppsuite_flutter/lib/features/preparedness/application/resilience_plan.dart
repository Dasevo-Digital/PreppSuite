import 'package:uuid/uuid.dart';

/// Private resilience planning that stays on this device with the crisis hub.
///
/// The entries deliberately contain no contacts from the address book, GPS
/// co-ordinates, or account identifiers. A household can record an alias and
/// an agreed contact method, then decide separately whether it belongs in an
/// encrypted backup or a printed briefing.
class ResiliencePlan {
  const ResiliencePlan({
    this.warningChecks = const {},
    this.support = const IndividualSupportPlan(),
    this.sources = const [],
    this.learningChecks = const {},
    this.neighborhood = const [],
    this.maintenanceEveryDays = const {},
  });

  /// Check id to the most recent successful real-world test.
  final Map<String, DateTime> warningChecks;
  final IndividualSupportPlan support;
  final List<TrustedSource> sources;
  final Map<String, DateTime> learningChecks;
  final List<NeighborhoodCapability> neighborhood;

  /// A zero or missing entry means "not scheduled", never "overdue".
  final Map<String, int> maintenanceEveryDays;

  ResiliencePlan copyWith({
    Map<String, DateTime>? warningChecks,
    IndividualSupportPlan? support,
    List<TrustedSource>? sources,
    Map<String, DateTime>? learningChecks,
    List<NeighborhoodCapability>? neighborhood,
    Map<String, int>? maintenanceEveryDays,
  }) => ResiliencePlan(
    warningChecks: warningChecks ?? this.warningChecks,
    support: support ?? this.support,
    sources: sources ?? this.sources,
    learningChecks: learningChecks ?? this.learningChecks,
    neighborhood: neighborhood ?? this.neighborhood,
    maintenanceEveryDays: maintenanceEveryDays ?? this.maintenanceEveryDays,
  );

  Map<String, Object?> toJson() => {
    'warningChecks': _dateMapToJson(warningChecks),
    'support': support.toJson(),
    'sources': [for (final source in sources) source.toJson()],
    'learningChecks': _dateMapToJson(learningChecks),
    'neighborhood': [for (final entry in neighborhood) entry.toJson()],
    'maintenanceEveryDays': maintenanceEveryDays,
  };

  static ResiliencePlan fromJson(Object? value) {
    if (value is! Map) return const ResiliencePlan();
    return ResiliencePlan(
      warningChecks: _dateMapFromJson(value['warningChecks']),
      support: IndividualSupportPlan.fromJson(value['support']),
      sources: _items(value['sources'], TrustedSource.fromJson),
      learningChecks: _dateMapFromJson(value['learningChecks']),
      neighborhood: _items(
        value['neighborhood'],
        NeighborhoodCapability.fromJson,
      ),
      maintenanceEveryDays: _intMapFromJson(value['maintenanceEveryDays']),
    );
  }

  /// Newer local records win on conflict, while lists are united by id.
  ResiliencePlan mergeWith(ResiliencePlan incoming) => ResiliencePlan(
    warningChecks: mergeDates(warningChecks, incoming.warningChecks),
    support: support.mergeWith(incoming.support),
    sources: mergeById(
      sources,
      incoming.sources,
      (item) => item.id,
      (item) => item.checkedAt,
    ),
    learningChecks: mergeDates(learningChecks, incoming.learningChecks),
    neighborhood: mergeById(
      neighborhood,
      incoming.neighborhood,
      (item) => item.id,
      (item) => item.checkedAt,
    ),
    // Intervals carry no timestamp. Preserve an explicit local choice and
    // take a restored value only when this device has no choice for it yet.
    maintenanceEveryDays: {
      ...incoming.maintenanceEveryDays,
      ...maintenanceEveryDays,
    },
  );
}

class IndividualSupportPlan {
  const IndividualSupportPlan({
    this.powerReviewed = false,
    this.evacuationReviewed = false,
    this.transportReviewed = false,
    this.medicineReviewed = false,
    this.assistanceReviewed = false,
    this.note = '',
    this.checkedAt,
  });

  final bool powerReviewed;
  final bool evacuationReviewed;
  final bool transportReviewed;
  final bool medicineReviewed;
  final bool assistanceReviewed;
  final String note;
  final DateTime? checkedAt;

  IndividualSupportPlan copyWith({
    bool? powerReviewed,
    bool? evacuationReviewed,
    bool? transportReviewed,
    bool? medicineReviewed,
    bool? assistanceReviewed,
    String? note,
    DateTime? checkedAt,
  }) => IndividualSupportPlan(
    powerReviewed: powerReviewed ?? this.powerReviewed,
    evacuationReviewed: evacuationReviewed ?? this.evacuationReviewed,
    transportReviewed: transportReviewed ?? this.transportReviewed,
    medicineReviewed: medicineReviewed ?? this.medicineReviewed,
    assistanceReviewed: assistanceReviewed ?? this.assistanceReviewed,
    note: note ?? this.note,
    checkedAt: checkedAt ?? DateTime.now(),
  );

  Map<String, Object?> toJson() => {
    'powerReviewed': powerReviewed,
    'evacuationReviewed': evacuationReviewed,
    'transportReviewed': transportReviewed,
    'medicineReviewed': medicineReviewed,
    'assistanceReviewed': assistanceReviewed,
    'note': note,
    'checkedAt': checkedAt?.toUtc().toIso8601String(),
  };

  static IndividualSupportPlan fromJson(Object? value) {
    if (value is! Map) return const IndividualSupportPlan();
    return IndividualSupportPlan(
      powerReviewed: value['powerReviewed'] == true,
      evacuationReviewed: value['evacuationReviewed'] == true,
      transportReviewed: value['transportReviewed'] == true,
      medicineReviewed: value['medicineReviewed'] == true,
      assistanceReviewed: value['assistanceReviewed'] == true,
      note: value['note'] is String ? value['note'] as String : '',
      checkedAt: _date(value['checkedAt']),
    );
  }

  IndividualSupportPlan mergeWith(IndividualSupportPlan incoming) =>
      _newer(incoming.checkedAt, checkedAt) ? incoming : this;
}

class TrustedSource {
  const TrustedSource({
    required this.id,
    required this.label,
    required this.channel,
    required this.offlineFallback,
    required this.checkedAt,
  });

  factory TrustedSource.create({
    required String label,
    required String channel,
    required String offlineFallback,
  }) => TrustedSource(
    id: const Uuid().v4(),
    label: label,
    channel: channel,
    offlineFallback: offlineFallback,
    checkedAt: DateTime.now(),
  );

  final String id, label, channel, offlineFallback;
  final DateTime checkedAt;

  Map<String, Object?> toJson() => {
    'id': id,
    'label': label,
    'channel': channel,
    'offlineFallback': offlineFallback,
    'checkedAt': checkedAt.toUtc().toIso8601String(),
  };

  static TrustedSource? fromJson(Object? value) {
    if (value is! Map) return null;
    final checkedAt = _date(value['checkedAt']);
    if (value['id'] is! String ||
        value['label'] is! String ||
        value['channel'] is! String ||
        value['offlineFallback'] is! String ||
        checkedAt == null) {
      return null;
    }
    return TrustedSource(
      id: value['id'] as String,
      label: value['label'] as String,
      channel: value['channel'] as String,
      offlineFallback: value['offlineFallback'] as String,
      checkedAt: checkedAt,
    );
  }
}

class NeighborhoodCapability {
  const NeighborhoodCapability({
    required this.id,
    required this.alias,
    required this.skill,
    required this.contactMethod,
    required this.meetingPoint,
    required this.checkedAt,
  });

  factory NeighborhoodCapability.create({
    required String alias,
    required String skill,
    required String contactMethod,
    required String meetingPoint,
  }) => NeighborhoodCapability(
    id: const Uuid().v4(),
    alias: alias,
    skill: skill,
    contactMethod: contactMethod,
    meetingPoint: meetingPoint,
    checkedAt: DateTime.now(),
  );

  final String id, alias, skill, contactMethod, meetingPoint;
  final DateTime checkedAt;

  Map<String, Object?> toJson() => {
    'id': id,
    'alias': alias,
    'skill': skill,
    'contactMethod': contactMethod,
    'meetingPoint': meetingPoint,
    'checkedAt': checkedAt.toUtc().toIso8601String(),
  };

  static NeighborhoodCapability? fromJson(Object? value) {
    if (value is! Map) return null;
    final checkedAt = _date(value['checkedAt']);
    if (value['id'] is! String ||
        value['alias'] is! String ||
        value['skill'] is! String ||
        value['contactMethod'] is! String ||
        value['meetingPoint'] is! String ||
        checkedAt == null) {
      return null;
    }
    return NeighborhoodCapability(
      id: value['id'] as String,
      alias: value['alias'] as String,
      skill: value['skill'] as String,
      contactMethod: value['contactMethod'] as String,
      meetingPoint: value['meetingPoint'] as String,
      checkedAt: checkedAt,
    );
  }
}

Map<String, Object?> _dateMapToJson(Map<String, DateTime> values) => {
  for (final entry in values.entries)
    entry.key: entry.value.toUtc().toIso8601String(),
};

Map<String, DateTime> _dateMapFromJson(Object? value) {
  if (value is! Map) return const {};
  final result = <String, DateTime>{};
  for (final entry in value.entries) {
    final parsed = _date(entry.value);
    if (entry.key is String && parsed != null) {
      result[entry.key as String] = parsed;
    }
  }
  return result;
}

Map<String, int> _intMapFromJson(Object? value) {
  if (value is! Map) return const {};
  final result = <String, int>{};
  for (final entry in value.entries) {
    final days = entry.value is int ? entry.value as int : null;
    if (entry.key is String && days != null && days >= 0) {
      result[entry.key as String] = days;
    }
  }
  return result;
}

List<T> _items<T>(Object? value, T? Function(Object?) parse) =>
    value is List ? value.map(parse).whereType<T>().toList() : const [];

DateTime? _date(Object? value) =>
    value is String ? DateTime.tryParse(value)?.toLocal() : null;

bool _newer(DateTime? candidate, DateTime? held) =>
    candidate != null && (held == null || candidate.isAfter(held));

Map<String, DateTime> mergeDates(
  Map<String, DateTime> held,
  Map<String, DateTime> incoming,
) {
  final result = Map<String, DateTime>.from(held);
  for (final entry in incoming.entries) {
    if (_newer(entry.value, result[entry.key])) result[entry.key] = entry.value;
  }
  return result;
}

List<T> mergeById<T>(
  List<T> held,
  List<T> incoming,
  String Function(T) idOf,
  DateTime Function(T) checkedAtOf,
) {
  final byId = {for (final item in held) idOf(item): item};
  final order = [for (final item in held) idOf(item)];
  for (final item in incoming) {
    final id = idOf(item);
    final existing = byId[id];
    if (existing == null) {
      byId[id] = item;
      order.add(id);
    } else if (checkedAtOf(item).isAfter(checkedAtOf(existing))) {
      byId[id] = item;
    }
  }
  return [for (final id in order) byId[id] as T];
}
