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
import 'package:serverpod_client/serverpod_client.dart' as _i1;

/// Normalized severity, shared vocabulary between both source feeds (both
/// already use the CAP standard's Minor/Moderate/Severe/Extreme scale).
enum WarningSeverity implements _i1.SerializableModel {
  minor,
  moderate,
  severe,
  extreme;

  static WarningSeverity fromJson(String name) {
    switch (name) {
      case 'minor':
        return WarningSeverity.minor;
      case 'moderate':
        return WarningSeverity.moderate;
      case 'severe':
        return WarningSeverity.severe;
      case 'extreme':
        return WarningSeverity.extreme;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "WarningSeverity"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
