import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../local_db/database.dart';

/// Everything one device knows, as one file.
///
/// A full snapshot rather than a log of changes. That costs a few hundred
/// kilobytes per device and buys two things worth far more: a device that
/// was offline for a month needs no catch-up, and a household whose
/// original device is gone still has every row, because every other device
/// has been republishing them all along.
///
/// Rows travel with their `updatedAt` logical version. Local edits advance
/// beyond the stored second; merges compare that version, then canonical
/// shared contents on ties. A fast device clock can still outrank unseen
/// edits. Deletions remain tombstones so a later edit can overrule them.
class DeviceSnapshot {
  const DeviceSnapshot({
    required this.deviceId,
    required this.householdId,
    required this.writtenAt,
    this.inventoryItems = const [],
    this.checklistTemplates = const [],
    this.checklistItems = const [],
    this.budgetEntries = const [],
    this.householdPlans = const [],
    this.householdMembers = const [],
    this.possessions = const [],
  });

  /// See [HouseholdFile.currentVersion] for how a mismatch is handled: a
  /// file claiming a newer version is skipped, not guessed at.
  static const currentVersion = 1;

  /// How many rows this snapshot carries.
  ///
  /// Every collection, `possessions` included — the counter this replaced
  /// lived in `local_handover.dart` and had never been told about that
  /// table, so a handover under-reported what it sent. Counting here is
  /// what stops the next added table from being forgotten twice.
  int get rowCount =>
      inventoryItems.length +
      checklistTemplates.length +
      checklistItems.length +
      budgetEntries.length +
      householdPlans.length +
      householdMembers.length +
      possessions.length;

  final String deviceId;
  final String householdId;
  final DateTime writtenAt;

  final List<Map<String, Object?>> inventoryItems;
  final List<Map<String, Object?>> checklistTemplates;
  final List<Map<String, Object?>> checklistItems;
  final List<Map<String, Object?>> budgetEntries;

  /// At most one, and its clientId is the household id — see
  /// [HouseholdPlans]. A list all the same, so the shape of the file
  /// stays the same as every other collection in it.
  final List<Map<String, Object?>> householdPlans;

  /// The people, and what an ambulance would want to know about
  /// them. Health data — see [HouseholdMembers] and the note on
  /// encryption in `folder_crypto.dart`.
  final List<Map<String, Object?>> householdMembers;

  /// What the household owns, for an insurer rather than for the supply
  /// calculator. Added after the fact, which a reader has to tolerate:
  /// a file written by an older version simply has no such key, and
  /// [_rows] answers an empty list for it.
  final List<Map<String, Object?>> possessions;

  String encode() => const JsonEncoder.withIndent('  ').convert(toJson());

  /// The same content as [encode], still as a map.
  ///
  /// A local handover sends a *superset* of this — the settings and the
  /// photographs travel beside the rows — and it builds that by adding
  /// keys to this map. Keys rather than a wrapper, so that an older app
  /// on the other end reads the whole thing with [decode], ignores what
  /// it does not know, and the handover still works.
  Map<String, Object?> toJson() => {
    'version': currentVersion,
    'deviceId': deviceId,
    'householdId': householdId,
    'writtenAt': writtenAt.toUtc().toIso8601String(),
    'inventoryItems': inventoryItems,
    'checklistTemplates': checklistTemplates,
    'checklistItems': checklistItems,
    'budgetEntries': budgetEntries,
    'householdPlans': householdPlans,
    'householdMembers': householdMembers,
    'possessions': possessions,
  };

  static DeviceSnapshot? decode(String raw) {
    try {
      final json = jsonDecode(raw);
      if (json is! Map<String, Object?>) return null;

      final version = json['version'];
      if (version is! int || version > currentVersion) return null;

      final deviceId = json['deviceId'];
      final householdId = json['householdId'];
      if (deviceId is! String || deviceId.isEmpty) return null;
      if (householdId is! String || householdId.isEmpty) return null;

      return DeviceSnapshot(
        deviceId: deviceId,
        householdId: householdId,
        writtenAt: asUtcDate(json['writtenAt']) ?? DateTime.now().toUtc(),
        inventoryItems: _rows(json['inventoryItems']),
        checklistTemplates: _rows(json['checklistTemplates']),
        checklistItems: _rows(json['checklistItems']),
        budgetEntries: _rows(json['budgetEntries']),
        householdPlans: _rows(json['householdPlans']),
        householdMembers: _rows(json['householdMembers']),
        possessions: _rows(json['possessions']),
      );
    } on FormatException {
      return null;
    }
  }

