import '../features/warnings/application/warning_region_filter.dart';

/// Who and where this installation is.
///
/// Replaces the server-side `Household`. The [id] stays because every local
/// table partitions by it — and because it is what two devices sharing a
/// folder must agree on for their rows to merge rather than pile up. It is
/// generated once on this device, or adopted from a shared folder.
class HouseholdProfile {
  const HouseholdProfile({
    required this.id,
    required this.name,
    required this.countryCode,
    this.regionKey,
    this.personCount = 1,
    this.extraRegions = const [],
  });

  /// Stable identity for the household's data. Shared, not secret.
  final String id;

  /// What the user calls this household. Cosmetic.
  final String name;

  /// ISO 3166-1 alpha-2 — decides which warning feeds are polled.
  final String countryCode;

  /// German ARS/Kreisschlüssel. Only the first five digits are ever used,
  /// which is as precise as the BBK feed gets.
  final String? regionKey;

  /// Drives the supply calculator's targets.
  final int personCount;

  /// Regions followed beyond the own one.
  final List<WarningRegion> extraRegions;

  WarningRegionFilter get warningFilter => WarningRegionFilter(
    countryCode: countryCode,
    ownRegionKey: regionKey,
    extraRegions: extraRegions,
  );

  HouseholdProfile copyWith({
    String? name,
    String? countryCode,
    String? regionKey,
    bool clearRegionKey = false,
    int? personCount,
    List<WarningRegion>? extraRegions,
  }) {
    return HouseholdProfile(
      id: id,
      name: name ?? this.name,
      countryCode: countryCode ?? this.countryCode,
      regionKey: clearRegionKey ? null : (regionKey ?? this.regionKey),
      personCount: personCount ?? this.personCount,
      extraRegions: extraRegions ?? this.extraRegions,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'countryCode': countryCode,
    'regionKey': regionKey,
    'personCount': personCount,
    'extraRegions': [for (final r in extraRegions) r.encode()],
  };

  /// Returns null rather than throwing on anything unexpected: this is
  /// read from preferences and from files other devices wrote, and a
  /// corrupt profile should send the user through onboarding again, not
  /// crash the app on launch.
  static HouseholdProfile? fromJson(Map<String, Object?> json) {
    final id = json['id'];
    final name = json['name'];
    final country = json['countryCode'];
    if (id is! String || id.isEmpty) return null;
    if (name is! String || country is! String || country.isEmpty) return null;

    final region = json['regionKey'];
    final people = json['personCount'];
    final extra = json['extraRegions'];

    return HouseholdProfile(
      id: id,
      name: name,
      countryCode: country,
      regionKey: region is String && region.isNotEmpty ? region : null,
      personCount: people is int && people > 0 ? people : 1,
      extraRegions: [
        if (extra is List)
          for (final entry in extra)
            if (entry is String) ?WarningRegion.decode(entry),
      ],
    );
  }
}
