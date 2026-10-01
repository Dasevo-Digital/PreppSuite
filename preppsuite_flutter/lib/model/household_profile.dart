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
    this.children = 0,
    this.dogs = 0,
    this.cats = 0,
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

  /// Adults. Drives the supply calculator's targets.
  final int personCount;

  /// The others in the household who also have to be fed and watered.
  ///
  /// Separate counts rather than one number because the BBK's figures are
  /// per adult and it publishes none for children or animals — see
  /// `supply_calculator.dart`, which is where what each of them costs a
  /// day is written down and attributed.
  final int children;
  final int dogs;
  final int cats;

  /// Regions followed beyond the own one.
  final List<WarningRegion> extraRegions;

  WarningRegionFilter get warningFilter => WarningRegionFilter(
    countryCode: countryCode,
    ownRegionKey: regionKey,
    extraRegions: extraRegions,
  );

  /// [id] only for moving into another household — see
  /// `HouseholdProfileController.moveInto`, which is the one place that
  /// should pass it. Every other field travels along, which is the point:
  /// building a new profile by hand is how the children and the pets
  /// once got left behind on the way into a shared folder.
  HouseholdProfile copyWith({
    String? id,
    String? name,
    String? countryCode,
    String? regionKey,
    bool clearRegionKey = false,
    int? personCount,
    int? children,
    int? dogs,
    int? cats,
    List<WarningRegion>? extraRegions,
  }) {
    return HouseholdProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      countryCode: countryCode ?? this.countryCode,
      regionKey: clearRegionKey ? null : (regionKey ?? this.regionKey),
      personCount: personCount ?? this.personCount,
      children: children ?? this.children,
      dogs: dogs ?? this.dogs,
      cats: cats ?? this.cats,
      extraRegions: extraRegions ?? this.extraRegions,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'countryCode': countryCode,
    'regionKey': regionKey,
    'personCount': personCount,
    'children': children,
    'dogs': dogs,
    'cats': cats,
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
      // Absent in profiles written before these existed, which is the
      // normal case on an upgrade rather than an error.
      children: _count(json['children']),
      dogs: _count(json['dogs']),
      cats: _count(json['cats']),
      extraRegions: [
        if (extra is List)
          for (final entry in extra)
            if (entry is String) ?WarningRegion.decode(entry),
      ],
    );
  }

  static int _count(Object? value) => value is int && value > 0 ? value : 0;
}
