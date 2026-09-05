import 'dart:convert';

/// The `household.json` a shared folder is identified by.
///
/// Carries only what every device in the household must agree on: the id
/// their rows are partitioned by. Name and country ride along as the
/// values a joining device is offered, not as values it is bound to —
/// which is what keeps this file single-writer. It is written once, by
/// whichever device set the folder up, and only read afterwards. Nothing
/// in it is secret; anyone who can see the folder can already see every
/// row in it.
class HouseholdFile {
  const HouseholdFile({
    required this.householdId,
    required this.name,
    required this.countryCode,
    required this.createdAt,
  });

  /// Bumped only if the layout stops being readable by an older app. A
  /// higher number than this app knows means "do not touch" rather than
  /// "guess" — the folder belongs to a newer install that would lose data
  /// if this one wrote an older shape over it.
  static const currentVersion = 1;

  final String householdId;
  final String name;
  final String countryCode;
  final DateTime createdAt;

  String encode() => const JsonEncoder.withIndent('  ').convert({
    'version': currentVersion,
    'householdId': householdId,
    'name': name,
    'countryCode': countryCode,
    'createdAt': createdAt.toUtc().toIso8601String(),
  });

  /// Returns null for anything unreadable — a truncated download, a file
  /// another program put there, a version from the future. The caller
  /// treats that as "this folder is not usable", which is the safe answer
  /// for all three.
  static HouseholdFile? decode(String raw) {
    try {
      final json = jsonDecode(raw);
      if (json is! Map<String, Object?>) return null;

      final version = json['version'];
      if (version is! int || version > currentVersion) return null;

      final id = json['householdId'];
      final name = json['name'];
      final country = json['countryCode'];
      if (id is! String || id.isEmpty) return null;
      if (name is! String || country is! String || country.isEmpty) {
        return null;
      }

      final created = json['createdAt'];
      return HouseholdFile(
        householdId: id,
        name: name,
        countryCode: country,
        createdAt:
            (created is String ? DateTime.tryParse(created) : null)?.toUtc() ??
            DateTime.now().toUtc(),
      );
    } on FormatException {
      return null;
    }
  }
}