  static List<Map<String, Object?>> _rows(Object? value) => [
    if (value is List)
      for (final entry in value)
        if (entry is Map<String, Object?>) entry,
  ];
}

// --- Row codecs --------------------------------------------------------
//
// Written by hand rather than using drift's generated `toJson`. The
// generated one follows the column list, which would make every future
// migration a silent change to a file format that other installs — and
// older app versions — have to keep reading. These name their fields
// explicitly and skip anything they don't recognize.

Map<String, Object?> encodeInventoryItem(InventoryItem row) => {
  'clientId': row.clientId,
  'householdId': row.householdId,
  'name': row.name,
  'category': row.category,
  'barcode': row.barcode,
  'offProductId': row.offProductId,
  'quantity': row.quantity,
  'unit': row.unit,
  'storageLocation': row.storageLocation,
  'expirationDate': _date(row.expirationDate),
  'minQuantity': row.minQuantity,
  'calories': row.calories,
  'proteinGrams': row.proteinGrams,
  'carbohydrateGrams': row.carbohydrateGrams,
  'fatGrams': row.fatGrams,
  'fiberGrams': row.fiberGrams,
  'dailyDose': row.dailyDose,
  'notes': row.notes,
  'updatedAt': _date(row.updatedAt),
  'deletedAt': _date(row.deletedAt),
  // photoPath is deliberately absent: it points into this device's
  // documents directory, and the picture itself is not in the folder. A
  // path that resolves to nothing on the other device is worse than no
  // path at all. The merge leaves the local value untouched.
};

/// Returns null when the row is unusable, so one bad entry costs one row
/// rather than the whole sync.
InventoryItemsCompanion? decodeInventoryItem(Map<String, Object?> json) {
  final clientId = _string(json['clientId']);
  final householdId = _string(json['householdId']);
  final name = _string(json['name']);
  final category = _string(json['category']);
  final quantity = _double(json['quantity']);
  final updatedAt = asUtcDate(json['updatedAt']);
  if (clientId == null ||
      householdId == null ||
      name == null ||
      category == null ||
      quantity == null ||
      updatedAt == null) {
    return null;
  }

  return InventoryItemsCompanion.insert(
    clientId: clientId,
    householdId: householdId,
    name: name,
    category: category,
    barcode: Value(_string(json['barcode'])),
    offProductId: Value(_string(json['offProductId'])),
    quantity: quantity,
    unit: _string(json['unit']) ?? '',
    storageLocation: _string(json['storageLocation']) ?? '',
    expirationDate: Value(asUtcDate(json['expirationDate'])),
    minQuantity: Value(_double(json['minQuantity'])),
    calories: Value(_double(json['calories'])),
    // Absent in files written before these columns existed, which is why
    // every one of them is nullable and read through a tolerant helper:
    // an older device's snapshot has to stay readable.
    proteinGrams: Value(_double(json['proteinGrams'])),
    carbohydrateGrams: Value(_double(json['carbohydrateGrams'])),
    fatGrams: Value(_double(json['fatGrams'])),
    fiberGrams: Value(_double(json['fiberGrams'])),
    dailyDose: Value(_double(json['dailyDose'])),
    notes: Value(_string(json['notes'])),
    updatedAt: updatedAt,
    deletedAt: Value(asUtcDate(json['deletedAt'])),
    // Arrived from elsewhere, so there is nothing of ours to publish.
    dirty: const Value(false),
  );
}

Map<String, Object?> encodeChecklistTemplate(ChecklistTemplate row) => {
  'clientId': row.clientId,
  'householdId': row.householdId,
  'title': row.title,
  'category': row.category,
  'isBuiltIn': row.isBuiltIn,
  'updatedAt': _date(row.updatedAt),
  'deletedAt': _date(row.deletedAt),
};

ChecklistTemplatesCompanion? decodeChecklistTemplate(
  Map<String, Object?> json,
) {
  final clientId = _string(json['clientId']);
  final title = _string(json['title']);
  final category = _string(json['category']);
  final updatedAt = asUtcDate(json['updatedAt']);
  if (clientId == null ||
      title == null ||
      category == null ||
      updatedAt == null) {
    return null;
  }

  return ChecklistTemplatesCompanion.insert(
    clientId: clientId,
    householdId: Value(_string(json['householdId'])),
    title: title,
    category: category,
    isBuiltIn: Value(json['isBuiltIn'] == true),
    updatedAt: updatedAt,
    deletedAt: Value(asUtcDate(json['deletedAt'])),
    dirty: const Value(false),
  );
}

