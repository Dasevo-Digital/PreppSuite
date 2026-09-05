/// What a device wants warnings about.
///
/// Deliberately free of anything from the generated client package. Two
/// reasons: the background worker runs in its own isolate where no
/// household has been fetched and no session exists, and the server — the
/// only thing those types describe — is on its way out. A plain value type
/// can be stored in preferences, read back in an isolate, and compared
/// without any of that.
library;

/// How coarse an additional region is.
enum WarningRegionKind {
  /// A 5-digit Kreisschlüssel.
  kreis,

  /// A 2-letter German state code.
  bundesland,
}

/// One region beyond the device's own, e.g. a neighbouring district or the
/// state a family member lives in.
class WarningRegion {
  const WarningRegion({required this.kind, required this.value});

  final WarningRegionKind kind;
  final String value;

  /// Round-trips through preferences as `kind:value`.
  String encode() => '${kind.name}:$value';

  static WarningRegion? decode(String encoded) {
    final separator = encoded.indexOf(':');
    if (separator <= 0) return null;
    final kind =
        WarningRegionKind.values.asNameMap()[encoded.substring(
          0,
          separator,
        )];
    if (kind == null) return null;
    final value = encoded.substring(separator + 1);
    return value.isEmpty ? null : WarningRegion(kind: kind, value: value);
  }

  @override
  bool operator ==(Object other) =>
      other is WarningRegion && other.kind == kind && other.value == value;

  @override
  int get hashCode => Object.hash(kind, value);
}

/// The country, own region and any extra regions a device follows.
class WarningRegionFilter {
  const WarningRegionFilter({
    required this.countryCode,
    this.ownRegionKey,
    this.extraRegions = const [],
  });

  /// ISO 3166-1 alpha-2. Decides which feeds are polled at all.
  final String countryCode;

  /// German ARS/Kreisschlüssel; only the first five digits are ever used,
  /// which is as precise as the BBK feed gets.
  final String? ownRegionKey;

  final List<WarningRegion> extraRegions;

  /// Whether the device has said anything about where it is. When it has
  /// not, every warning in the country is shown — the safe reading for a
  /// civil-protection alert.
  bool get hasAnyRegion =>
      (ownRegionKey != null && ownRegionKey!.length >= 5) ||
      extraRegions.isNotEmpty;

  String? get ownKreisSchluessel {
    final key = ownRegionKey;
    if (key == null || key.length < 5) return null;
    return key.substring(0, 5);
  }
}
