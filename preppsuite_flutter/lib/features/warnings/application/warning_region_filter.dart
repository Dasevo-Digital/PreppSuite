/// What a device wants warnings about.
///
/// Deliberately free of anything from the generated client package. Two
/// reasons: the background worker runs in its own isolate where no
/// household has been fetched and no session exists, and the server — the
/// only thing those types describe — is on its way out. A plain value type
/// can be stored in preferences, read back in an isolate, and compared
/// without any of that.
library;

import '../../household/application/german_states.dart';
import 'german_district_keys.dart';

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
  const WarningRegion({required this.kind, required this.value, this.label});

  final WarningRegionKind kind;
  final String value;

  /// A household's name for this place, such as "Oma" or "Arbeit".
  /// It is presentation-only: warning matching always uses [kind] and
  /// [value], which keeps a renamed place from changing which alerts match.
  final String? label;

  /// Round-trips through preferences. The original `kind:value` shape stays
  /// readable so an update never loses old subscriptions; labelled places use
  /// an escaped, versioned shape because district values may themselves hold
  /// a colon in tests or imported data.
  String encode() {
    final normalizedLabel = label?.trim();
    if (normalizedLabel == null || normalizedLabel.isEmpty) {
      return '${kind.name}:$value';
    }
    return 'v2:${kind.name}:${Uri.encodeComponent(value)}:'
        '${Uri.encodeComponent(normalizedLabel)}';
  }

  static WarningRegion? decode(String encoded) {
    if (encoded.startsWith('v2:')) {
      final parts = encoded.split(':');
      if (parts.length != 4) return null;
      final kind = WarningRegionKind.values.asNameMap()[parts[1]];
      if (kind == null) return null;
      try {
        final value = Uri.decodeComponent(parts[2]);
        final label = Uri.decodeComponent(parts[3]).trim();
        if (value.isEmpty || label.isEmpty) return null;
        return WarningRegion(kind: kind, value: value, label: label);
      } on FormatException {
        return null;
      }
    }
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

  /// Whether this names a district or a state that exists.
  bool get isPlaced => switch (kind) {
    WarningRegionKind.kreis => isGermanRegionKey(value),
    WarningRegionKind.bundesland => germanStateByBbkCode(value) != null,
  };

  WarningRegion copyWith({String? label, bool clearLabel = false}) =>
      WarningRegion(
        kind: kind,
        value: value,
        label: clearLabel ? null : (label ?? this.label),
      );
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
  ///
  /// Nor has it where its own key names no district (#349). Followed
  /// places alone would then decide, and the warnings for where the
  /// household lives read as somewhere else. A followed place that names
  /// nothing does not count either.
  bool get hasAnyRegion {
    if (ownKreisSchluessel != null) return true;
    final own = ownRegionKey?.trim() ?? '';
    return own.isEmpty && extraRegions.any((region) => region.isPlaced);
  }

  /// The first five digits, or null where the key names no German
  /// district.
  ///
  /// A postcode in the field used to switch off the warnings for the own
  /// district and state (#349): "77756" counted as a region, "77" is no
  /// state, and a flood in the district and a warning for all of
  /// Baden-Württemberg both read as somewhere else. Two digits from 01 to
  /// 16 were not enough: "04109" is Leipzig's postcode and began like
  /// Bremen. A key counts only where the district table has it; otherwise
  /// it is none, which shows everything in the country, the safe reading.
  /// The forms refuse such keys; this is for the ones already stored.
  String? get ownKreisSchluessel {
    final key = ownRegionKey;
    if (key == null || !isGermanRegionKey(key)) return null;
    return key.substring(0, 5);
  }

  /// Every district whose precise BBK dashboard should supplement the
  /// nationwide feed. A set avoids duplicate requests when the same place is
  /// named twice in a household's configuration.
  List<String> get followedKreisSchluessel => {
    ?ownKreisSchluessel,
    for (final region in extraRegions)
      if (region.kind == WarningRegionKind.kreis && region.isPlaced)
        region.value.substring(0, 5),
  }.toList(growable: false);
}

/// Whether [key] begins with the key of a German district.
bool isGermanRegionKey(String key) =>
    key.length >= 5 && germanDistrictKeys.contains(key.substring(0, 5));