Map<String, Object?> encodeChecklistItem(ChecklistItem row) => {
  'clientId': row.clientId,
  'householdId': row.householdId,
  'templateClientId': row.templateClientId,
  'title': row.title,
  'targetQuantity': row.targetQuantity,
  'isChecked': row.isChecked,
  'linkedInventoryItemId': row.linkedInventoryItemId,
  'sortOrder': row.sortOrder,
  'updatedAt': _date(row.updatedAt),
  'deletedAt': _date(row.deletedAt),
};

ChecklistItemsCompanion? decodeChecklistItem(Map<String, Object?> json) {
  final clientId = _string(json['clientId']);
  final templateClientId = _string(json['templateClientId']);
  final title = _string(json['title']);
  final updatedAt = asUtcDate(json['updatedAt']);
  if (clientId == null ||
      templateClientId == null ||
      title == null ||
      updatedAt == null) {
    return null;
  }

  return ChecklistItemsCompanion.insert(
    clientId: clientId,
    householdId: Value(_string(json['householdId'])),
    templateClientId: templateClientId,
    title: title,
    targetQuantity: Value(_double(json['targetQuantity'])),
    isChecked: Value(json['isChecked'] == true),
    linkedInventoryItemId: Value(_string(json['linkedInventoryItemId'])),
    sortOrder: Value(_int(json['sortOrder']) ?? 0),
    updatedAt: updatedAt,
    deletedAt: Value(asUtcDate(json['deletedAt'])),
    dirty: const Value(false),
  );
}

Map<String, Object?> encodeHouseholdMember(HouseholdMember row) => {
  'clientId': row.clientId,
  'householdId': row.householdId,
  'name': row.name,
  'birthYear': row.birthYear,
  'bloodType': row.bloodType,
  'allergies': row.allergies,
  'medication': row.medication,
  'conditions': row.conditions,
  'insurance': row.insurance,
  'doctor': row.doctor,
  'emergencyContact': row.emergencyContact,
  'notes': row.notes,
  'sortOrder': row.sortOrder,
  'updatedAt': _date(row.updatedAt),
  'deletedAt': _date(row.deletedAt),
};

HouseholdMembersCompanion? decodeHouseholdMember(Map<String, Object?> json) {
  final clientId = _string(json['clientId']);
  final householdId = _string(json['householdId']);
  final name = _string(json['name']);
  final updatedAt = asUtcDate(json['updatedAt']);
  // A card without a name is not a card. Everything medical is optional:
  // one that says only "Lena, allergic to penicillin" is worth keeping.
  if (clientId == null ||
      householdId == null ||
      name == null ||
      updatedAt == null) {
    return null;
  }

  return HouseholdMembersCompanion.insert(
    clientId: clientId,
    householdId: householdId,
    name: name,
    birthYear: Value(_int(json['birthYear'])),
    bloodType: Value(_string(json['bloodType'])),
    allergies: Value(_string(json['allergies'])),
    medication: Value(_string(json['medication'])),
    conditions: Value(_string(json['conditions'])),
    insurance: Value(_string(json['insurance'])),
    doctor: Value(_string(json['doctor'])),
    emergencyContact: Value(_string(json['emergencyContact'])),
    notes: Value(_string(json['notes'])),
    sortOrder: Value(_int(json['sortOrder']) ?? 0),
    updatedAt: updatedAt,
    deletedAt: Value(asUtcDate(json['deletedAt'])),
    dirty: const Value(false),
  );
}

Map<String, Object?> encodePossession(Possession row) => {
  'clientId': row.clientId,
  'householdId': row.householdId,
  'name': row.name,
  'room': row.room,
  'serialNumber': row.serialNumber,
  'acquiredOn': _date(row.acquiredOn),
  'purchasePriceCents': row.purchasePriceCents,
  'currency': row.currency,
  'notes': row.notes,
  'updatedAt': _date(row.updatedAt),
  'deletedAt': _date(row.deletedAt),
  // photoPath stays behind for the same reason it does on an inventory
  // item: it names a file in this device's documents directory.
};

