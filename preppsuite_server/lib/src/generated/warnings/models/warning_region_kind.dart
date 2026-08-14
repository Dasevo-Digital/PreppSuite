/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod/serverpod.dart' as _i1;

/// What a [WarningRegionSubscription.value] identifies.
enum WarningRegionKind implements _i1.SerializableModel {
  /// `value` is a 5-digit German Kreisschlüssel (district key) — the most
  /// precise granularity the public BBK API supports (see
  /// `services/german_states.dart` for why not full ARS/Gemeinde level).
  kreis,

  /// `value` is a 2-letter German state (Bundesland) code, e.g. "BY".
  bundesland;

  static WarningRegionKind fromJson(String name) {
    switch (name) {
      case 'kreis':
        return WarningRegionKind.kreis;
      case 'bundesland':
        return WarningRegionKind.bundesland;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "WarningRegionKind"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
