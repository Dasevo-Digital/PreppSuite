import 'dart:convert';

import 'folder_crypto.dart';

/// The `household.json` a shared folder is identified by.
///
/// Carries only what every device in the household must agree on: the id
/// their rows are partitioned by, and — once the folder is encrypted —
/// how to derive the key from the household's passphrase. Name and
/// country ride along as the values a joining device is offered, not as
/// values it is bound to, which is what keeps this file single-writer.
///
/// Nothing in it is secret. Not even [vault]: a salt and three work
/// factors are public by design, and writing them down is what lets a
/// second device derive the same key from the same passphrase. The
/// passphrase itself never touches the folder.
class HouseholdFile {
  const HouseholdFile({
    required this.householdId,
    required this.name,
    required this.countryCode,
    required this.createdAt,
    this.vault,
    this.check,
  });

  /// Bumped only if the layout stops being readable by an older app. A
  /// higher number than this app knows means "do not touch" rather than
  /// "guess" — the folder belongs to a newer install that would lose data
  /// if this one wrote an older shape over it.
  static const currentVersion = 2;

  /// What a folder without encryption is written as.
  ///
  /// Version 2 is used *only* once a folder is encrypted, and that
  /// asymmetry is the whole point. An app that predates encryption
  /// refuses a version it does not know — which is exactly right for a
  /// folder whose device files it could not read anyway, and exactly
  /// wrong for a plain folder it has been sharing happily for months.
  /// Writing 2 unconditionally would lock every household out of its own
  /// data on the day one member updated.
  static const plainVersion = 1;

  final String householdId;
  final String name;
  final String countryCode;
  final DateTime createdAt;

  /// How to derive the folder key, or null while the folder is plain.
  final VaultParameters? vault;

  /// The encrypted token a passphrase is checked against, or null.
  final String? check;

  bool get isEncrypted => vault != null && check != null;

  String encode() => const JsonEncoder.withIndent('  ').convert({
    'version': isEncrypted ? currentVersion : plainVersion,
    'householdId': householdId,
    'name': name,
    'countryCode': countryCode,
    'createdAt': createdAt.toUtc().toIso8601String(),
    if (isEncrypted) ...{'vault': vault!.toJson(), 'check': check},
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
      if (version is! int ||
          version < plainVersion ||
          version > currentVersion) {
        return null;
      }

      final id = json['householdId'];
      final name = json['name'];
      final country = json['countryCode'];
      if (id is! String || id.isEmpty) return null;
      if (name is! String || country is! String || country.isEmpty) {
        return null;
      }

      // A folder that says it is encrypted but cannot say how is not a
      // folder to guess at: every device file in it would fail to open
      // and the failure would look like corruption.
      final rawVault = json['vault'];
      final check = json['check'];
      if ((version == currentVersion) != (rawVault != null)) return null;
      VaultParameters? vault;
      if (rawVault != null) {
        if (rawVault is! Map<String, Object?>) return null;
        vault = VaultParameters.fromJson(rawVault);
        if (vault == null) return null;
        if (check is! String || check.isEmpty) return null;
      }

      final created = json['createdAt'];
      return HouseholdFile(
        householdId: id,
        name: name,
        countryCode: country,
        createdAt:
            (created is String ? DateTime.tryParse(created) : null)?.toUtc() ??
            DateTime.now().toUtc(),
        vault: vault,
        check: vault == null ? null : check as String,
      );
    } on FormatException {
      return null;
    }
  }
}