PossessionsCompanion? decodePossession(Map<String, Object?> json) {
  final clientId = _string(json['clientId']);
  final householdId = _string(json['householdId']);
  final name = _string(json['name']);
  final updatedAt = asUtcDate(json['updatedAt']);
  // A name and nothing else is a usable entry: "Waschmaschine" in a list
  // of forty is still worth more after a fire than a perfect record of
  // thirty-nine.
  if (clientId == null ||
      householdId == null ||
      name == null ||
      updatedAt == null) {
    return null;
  }

  return PossessionsCompanion.insert(
    clientId: clientId,
    householdId: householdId,
    name: name,
    room: Value(_string(json['room'])),
    serialNumber: Value(_string(json['serialNumber'])),
    acquiredOn: Value(asUtcDate(json['acquiredOn'])),
    purchasePriceCents: Value(_int(json['purchasePriceCents'])),
    currency: Value(_string(json['currency'])),
    notes: Value(_string(json['notes'])),
    updatedAt: updatedAt,
    deletedAt: Value(asUtcDate(json['deletedAt'])),
    dirty: const Value(false),
  );
}

Map<String, Object?> encodeHouseholdPlan(HouseholdPlan row) => {
  'clientId': row.clientId,
  'householdId': row.householdId,
  'meetingPointNear': row.meetingPointNear,
  'meetingPointFar': row.meetingPointFar,
  'contactName': row.contactName,
  'contactPhone': row.contactPhone,
  'kitLocation': row.kitLocation,
  'shutoffLocation': row.shutoffLocation,
  'localContactPoint': row.localContactPoint,
  'notes': row.notes,
  'updatedAt': _date(row.updatedAt),
  'deletedAt': _date(row.deletedAt),
};

HouseholdPlansCompanion? decodeHouseholdPlan(Map<String, Object?> json) {
  final clientId = _string(json['clientId']);
  final householdId = _string(json['householdId']);
  final updatedAt = asUtcDate(json['updatedAt']);
  // Every field of the plan itself is optional — a household that only
  // agreed a meeting point and nothing else has a perfectly good plan.
  // The three above are what makes the row addressable at all.
  if (clientId == null || householdId == null || updatedAt == null) {
    return null;
  }

  return HouseholdPlansCompanion.insert(
    clientId: clientId,
    householdId: householdId,
    meetingPointNear: Value(_string(json['meetingPointNear'])),
    meetingPointFar: Value(_string(json['meetingPointFar'])),
    contactName: Value(_string(json['contactName'])),
    contactPhone: Value(_string(json['contactPhone'])),
    kitLocation: Value(_string(json['kitLocation'])),
    shutoffLocation: Value(_string(json['shutoffLocation'])),
    localContactPoint: Value(_string(json['localContactPoint'])),
    notes: Value(_string(json['notes'])),
    updatedAt: updatedAt,
    deletedAt: Value(asUtcDate(json['deletedAt'])),
    dirty: const Value(false),
  );
}

Map<String, Object?> encodeBudgetEntry(BudgetEntry row) => {
  'clientId': row.clientId,
  'householdId': row.householdId,
  'label': row.label,
  'amountCents': row.amountCents,
  'currency': row.currency,
  'category': row.category,
  'purchaseDate': _date(row.purchaseDate),
  'linkedInventoryItemId': row.linkedInventoryItemId,
  'updatedAt': _date(row.updatedAt),
  'deletedAt': _date(row.deletedAt),
};

BudgetEntriesCompanion? decodeBudgetEntry(Map<String, Object?> json) {
  final clientId = _string(json['clientId']);
  final householdId = _string(json['householdId']);
  final label = _string(json['label']);
  final amountCents = _int(json['amountCents']);
  final currency = _string(json['currency']);
  final category = _string(json['category']);
  final updatedAt = asUtcDate(json['updatedAt']);
  if (clientId == null ||
      householdId == null ||
      label == null ||
      amountCents == null ||
      currency == null ||
      category == null ||
      updatedAt == null) {
    return null;
  }

  return BudgetEntriesCompanion.insert(
    clientId: clientId,
    householdId: householdId,
    label: label,
    amountCents: amountCents,
    currency: currency,
    category: category,
    purchaseDate: Value(asUtcDate(json['purchaseDate'])),
    linkedInventoryItemId: Value(_string(json['linkedInventoryItemId'])),
    updatedAt: updatedAt,
    deletedAt: Value(asUtcDate(json['deletedAt'])),
    dirty: const Value(false),
  );
}

/// ISO-8601 in UTC throughout, so a file stays readable and comparable
/// regardless of which timezone the device that wrote it was in.
String? _date(DateTime? value) => value?.toUtc().toIso8601String();

DateTime? asUtcDate(Object? value) {
  if (value is! String) return null;
  return DateTime.tryParse(value)?.toUtc();
}

String? _string(Object? value) =>
    value is String && value.isNotEmpty ? value : null;

int? _int(Object? value) => value is num ? value.toInt() : null;

double? _double(Object? value) => value is num ? value.toDouble() : null;
